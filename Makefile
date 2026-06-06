.PHONY: help install test test-coverage analyze format clean build-android build-ios release version-bump docs docs-serve

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: ## Install dependencies
	flutter pub get

test: ## Run unit tests
	flutter test

test-coverage: ## Run tests with coverage
	flutter test --coverage
	@echo "Coverage report generated in coverage/ directory"

test-integration: ## Run integration tests
	flutter test integration_test/

analyze: ## Run static analysis
	flutter analyze

format: ## Format code
	dart format .

format-check: ## Check code formatting
	dart format --set-exit-if-changed .

clean: ## Clean build artifacts
	flutter clean
	rm -rf build/
	rm -rf .dart_tool/
	rm -rf coverage/

build-android: ## Build Android APK
	flutter build apk --release

build-ios: ## Build iOS app
	flutter build ios --release --no-codesign

build-all: build-android build-ios ## Build all platforms

pub-upgrade: ## Upgrade dependencies
	flutter pub upgrade

pub-outdated: ## Check for outdated dependencies
	flutter pub outdated

run: ## Run the app in debug mode
	flutter run

run-release: ## Run the app in release mode
	flutter run --release

release: ## Create a new release
	@echo "Creating a new release..."
	@echo "This will trigger the release workflow on GitHub"
	@read -p "Enter version (e.g., 1.0.1): " version; \
	git tag -a "v$$version" -m "Release v$$version"; \
	git push origin "v$$version"

version-bump: ## Bump version based on conventional commits
	@echo "Version bumping is handled automatically by GitHub Actions"
	@echo "Merge a PR to main to trigger automatic version bump"

changelog: ## Generate changelog from commits
	@echo "Changelog is generated automatically by semantic-release"
	@echo "See CHANGELOG.md for the latest changes"

docs: ## Generate API documentation
	flutter pub global activate dartdoc
	flutter pub global run dartdoc:dartdoc

docs-serve: ## Serve API documentation locally
	flutter pub global activate dartdoc
	flutter pub global run dartdoc:dartdoc --serve

audit: ## Security audit — check for outdated/vulnerable dependencies
	flutter pub outdated
	@echo "---"
	@echo "Audit complete. Review outdated packages above."

metrics: ## DORA metrics — test duration, lint count, build status
	@echo "=== DORA Metrics ==="
	@echo "Test duration:"
	@time flutter test --reporter compact 2>/dev/null || true
	@echo ""
	@echo "Lint issues:"
	@flutter analyze 2>&1 | tail -1 || true
	@echo ""
	@echo "Dependencies — outdated count:"
	@flutter pub outdated 2>/dev/null | grep -c '✗' || echo "0"
