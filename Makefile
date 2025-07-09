.PHONY: cond all fetch rebase build test update

cond: fetch
	@HEAD=$$(git rev-parse HEAD^); \
	UPSTREAM=$$(git rev-parse upstream/master); \
	if [ "$$HEAD" = "$$UPSTREAM" ]; then \
		echo "Current branch is up to date. Skipping the rest."; \
		exit 0; \
	else \
		$(MAKE) -f Makefile all; \
	fi

all: rebase cache build test

fetch:
	git fetch upstream

rebase: fetch
	git rebase upstream/master

cache:
	lake exe cache get

# To build mathlib4
build: cache
	time lake build

# To build and run all tests
test: build
	time lake test

# If you added a new file, run the following to update Mathlib.lean
update:
	lake exe mk_all
