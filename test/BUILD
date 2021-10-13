load("//avro:avro.bzl", "avro_gen", "avro_java_library")

avro_java_library(
    name = "defaults",
    srcs = glob(
        ["src/**/*.avsc"],
    ),
)

avro_java_library(
    name = "customs",
    srcs = glob(
        ["src/**/*.avsc"],
    ),
    strings = True,
)

avro_java_library(
    name = "files",
    srcs = glob(
        ["src/**/*.avsc"],
    ),
    files_not_dirs = True,
    strings = True,
)

avro_java_library(
    name = "custom_tool",
    srcs = glob(
        ["src/**/*.avsc"],
    ),
    # adds the dependency on the downloaded avro library to the java_library, so the sources can compile
    # while using the specified tools to compile the schema
    avro_libs = {
        "core": "@avro//:org_apache_avro_avro",
        "tools": "@avro//:org_apache_avro_avro_tools",
    },
    strings = True,
)
