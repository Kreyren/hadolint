# This file is used for repository management

# Project metadata
NAME ?= hadolint

# Using POSIX sh to be POSIX compatible
SHELL ?= sh

# Command overrides
STACK ?= wrappers/commands/stack.sh
MKDIR ?= mkdir
RM ?= rm
CHMOD ?= chmod

# File hierarchy overrides
BUILD ?= $(PWD)/build

# System metadata
KERNEL ?= $(shell uname -s)
DISTRO ?= $(shell cat /etc/os-release | grep ^ID\= | sed s/^ID\=//g)
RELEASE ?= $(shell cat /etc/os-release | grep ^VERSION_CODENAME\= | sed s/^VERSION_CODENAME\=//g | sed s/\"//g)

.PHONY: all build run test

all: list

#@ List all targets
list:
	@ true \
		&& grep -A 1 "^#@.*" Makefile | sed s/--//gm | sed s/:.*//gm | sed "s/#@/#/gm" | while IFS= read -r line; do \
			case "$$line" in \
				"#"*|"") printf '%s\n' "$$line" ;; \
				*) printf '%s\n' "make $$line"; \
			esac; \
		done

build-deps:
	@ case "$

# FIXME-QA(Krey): Build process taken from https://ci.appveyor.com/project/hadolint/hadolint/branch/master#L33 need peer-review
#@ Initiate the build
build:
	@ $(STACK) --version 1>/dev/null 
	@ [ -d "$(BUILD)" ] || "$(MKDIR)" "$(BUILD)"
	@ [ -d "$(BUILD)/$(NAME)" ] || "$(MKDIR)" "$(BUILD)/$(NAME)"
	@ $(STACK) --no-terminal --install-ghc test --only-dependencies --keep-going
	@ $(STACK) --no-terminal --local-bin-path "$(BUILD)/$(NAME)" install --flag hadolint:static

#@ Run the software - Arguments can be provided using 'make HADOLINT_ARGS="your arguments here" run'
run: build
	@ [ -x "$(BUILD)/$(NAME)/$(NAME)" ] || "$(CHMOD)" +x "$(BUILD)/$(NAME)/$(NAME)""
	@ "$(BUILD)/$(NAME)/$(NAME)" $(HADOLINT_ARGS)

#@ Run linting software
lint: lint-shellcheck

#@ Run shellcheck on supported files
lint-shellcheck:
	@ find . -name *.sh -or -name *.bash -or -name *.zsh -type f | shellcheck -

#@ Runs the test of the software
test: build
	@ $(STACK) test

#@ Cleans the build result
clean:
	@ [ ! -d "$(BUILD)" ] || rm -r "$(BUILD)"
