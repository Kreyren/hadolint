# This file is used for repository management

# Project metadata
export NAME ?= hadolint
export PROJECT_DEFAULT_BRANCH ?= master

# Using POSIX sh to be POSIX compatible
export SHELL ?= sh

# Command overrides
export STACK ?= stack
export MKDIR ?= mkdir
export RM ?= rm
export CHMOD ?= chmod
export SHELLCHECK ?= shellcheck
export UNAME ?= uname
export SED ?= sed
export CAT ?= cat
export LS ?= ls

# Wrappers
export WRAP_STACK ?= $(PWD)/wrappers/commands/stack.sh

# Function overrides
export DIE ?= die
export CP4C ?= cp4c

# File hierarchy overrides
export BUILD ?= $(PWD)/build

# System metadata
KERNEL ?= $(shell $(UNAME) -s)
DISTRO ?= $(shell $(CAT) /etc/os-release | $(GREP) ^ID\= | $(SED) s/^ID\=//g)
RELEASE ?= $(shell $(CAT) /etc/os-release | $(GREP) ^VERSION_CODENAME\= | $(SED) s/^VERSION_CODENAME\=//g | $(SED) s/\"//g)

.PHONY: all build run test

all: list

#@ List all targets
list:
	@ grep -A 1 "^#@.*" Makefile | sed s/--//gm | sed s/:.*//gm | sed "s/#@/#/gm" | while IFS= read -r line; do \
		case "$$line" in \
			"#"*|"") printf '%s\n' "$$line" ;; \
			*) printf '%s\n' "make $$line"; \
		esac; \
	done

# WARNING(Krey): This task is halting on systems with less then 4GB tempfs
# FIXME-QA(Krey): Build process taken from https://ci.appveyor.com/project/hadolint/hadolint/brin	ranch/master#L33 need peer-review
# FIXME: Implement a method to install stack if it's not installed
#@ Initiate the build
build:
	@ [ -d "$(BUILD)" ] || "$(MKDIR)" "$(BUILD)"
	@ [ -d "$(BUILD)/$(NAME)" ] || "$(MKDIR)" "$(BUILD)/$(NAME)"
	@ $(WRAP_STACK) --version 1>/dev/null
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
	@ find . -name *.sh -or -name *.bash -or -name *.zsh -type f | $(SHELLCHECK) -

#@ Run shellcheck agains only changed files in comparison to PROJECT_DEFAULT_BRANCH
lint-changed-shellcheck:
	@ for file in $$(git diff --name-only "$(PROJECT_DEFAULT_BRANCH)" | grep ".*\.(sh|bash|zsh)$$" | tr '\n' ' '); do \
		true \
			&& $(PRINTF) "Linting file '%1s' type '%2s' using command '$(SHELLCHECK)'\\n" "$$file" "$$(file "$$file" | sed "s/^.*\:\ //g")" \
			&& $(SHELLCHECK) $(SHELLCHECK_FLAGS) "$$file" \
			&& $(PRINTF) '%s\n' "Finished checking file '$$file'" \
		; done

#@ Runs the test of the software
test: build
	@ $(WRAP_STACK) test

#@ Cleans the build result
clean:
	@ [ ! -d "$(BUILD)" ] || rm -r "$(BUILD)"
