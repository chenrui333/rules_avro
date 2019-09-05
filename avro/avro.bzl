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

def _common_dir(files):
    if not files:
        return ""

    dirs = [f.dirname for f in files]

    if len(dirs) == 1:
        return dirs[0]

    split_dirs = [dir.split("/") for dir in dirs]

    # for each dir in the shortest, make sure all the dirs

    shortest = min(split_dirs)
    longest = max(split_dirs)

    for i, piece in enumerate(shortest):
        # if the next dir does not match, we've found our common parent
        if piece != longest[i]:
            return _join_list(shortest[:i], "/")

    return _join_list(shortest, "/")

def avro_repositories():
  # for code generation
  native.maven_jar(
      name = "org_apache_avro_avro_tools",
      artifact = "org.apache.avro:avro-tools:1.8.1",
      sha1 = "361c32d4cad8dea8e5944d588e7d410f9f2a7114",
  )
  native.bind(
      name = 'io_bazel_rules_avro/dependency/avro_tools',
      actual = '@org_apache_avro_avro_tools//jar',
  )

  # for code compilation
  native.maven_jar(
      name = "org_apache_avro_avro",
      artifact = "org.apache.avro:avro:1.8.1",
      sha1 = "f4e11d00055760dca33daab193192bd75cc87b59",
  )
  native.bind(
      name = 'io_bazel_rules_avro/dependency/avro',
      actual = '@org_apache_avro_avro//jar',
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
    src_dir = _common_dir(ctx.files.srcs)
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

    ctx.action(
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
            default = Label("//external:io_bazel_rules_avro/dependency/avro_tools"),
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
          Label("//external:io_bazel_rules_avro/dependency/avro")
        ],
        visibility=visibility,
    )
