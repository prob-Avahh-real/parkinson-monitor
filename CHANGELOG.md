# Changelog

All notable changes to Parkinson Monitor will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Environment configuration with flutter_dotenv
- Sentry crash reporting integration
- Firebase Analytics and Performance monitoring
- Automated release workflow for Android/iOS builds
- Deployment guides for Android and iOS platforms
- Architecture Decision Records (ADRs) for major decisions
- Makefile for common development tasks
- very_good_analysis for stricter code linting
- AppConfig class for centralized environment management
- MonitoringService for crash reporting and analytics

### Changed
- Updated CI/CD to use Flutter cache for faster builds
- Enhanced analysis_options.yaml with very_good_analysis
- Updated README with production setup instructions
- Added .env to Flutter assets

### Fixed
- N/A

## [1.0.0] - 2026-05-25

### Added
- Initial release of Parkinson Monitor
- BLE device connection and management
- Real-time sensor monitoring (accelerometer + gyroscope)
- Freeze of Gait detection using FFT analysis
- Resting tremor detection (4-6Hz frequency band)
- Bradykinesia detection (multi-dimensional assessment)
- GPS trajectory recording for outdoor mode
- Personalized calibration for detection thresholds
- PDF medical report generation
- Supabase cloud sync for data backup
- Clean Architecture implementation
- BLoC state management
- GetIt dependency injection
