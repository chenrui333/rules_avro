load("@rules_jvm_external//:defs.bzl", "maven_install")
load("@rules_jvm_external//:defs.bzl", "artifact")
load("@rules_jvm_external//:specs.bzl", "maven")

MAVEN_REPO_NAME = "avro"
AVRO_TOOLS = ("org.apache.avro", "avro-tools")
AVRO = ("org.apache.avro", "avro")


def _format_maven_jar_name(group_id, artifact_id):
    """
    group_id: str
    artifact_id: str
    """
    return ("%s_%s" % (group_id, artifact_id)).replace(".", "_").replace("-", "_")

def _format_maven_jar_dep_name(group_id, artifact_id, repo_name = "maven"):
    """
    group_id: str
    artifact_id: str
    repo_name: str = "maven"
    """
    return "@%s//:%s" % (repo_name, _format_maven_jar_name(group_id, artifact_id))


AVRO_TOOLS_LABEL = Label(_format_maven_jar_dep_name(
                           group_id = AVRO_TOOLS[0],
                           artifact_id = AVRO_TOOLS[1],
                           repo_name = MAVEN_REPO_NAME))

AVRO_CORE_LABEL = Label(_format_maven_jar_dep_name(
                     group_id = AVRO[0],
                     artifact_id = AVRO[1],
                     repo_name = MAVEN_REPO_NAME))

AVRO_LIBS_LABELS = {
    'tools': AVRO_TOOLS_LABEL,
    'core': AVRO_CORE_LABEL
}

def _join_list(l, delimiter):
    """
    Join a list into a single string. Inverse of List#split()

    l: List[String]
    delimiter: String
    """
    joined = ""
    for item in l:
        joined += (item + delimiter)
    return joined

def _files(files):
    if not files:
        return ""
    return " ".join([f.path for f in files])


def _common_dir(dirs):
    if not dirs:
        return ""

    if len(dirs) == 1:
        return dirs[0]

    split_dirs = [dir.split("/") for dir in dirs]

    shortest = min(split_dirs)
    longest = max(split_dirs)

    for i, piece in enumerate(shortest):
        # if the next dir does not match, we've found our common parent
        if piece != longest[i]:
            return _join_list(shortest[:i], "/")

    return _join_list(shortest, "/")

def avro_repositories(version = "1.9.1"):
    """
    version: str = "1.9.1" - the version of avro to fetch
    """
    artifacts = [
        maven.artifact(
            group = group_id,
            artifact = artifact_id,
            version = version,
        )
        for [group_id, artifact_id] in [AVRO, AVRO_TOOLS]
    ]
    maven_install(
        name = MAVEN_REPO_NAME,
        fetch_sources = True,
        artifacts = artifacts,
        repositories = [
            "https://repo1.maven.org/maven2/",
        ],
    )

def _new_idl2schemata_command(ctx, src_file, gen_dir):
    java_path = ctx.attr._jdk[java_common.JavaRuntimeInfo].java_executable_exec_path

    return [
        "{java} -jar {tool} idl2schemata {src} {dest}".format(
            java = java_path,
            tool = ctx.file.avro_tools.path,
            src = src_file.path,
            dest = gen_dir.path,
        ),
    ]

def _idl_schema_impl(ctx):
    files = []
    gen_dir = ctx.actions.declare_directory(
        "{out}".format(
            out = ctx.label.name,
        ),
    )

    commands = ["mkdir -p {gen_dir}".format(gen_dir = gen_dir.path)]
    for file in ctx.files.srcs:
        commands.extend(_new_idl2schemata_command(ctx, file, gen_dir))

    # forcing a timestamp for deterministic artifacts
    commands.append("find {gen_dir} -exec touch -t 198001010000 {{}} \\\\;".format(
        gen_dir = gen_dir.path,
    ))

    inputs = ctx.files.srcs + ctx.files.imports + ctx.files._jdk + [
        ctx.file.avro_tools,
    ]

    ctx.actions.run_shell(
        inputs = inputs,
        outputs = [gen_dir],
        command = " && ".join(commands),
        progress_message = "generating avro schemata",
        arguments = [],
    )

    return [
        DefaultInfo(files = depset([gen_dir])),
    ]

