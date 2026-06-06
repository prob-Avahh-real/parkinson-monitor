# Fastlane Configuration — Parkinson Monitor

## Prerequisites

```bash
brew install fastlane
cd parkinson-monitor/ios
bundle init
echo 'gem "fastlane"' >> Gemfile
bundle install
fastlane init
```

## Build & Upload

```bash
cd parkinson-monitor
# Build and upload to TestFlight
fastlane ios beta
# Build and upload to Google Play Internal Testing
fastlane android beta
```
