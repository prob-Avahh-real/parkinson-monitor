.PHONY: help install test analyze format clean build-android build-ios release

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: ## Install dependencies
	flutter pub get

test: ## Run unit tests
	flutter test

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

build-android: ## Build Android APK
	flutter build apk --release

build-android-bundle: ## Build Android App Bundle (for Play Store)
	flutter build appbundle --release

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

release: ## Create a new release (manual version tagging)
	@echo "Creating a new release..."
	@echo "This will trigger the release workflow on GitHub"
	@read -p "Enter version (e.g., 1.0.1): " version; \
	git tag -a "v$$version" -m "Release v$$version"; \
	git push origin "v$$version"