avro_idl_schema = rule(
    attrs = {
        "srcs": attr.label_list(
            allow_files = [".avdl"],
        ),
        "imports": attr.label_list(
            allow_files = [".avdl", ".avpr", ".avsc"],
        ),
        "_jdk": attr.label(
            default = Label("@bazel_tools//tools/jdk:current_java_runtime"),
            providers = [java_common.JavaRuntimeInfo],
        ),
        "avro_tools": attr.label(
            cfg = "host",
            default = AVRO_LIBS_LABELS["tools"],
            allow_single_file = True,
        ),
    },
    implementation = _idl_schema_impl,
)

def _new_idl_command(ctx, src_file, gen_dir, outputs):
    java_path = ctx.attr._jdk[java_common.JavaRuntimeInfo].java_executable_exec_path
    dest = ctx.actions.declare_file(
        gen_dir + "/" + src_file.path[:src_file.path.rfind(".")] + ".avpr",
    )
    outputs.append(dest)

    return [
        "mkdir -p {dest}".format(dest = dest.dirname),
        "{java} -jar {tool} idl {src} {dest}".format(
            java = java_path,
            tool = ctx.file.avro_tools.path,
            src = src_file.path,
            dest = dest.path,
        ),
        # forcing a timestamp for deterministic artifacts
        "touch -t 198001010000 {dest}".format(dest = dest.path),
    ]

def _idl_gen_impl(ctx):
    all_outputs = []
    gen_dir = "{out}-proto".format(
        out = ctx.label.name,
    )

    base_inputs = ctx.files.imports + ctx.files._jdk + [
        ctx.file.avro_tools,
    ]

    for file in ctx.files.srcs:
        outputs = []
        commands = _new_idl_command(ctx, file, gen_dir, outputs)
        ctx.actions.run_shell(
            inputs = [file] + base_inputs,
            outputs = outputs,
            command = " && ".join(commands),
            progress_message = "generating avro proto for {}".format(file.basename),
            arguments = [],
        )

        all_outputs.extend(outputs)

    return [
        DefaultInfo(files = depset(all_outputs)),
    ]

_avro_idl_gen = rule(
    attrs = {
        "srcs": attr.label_list(
            allow_files = [".avdl"],
        ),
        "imports": attr.label_list(
            allow_files = [".avdl", ".avpr", ".avsc"],
        ),
        "_jdk": attr.label(
            default = Label("@bazel_tools//tools/jdk:current_java_runtime"),
            providers = [java_common.JavaRuntimeInfo],
        ),
        "avro_tools": attr.label(
            cfg = "host",
            default = AVRO_LIBS_LABELS["tools"],
            allow_single_file = True,
        ),
    },
    implementation = _idl_gen_impl,
)

def _new_generator_command(ctx, src_dir, type, gen_dir):
  java_path = ctx.attr._jdk[java_common.JavaRuntimeInfo].java_executable_exec_path
  gen_command  = "{java} -jar {tool} compile ".format(
     java=java_path,
     tool=ctx.file.avro_tools.path,
  )

  if ctx.attr.strings:
    gen_command += " -string"

  if ctx.attr.encoding:
    gen_command += " -encoding {encoding}".format(
      encoding=ctx.attr.encoding
    )

  gen_command += " {type} {src} {gen_dir}".format(
    src=src_dir,
    type=type,
    gen_dir=gen_dir,
  )

  return gen_command

