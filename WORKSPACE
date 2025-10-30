workspace(name = "io_bazel_rules_avro")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "aspect_bazel_lib",
    sha256 = "53cadea9109e646a93ed4dc90c9bbcaa8073c7c3df745b92f6a5000daf7aa3da",
    strip_prefix = "bazel-lib-2.21.2",
    url = "https://github.com/bazel-contrib/bazel-lib/releases/download/v2.21.2/bazel-lib-v2.21.2.tar.gz",
)

load("@aspect_bazel_lib//lib:repositories.bzl", "aspect_bazel_lib_dependencies", "aspect_bazel_lib_register_toolchains")

# Required bazel-lib dependencies

aspect_bazel_lib_dependencies()

# Required rules_shell dependencies
load("@rules_shell//shell:repositories.bzl", "rules_shell_dependencies", "rules_shell_toolchains")

rules_shell_dependencies()

rules_shell_toolchains()

# Register bazel-lib toolchains

aspect_bazel_lib_register_toolchains()

# Create the host platform repository transitively required by bazel-lib

load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("@platforms//host:extension.bzl", "host_platform_repo")

maybe(
    host_platform_repo,
    name = "host_platform",
)

RULES_JVM_EXTERNAL_TAG = "6.5"

RULES_JVM_EXTERNAL_SHA = "3a4d56357851cf5b0dae538b3f3e0612a4f58925dfb3cadb2e0c4e87d51e629e"

http_archive(
    name = "rules_jvm_external",
    sha256 = RULES_JVM_EXTERNAL_SHA,
    strip_prefix = "rules_jvm_external-%s" % RULES_JVM_EXTERNAL_TAG,
    url = "https://github.com/bazel-contrib/rules_jvm_external/releases/download/%s/rules_jvm_external-%s.tar.gz" % (RULES_JVM_EXTERNAL_TAG, RULES_JVM_EXTERNAL_TAG),
)

load("@rules_jvm_external//:repositories.bzl", "rules_jvm_external_deps")

rules_jvm_external_deps()

load("@rules_jvm_external//:setup.bzl", "rules_jvm_external_setup")

rules_jvm_external_setup()

load("//avro:avro.bzl", "avro_repositories")

avro_repositories(maven_install_json = "maven_install.json")
