_avro_filetype = FileType([".avsc"])

def _commonprefix(m):
    if not m: return ''
    s1 = min(m)
    s2 = max(m)
    for i, c in enumerate([s for s in s1]):
        if c != s2[i]:
            return s1[:i]
    return s1

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


  # transitive deps
  native.maven_jar(
      name = "org_codehaus_jackson_jackson_core_asl",
      artifact = "org.codehaus.jackson:jackson-core-asl:1.9.13",
      sha1 = "3c304d70f42f832e0a86d45bd437f692129299a4",
  )
  native.bind(
      name = 'io_bazel_rules_avro/dependency/jackson_core_asl',
      actual = '@org_codehaus_jackson_jackson_core_asl//jar',
  )

  # transitent dependencies
  native.maven_jar(
      name = "org_codehaus_jackson_jackson_mapper_asl",
      artifact = "org.codehaus.jackson:jackson-mapper-asl:1.9.13",
      sha1 = "1ee2f2bed0e5dd29d1cb155a166e6f8d50bbddb7",
  )
  native.bind(
      name = 'io_bazel_rules_avro/dependency/jackson_mapper_asl',
      actual = '@org_codehaus_jackson_jackson_mapper_asl//jar',
  )


def _new_generator_command(ctx, src_dir, gen_dir):
  gen_command  = "{java} -jar {tool} compile ".format(
     java=ctx.executable._java.path,
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
    src_dir = _commonprefix(
      [f.path for f in ctx.files.srcs]
    )
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
          jar=ctx.file._jar.path,
          output=ctx.outputs.codegen.path,
          gen_dir=gen_dir
        )
    ]

    inputs = ctx.files.srcs + ctx.files._jdk + [
      ctx.executable._java,
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
          allow_files = _avro_filetype
        ),
        "strings": attr.bool(),
        "encoding": attr.string(),
        "_jdk": attr.label(
          default=Label("//tools/defaults:jdk"),
          allow_files=True
        ),
        "_java": attr.label(
            executable = True,
            cfg = "host",
            default = Label("@bazel_tools//tools/jdk:java"),
            single_file = True,
            allow_files = True,
        ),
        "_jar": attr.label(
            default=Label("@bazel_tools//tools/jdk:jar"),
            allow_files=True,
            single_file=True
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
