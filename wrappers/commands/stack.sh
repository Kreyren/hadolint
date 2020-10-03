#!/bin/sh
# shellcheck shell=sh # Written to be POSIX-compatible

set -e # Exit on false

. scripts/libs/cp4c.shlib
. scripts/libs/die.shlib

# FIXME: Get this value from makefile
KERNEL="$(uname -s)"

# Krey: Command overrides
[ -n "$STACK" ] || BREW=brew
[ -n "$CHOCO" ] || CHOCO=choco
[ -n "$STACK" ] || STACK=stack
[ -n "$APT_GET" ] || APT_GET=apt-get

# Krey: Function overrides
[ -n "$CP4C" ] || CP4C=cp4c
[ -n "$DIE" ] || DIE=die

# Krey: Check if command 'stack' is available if not try to install it
if $CP4C $STACK; then
	$TRUE
elif ! $CP4C $STACK; then
	case "$KERNEL" in
		linux)
			if $CP4C $APT_GET; then
				case "$DISTRO" in
					debian|devuan)
						$PRINTF 'WARNING: %s\n' "As of 03/10/2020-EU $DISTRO does not have package 'haskell-stack' in stable/testing release so you might need to adjust your sources.list to use unstable target"
						$APT_GET install --yes haskell-stack
					;;
					*) die fixme "Distribution '$DISTRO' is not implemented to install required 'stack' command on kernel '$KERNEL'"
				esac
			else
				$DIE unexpected
			fi
		;;
		darwin)
			# Check for options to install stack
			if $CP4C $BREW; then
				$BREW install haskell-stack
			elif ! $CP4C $BREW; then
				$DIE fixme "Not implemented - We require command 'stack' which is not available and this darwin system doesn't have homebrew installed"
			else
				$DIE unexpected
			fi
		;;
		windows)
			if $CP4C $CHOCO; then
				$CHOCO install haskell-stack
			elif ! $CP4C $CHOCO; then
				$DIE false "Unable to install package 'haskell-stack' to get command 'stack' required for building"
			else
				$DIE unexpected
			fi
		;;
		*) $DIE 26 "Kernel '$KERNEL' is not implemented"
	esac
else
	$DIE unexpected
fi

# Execute
$STACK "$*"