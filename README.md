# bazel avro rules

> [Bazel](https://bazel.build/) rules for generating [avro](https://avro.apache.org/) java sources and libraries

## Rules

* avro_gen
* avro_java_library

## Getting started

To use the Avro rules, add the following to your `WORKSPACE` file

```python
rules_avro_version="4413a57db613a1eba5d5a56ca48d7c6655726bb8" # update this as needed

git_repository(
    name = "io_bazel_rules_avro",
    commit = rules_avro_version,
    remote = "git@github.com:meetup/bazel-avro.git",
)

load("@io_bazel_rules_avro//avro:avro.bzl", "avro_repositories")
avro_repositories()
```

Then in your BUILD file just add the following so the rules will be available:
```python
load("@io_bazel_rules_avro//avro:avro.bzl", "avro_gen", "avro_java_library")
```

## avro_gen

```python
avro_gen(name, srcs, strings, big_decimals, encoding)
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
          List of `.avsc` files used as inputs for code generation
        </p>
      </td>
    </tr>
    <tr>
      <td><code>strings</code></td>
      <td>
        <code>Boolean, optional</code>
        <p>use java.lang.String instead of Utf8.</p>
      </td>
    </tr>
    <tr>
      <td><code>big_decimals</code></td>
      <td>
        <code>Boolean, optional</code>
        <p>use java.math.BigDecimal for.</p>
      </td>
    </tr>
    <tr>
      <td><code>encoding</code></td>
      <td>
        <code>String, optional</code>
        <p>set the encoding of output files.</p>
      </td>
    </tr>
  </tbody>
</table>


## avro_java_library

```python
avro_java_library(name, srcs, strings, big_decimals, encoding)
```

Same as above except that the outputs include those provided by `java_library` rules.

Meetup 2017
