# bazel avro rules

[![Build Status](https://travis-ci.org/chenrui333/rules_avro.svg?branch=master)](https://travis-ci.org/chenrui333/rules_avro)

> [Bazel](https://bazel.build/) rules for generating java sources and libraries from [avro](https://avro.apache.org/) schemas

## Rules

* [avro_gen](#avro_gen)
* [avro_java_library](#avro_java_library)

## Getting started

To use the Avro rules, add the following to your projects `WORKSPACE` file

```python
# rules_avro depends on rules_jvm_external: https://github.com/bazelbuild/rules_jvm_external
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

RULES_JVM_EXTERNAL_TAG = "2.7"

RULES_JVM_EXTERNAL_SHA = "f04b1466a00a2845106801e0c5cec96841f49ea4e7d1df88dc8e4bf31523df74"

http_archive(
    name = "rules_jvm_external",
    sha256 = RULES_JVM_EXTERNAL_SHA,
    strip_prefix = "rules_jvm_external-%s" % RULES_JVM_EXTERNAL_TAG,
    url = "https://github.com/bazelbuild/rules_jvm_external/archive/%s.zip" % RULES_JVM_EXTERNAL_TAG,
)


rules_avro_version="c9bfdda9e909e4213abc595a07353e0d23128bbd" # update this commit hash as needed

git_repository(
    name = "io_bazel_rules_avro",
    commit = rules_avro_version,
    remote = "git@github.com:meetup/rules_avro.git",
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

Meetup 2017