def _gen_impl(ctx):
    src_dir = _files(ctx.files.srcs) if ctx.attr.files_not_dirs else _common_dir([f.dirname for f in ctx.files.srcs])

    gen_dir = "{out}-tmp".format(
         out=ctx.outputs.codegen.path
    )

    commands = [
        "mkdir -p {gen_dir}".format(gen_dir=gen_dir),
        _new_generator_command(ctx, src_dir, ctx.attr.type, gen_dir),
        # forcing a timestamp for deterministic artifacts
        "find {gen_dir} -exec touch -t 198001010000 {{}} \\;".format(
          gen_dir=gen_dir
        ),
        "{jar} cMf {output} -C {gen_dir} .".format(
          jar="%s/bin/jar" % ctx.attr._jdk[java_common.JavaRuntimeInfo].java_home,
          output=ctx.outputs.codegen.path,
          gen_dir=gen_dir
        )
    ]

    inputs = ctx.files.srcs + ctx.files._jdk + [
      ctx.file.avro_tools,
    ]

    ctx.actions.run_shell(
        inputs = inputs,
        outputs = [ctx.outputs.codegen],
        command = " && ".join(commands),
        progress_message = "generating avro srcs",
        arguments = [],
      )

    return struct(
      codegen=ctx.outputs.codegen
    )

avro_gen = rule(
    attrs = {
        "srcs": attr.label_list(
          allow_files = [".avsc", ".avpr"],
        ),
        "type": attr.string(
            default = "schema",
            values = ["schema", "protocol"],
        ),
        "strings": attr.bool(),
        "encoding": attr.string(),
        "files_not_dirs": attr.bool(
            default = False
        ),
        "_jdk": attr.label(
                    default=Label("@bazel_tools//tools/jdk:current_java_runtime"),
                    providers = [java_common.JavaRuntimeInfo]
                ),
        "avro_tools": attr.label(
            cfg = "host",
            default = AVRO_LIBS_LABELS["tools"],
            allow_single_file = True,
        )
    },
    outputs = {
        "codegen": "%{name}_codegen.srcjar",
    },
    implementation = _gen_impl,
)

def avro_java_library(
  name, srcs=[], type=None, strings=None, encoding=None, visibility=None, files_not_dirs=False, avro_libs=None):
    libs = avro_libs if avro_libs else AVRO_LIBS_LABELS
    tools = libs["tools"]
    deps = [libs["core"]]

    avro_gen(
        name=name + '_srcjar',
        srcs = srcs,
        type = type,
        strings=strings,
        encoding=encoding,
        files_not_dirs=files_not_dirs,
        visibility=visibility,
        avro_tools=tools
    )
    native.java_library(
        name=name,
        srcs=[name + '_srcjar'],
        deps = deps,
        visibility=visibility,
    )

def avro_idl_gen(
        name,
        srcs = [],
        imports = [],
        strings = None,
        encoding = None,
        visibility = None,
        avro_tools = None):
    _avro_idl_gen(
        name = name + "_idl",
        srcs = srcs,
        imports = imports,
        avro_tools = avro_tools,
    )

    avro_gen(
        name = name,
        srcs = [name + "_idl"],
        type = "protocol",
        strings = strings,
        encoding = encoding,
        visibility = visibility,
        files_not_dirs = True,
        avro_tools = avro_tools,
    )

def avro_idl_java_library(
        name,
        srcs = [],
        imports = [],
        strings = None,
        encoding = None,
        visibility = None,
        avro_libs = None):
    """Generate a Java library from an AVRO IDL definition"""

    libs = avro_libs if avro_libs else AVRO_LIBS_LABELS
    tools = libs["tools"]
    deps = [libs["core"]]

    avro_idl_gen(
        name = name + "_srcjar",
        srcs = srcs,
        imports = imports,
        strings = strings,
        encoding = encoding,
        visibility = visibility,
        avro_tools = tools,
    )

    native.java_library(
        name = name,
        srcs = [name + "_srcjar"],
        deps = deps,
        visibility = visibility
    )
