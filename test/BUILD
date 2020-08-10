load("//avro:avro.bzl", "avro_gen", "avro_java_library")

avro_java_library(
    name = "defaults",
    srcs = glob(
        ["src/**/*.avsc"],
    ),
)

avro_java_library(
    name = "customs",
    strings = True,
    srcs = glob(
        ["src/**/*.avsc"],
    ),
)

avro_java_library(
    name = "files",
    strings = True,
    files_not_dirs = True,
    srcs = glob(
        ["src/**/*.avsc"],
    )
)
