build:
	@bazel build //... --noenable_bzlmod
	@bazel build //... --enable_bzlmod

test:
	@./test.sh

.PHONY: build test
