# Changelog

All notable changes to Parkinson Monitor will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Enhanced CI/CD pipeline with Android/iOS build jobs
- Code coverage reporting with Codecov integration
- Dependency scanning and outdated package checks
- Automated code formatting checks in CI
- Pre-commit hooks for code quality enforcement
- Environment configuration with flutter_dotenv
- Environment-specific configs (.env.development, .env.production)
- AppConfig class for centralized environment management
- Widget tests for home_page and monitoring_page
- Integration tests for critical app flows
- Coverage configuration with minimum thresholds
- Makefile for common development tasks
- CONTRIBUTING.md with development guidelines
- very_good_analysis package for stricter linting

### Changed
- Updated analysis_options.yaml to use very_good_analysis
- Enhanced CI/CD to run on both main and develop branches
- Updated README with new development workflow
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
