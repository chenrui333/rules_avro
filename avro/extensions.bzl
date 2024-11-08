load("//avro:avro.bzl", "AVRO_DEFAULT_VERSION", "avro_repositories")

def _avro_impl(module_ctx):
    for m in module_ctx.modules:
        if m.is_root:
            if m.tags.avro_artifacts:
                avro_artifacts = m.tags.avro_artifacts[-1]
                avro_repositories(
                    version = avro_artifacts.version,
                    excluded_artifacts = avro_artifacts.excluded_artifacts,
                )
            else:
                avro_repositories()

avro = module_extension(
    implementation = _avro_impl,
    tag_classes = {
        "avro_artifacts": tag_class(
            attrs = {
                "version": attr.string(default = AVRO_DEFAULT_VERSION),
                "excluded_artifacts": attr.string_list(),
            },
        ),
    },
)
