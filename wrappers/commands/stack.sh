#!/bin/sh
# shellcheck shell=sh # Written to be POSIX-compatible

set -e # Exit on false

# shellcheck source=scripts/libs/cp4c.shlib
. "$(pwd)/scripts/libs/cp4c.shlib"
. "$(pwd)/scripts/libs/die.shlib"

# Command overrides
STACK=stack
BREW=brew
CHOCO=choco
APT_GET=apt-get

# Check if command 'stack' is available
if cp4c stack; then
	true
elif ! cp4c stack; then
	case "$KERNEL" in
		linux)
			if cp4c apt-get; then
				case "$DISTRO" in
					debian|devuan)
						printf 'WARNING: %s\n' "As of 03/10/2020-EU $DISTRO does not have package 'haskell-stack' in stable/testing release so you might need to adjust your sources.list to use unstable target"
						$APT_GET install --yes haskell-stack
					;;
					*) die fixme "Distribution '$DISTRO' is not implemented to install required 'stack' command on kernel '$KERNEL'"
				esac
			fi
		;;
		darwin)
			# Check for options to install stack
			if cp4c $BREW; then
				$BREW install haskell-stack
			elif ! cp4c $BREW; then
				die fixme "Not implemented - We require command 'stack' which is not available and this darwin system doesn't have homebrew installed"
			else
				die unexpected
			fi
		;;
		windows)
			if cp4c $CHOCO; then
				$CHOCO install haskell-stack
			elif ! cp4c $CHOCO; then
				die false "Unable to install package 'haskell-stack' to get command 'stack' required for building"
			else
				die unexpected
			fi
		;;
		*) die 26 "Kernel '$KERNEL' is not implemented"
	esac
fi

# Execute
$STACK "$*"