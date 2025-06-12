# bazel avro rules <!-- omit in toc -->

[![Build Status](https://travis-ci.org/chenrui333/rules_avro.svg?branch=master)](https://travis-ci.org/chenrui333/rules_avro)

> [Bazel](https://bazel.build/) rules for generating java sources and libraries from [avro](https://avro.apache.org/) schemas

## Rules

- [Rules](#rules)
- [Getting started](#getting-started)
- [avro_gen](#avro_gen)
- [avro_java_library](#avro_java_library)

## Getting started

To use the Avro rules, add the following to your projects `WORKSPACE` file

```python
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# rules_avro depends on aspect_bazel_lib: https://github.com/bazel-contrib/bazel-lib
http_archive(
    name = "aspect_bazel_lib",
    sha256 = "63ae96db9b9ea3821320e4274352980387dc3218baeea0387f7cf738755d0f16",
    strip_prefix = "bazel-lib-2.19.1",
    url = "https://github.com/bazel-contrib/bazel-lib/releases/download/v2.19.1/bazel-lib-v2.19.1.tar.gz",
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

# rules_avro depends on rules_jvm_external: https://github.com/bazelbuild/rules_jvm_external
RULES_JVM_EXTERNAL_TAG = "4.1"
RULES_JVM_EXTERNAL_SHA = "f36441aa876c4f6427bfb2d1f2d723b48e9d930b62662bf723ddfb8fc80f0140"

http_archive(
    name = "rules_jvm_external",
    sha256 = RULES_JVM_EXTERNAL_SHA,
    strip_prefix = "rules_jvm_external-%s" % RULES_JVM_EXTERNAL_TAG,
    url = "https://github.com/bazelbuild/rules_jvm_external/archive/%s.zip" % RULES_JVM_EXTERNAL_TAG,
)


RULES_AVRO_VERSION = "96670d5c4a0a3e0f25f4177336e1fa94eba8be5a"
RULES_AVRO_SHA256 = "3bd69872ec72904e843762f7b3532fd1125215503a635a24f6c8037c75b299bc"

http_archive(
    name = "io_bazel_rules_avro",
    strip_prefix = "rules_avro-%s" % RULES_AVRO_VERSION,
    url = "https://github.com/chenrui333/rules_avro/archive/%s.tar.gz" % RULES_AVRO_VERSION,
    sha256 = RULES_AVRO_SHA256
)

load("@io_bazel_rules_avro//avro:avro.bzl", "avro_repositories")
avro_repositories()
# or specify a version
avro_repositories(version = "1.9.1")
```

Then in your `BUILD` file, just add the following so the rules will be available:

```python
load("@io_bazel_rules_avro//avro:avro.bzl", "avro_gen", "avro_java_library")
```

## avro_gen

```python
avro_gen(name, srcs, strings, encoding)
```

Generates `.srcjar` containing generated `.java` source files from a collection of `.avsc` schemas

<table class="table table-condensed table-bordered table-params">
  <colgroup>
    <col class="col-param" />
    <col class="param-description" />
  </colgroup>
  <thead>
    <tr>
      <th colspan="2">Attributes</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>name</code></td>
      <td>
        <code>Name, required</code>
        <p>A unique name for this rule.</p>
      </td>
    </tr>
    <tr>
      <td><code>srcs</code></td>
      <td>
        <code>List of labels, required</code>
        <p>
          List of <code>.avsc</code> files used as inputs for code generation
        </p>
      </td>
    </tr>
    <tr>
      <td><code>strings</code></td>
      <td>
        <code>Boolean, optional</code>
        <p>use <code>java.lang.String</code> instead of <code>Utf8</code>.</p>
      </td>
    </tr>
    <tr>
      <td><code>encoding</code></td>
      <td>
        <code>String, optional</code>
        <p>set the encoding of output files.</p>
      </td>
    </tr>
    <tr>
      <td><code>avro_tools</code></td>
      <td>
        <code>Label, optional</code>
        <p>Label to the runnable Avro tools jar. Default, uses the tools jar associated with the downloaded avro
        version via `avro_repository`</p>
      </td>
    </tr>
  </tbody>
</table>

## avro_java_library

```python
avro_java_library(name, srcs, strings, encoding)
```

Same as above except
  * instead of `avro_tools`, provide `avro_libs` as a dict(core, tools) of Labels for the avro libraries.
    * See tests for an example the re-uses the downloaded library explicitly
  * the outputs include those provided by `java_library` rules.
