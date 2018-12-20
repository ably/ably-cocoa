SHELL := /bin/bash
.PHONY: help setup submodules

RUBY := $(shell command -v ruby 2>/dev/null)
HOMEBREW := $(shell command -v brew 2>/dev/null)

default: help

# Add the following 'help' target to your Makefile
# And add help text after each target name starting with '\#\#'

# COLORS
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
WHITE  := $(shell tput -Txterm setaf 7)
RESET  := $(shell tput -Txterm sgr0)

## ----- Helper functions ------

# Helper target for declaring an external executable as a recipe dependency.
# For example,
#   `my_target: | _program_awk`
# will fail before running the target named `my_target` if the command `awk` is
# not found on the system path.
_program_%: FORCE
	@_=$(or $(shell which $* 2> /dev/null),$(error `$*` command not found. Please install `$*` and try again))

# Helper target for declaring required environment variables.
#
# For example,
#   `my_target`: | _var_PARAMETER`
#
# will fail before running `my_target` if the variable `PARAMETER` is not declared.
_var_%: FORCE
	@_=$(or $($*),$(error `$*` is a required parameter))

## ------ Commmands -----------

TARGET_MAX_CHAR_NUM=20
## Show help
help:
	@echo ''
	@echo 'Usage:'
	@echo '  ${YELLOW}make${RESET} ${GREEN}<target>${RESET}'
	@echo ''
	@echo 'Targets:'
	@awk '/^[a-zA-Z\-\_0-9]+:/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")-1); \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			printf "  ${YELLOW}%-$(TARGET_MAX_CHAR_NUM)s${RESET} ${GREEN}%s${RESET}\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' \
	$(MAKEFILE_LIST)

## Install dependencies.
setup: \
	submodules \
	install_carthage \
	update_carthage_dependencies \
	install_fastlane

## Update dependencies.
update: \
	submodules \
	update_carthage \
	update_carthage_dependencies \
	update_fastlane

install_fastlane:
	$(info Installing Fastlane…)

	gem install fastlane -v 2.108.0

update_fastlane:
	$(info Updating Fastlane…)

	gem update fastlane -v 2.108.0

install_carthage:
	$(info Installing Carthage…)

	brew unlink carthage || true
	brew install carthage
	brew link --overwrite carthage

update_carthage:
	$(info Updating Carthage…)

	brew upgrade carthage

## -- Source Code Tasks --

## Update git submodule's
submodules:
	$(info Updating submodules…)

	git submodule update --init --recursive
	
## -- Testing --

## [Tests] Run tests on iOS 12 using sandbox environment
test_iOS:
	ABLY_ENV="sandbox" NAME="ably-iOS" fastlane test_iOS12

## [Tests] Run tests on tvOS 12 using sandbox environment
test_tvOS:
	ABLY_ENV="sandbox" NAME="ably-tvOS" fastlane test_tvOS12

## [Tests] Run tests on macOS using sandbox environment
test_macOS:
	ABLY_ENV="sandbox" NAME="ably-macOS" fastlane test_macOS

## -- CocoaPods --

## [CocoaPods] Validates Ably pod
pod_lint:
	pod lib lint --swift-version=4.2 --allow-warnings

## -- Carthage --

## [Carthage] Make a .zip package of frameworks
carthage_package:
	$(info Building and archiving…)

	carthage build --no-skip-current --archive

## [Carthage] Clear Carthage caches. Helps with Carthage update issues
carthage_clean:
	$(info Deleting Carthage caches…)

	rm -rf ~/Library/Caches/org.carthage.CarthageKit/dependencies/

## [Carthage] Update dependencies
update_carthage_dependencies:
	$(info Updating Carthage dependencies for all platforms…)

	carthage update

## [Carthage] Update dependencies for iOS
update_carthage_dependencies_ios:
	$(info Updating Carthage dependencies for iOS…)

	carthage update --platform iOS

## [Carthage] Update dependencies for tvOS
update_carthage_dependencies_tvos:
	$(info Updating Carthage dependencies for tvOS…)

	carthage update --platform tvOS

## [Carthage] Update dependencies for macOS
update_carthage_dependencies_macos:
	$(info Updating Carthage dependencies for macOS…)

	carthage update --platform macOS

## -- Version --

## [Version] Bump Patch Version
bump_patch:
	$(info Bumping version Patch type…)

	Scripts/set-version.sh `Scripts/get-version.sh | awk -F. '{$$NF = $$NF + 1;} 1' | sed 's/ /./g'`

## [Version] Bump Minor Version
bump_minor:
	$(info Bumping version Minor type…)

	Scripts/set-version.sh `Scripts/get-version.sh | awk -F. '{$$(NF-1) = $$(NF-1) + 1;} 1' | sed 's/ /./g' | awk -F. '{$$(NF) = 0;} 1' | sed 's/ /./g' `

## [Version] Bump Major Version
bump_major:
	$(info Bumping version Major type…)

	Scripts/set-version.sh `Scripts/get-version.sh | awk -F. '{$$(NF-2) = $$(NF-2) + 1;} 1' | sed 's/ /./g' | awk -F. '{$$(NF-1) = 0;} 1' | sed 's/ /./g' | awk -F. '{$$(NF) = 0;} 1' | sed 's/ /./g' `
