SHELL_FILES := install.sh setup.sh $(wildcard lib/*.sh) $(wildcard tests/stubs/*)

.PHONY: test lint unit

test: lint unit

lint:
	shellcheck -x $(wildcard $(SHELL_FILES))

unit:
	bats tests
