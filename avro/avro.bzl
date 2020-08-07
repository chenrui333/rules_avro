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

def _new_generator_command(ctx, src_dir, gen_dir):
  java_path = ctx.attr._jdk[java_common.JavaRuntimeInfo].java_executable_exec_path
  gen_command  = "{java} -jar {tool} compile ".format(
     java=java_path,
     tool=ctx.file._avro_tools.path,
  )

  if ctx.attr.strings:
    gen_command += " -string"

  if ctx.attr.encoding:
    gen_command += " -encoding {encoding}".format(
      encoding=ctx.attr.encoding
    )

  gen_command += " schema {src} {gen_dir}".format(
    src=src_dir,
    gen_dir=gen_dir
  )

  return gen_command

def _impl(ctx):
    src_dir = _common_dir([f.dirname for f in ctx.files.srcs])

    gen_dir = "{out}-tmp".format(
         out=ctx.outputs.codegen.path
    )

    commands = [
        "mkdir -p {gen_dir}".format(gen_dir=gen_dir),
        _new_generator_command(ctx, src_dir, gen_dir),
        # forcing a timestamp for deterministic artifacts
        "find {gen_dir} -exec touch -t 198001010000 {{}} \;".format(
          gen_dir=gen_dir
        ),
        "{jar} cMf {output} -C {gen_dir} .".format(
          jar="%s/bin/jar" % ctx.attr._jdk[java_common.JavaRuntimeInfo].java_home,
          output=ctx.outputs.codegen.path,
          gen_dir=gen_dir
        )
    ]

    inputs = ctx.files.srcs + ctx.files._jdk + [
      ctx.file._avro_tools,
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
          allow_files = [".avsc"]
        ),
        "strings": attr.bool(),
        "encoding": attr.string(),
        "_jdk": attr.label(
                    default=Label("@bazel_tools//tools/jdk:current_java_runtime"),
                    providers = [java_common.JavaRuntimeInfo]
                ),
        "_avro_tools": attr.label(
            cfg = "host",
            default = Label(
                _format_maven_jar_dep_name(
                    group_id = AVRO_TOOLS[0],
                    artifact_id = AVRO_TOOLS[1],
                    repo_name = MAVEN_REPO_NAME,
                ),
            ),
            allow_single_file = True,
        )
    },
    outputs = {
        "codegen": "%{name}_codegen.srcjar",
    },
    implementation = _impl,
)


def avro_java_library(
  name, srcs=[], strings=None, encoding=None, visibility=None):
    avro_gen(
        name=name + '_srcjar',
        srcs = srcs,
        strings=strings,
        encoding=encoding,
        visibility=visibility,
    )
    native.java_library(
        name=name,
        srcs=[name + '_srcjar'],
        deps = [
          Label(
              _format_maven_jar_dep_name(
                  group_id = AVRO[0],
                  artifact_id = AVRO[1],
                  repo_name = MAVEN_REPO_NAME,
              ),
          ),
        ],
        visibility=visibility,
    )
