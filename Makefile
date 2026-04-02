SHELL := /bin/bash
SCRIPTS := ast ast-hook

.PHONY: check lint fmt fmt-fix test test-live install uninstall

check: lint fmt test

lint:
	shellcheck $(SCRIPTS)

fmt:
	shfmt -i 2 -d $(SCRIPTS)

fmt-fix:
	shfmt -i 2 -w $(SCRIPTS)

test:
	bats test/

test-live:
	AST_LIVE=1 bats test/

install:
	ln -sf $(CURDIR)/ast /usr/local/bin/ast

uninstall:
	rm -f /usr/local/bin/ast
