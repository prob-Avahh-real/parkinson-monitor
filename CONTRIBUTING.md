# Contributing to Parkinson Monitor

Thank you for your interest in contributing to Parkinson Monitor! This document provides guidelines for contributing to the project.

## Development Setup

### Prerequisites
- Flutter 3.44+ / Dart 3.12+
- iOS 14+ or Android 8+ (for testing)
- Git

### Installation

1. Clone the repository:
```bash
git clone https://github.com/YOUR_ORG/parkinson-monitor.git
cd parkinson-monitor
```

2. Install dependencies:
```bash
make install
# or
flutter pub get
```

3. Set up environment configuration:
```bash
cp .env.example .env
# Edit .env with your configuration
```

## Development Workflow

### Running the App

```bash
# Debug mode
make run

# Release mode
make run-release
```

### Code Quality

Before committing, ensure your code passes all checks:

```bash
# Format code
make format

# Run static analysis
make analyze

# Run tests
make test

# Run tests with coverage
make test-coverage
```

### Pre-commit Hooks

The project uses pre-commit hooks to ensure code quality. The hooks will:
- Format code with `dart format`
- Run static analysis with `flutter analyze`
- Run tests with `flutter test`

If you need to bypass hooks (not recommended):
```bash
git commit --no-verify -m "Your message"
```

## Testing

### Unit Tests
```bash
make test
```

### Integration Tests
```bash
make test-integration
```

### Coverage
```bash
make test-coverage
```

Coverage reports are generated in the `coverage/` directory.

## Code Style

This project uses `very_good_analysis` for linting. Key rules:
- Use single quotes for strings
- Prefer `const` constructors
- Avoid `print` statements (use logging instead)
- Prefer final fields and locals

Run `make format` to automatically format your code.

## Branching Strategy

- `main` - Production branch
- `develop` - Development branch
- `feature/<ticket-id>-<description>` - Feature branches

### Creating a Feature Branch

```bash
git checkout develop
git pull origin develop
git checkout -b feature/TICKET-123-add-new-feature
```

### Commit Messages

Follow conventional commits format:
```
<type>(<scope>): <subject>

<body>

<footer>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

Examples:
```
feat(detection): add freeze index threshold calibration
fix(ble): handle connection timeout gracefully
docs(readme): update installation instructions
```

## Pull Request Process

1. Ensure your branch is up to date with `develop`
2. Run all tests and checks locally
3. Create a pull request to `develop`
4. Wait for CI/CD checks to pass
5. Request review from maintainers

### PR Checklist
- [ ] Code follows project style guidelines
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] All tests pass locally
- [ ] CI/CD checks pass

## Environment Configuration

The project uses environment variables for configuration. Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
```

Key environment variables:
- `SUPABASE_URL`: Supabase project URL
- `SUPABASE_ANON_KEY`: Supabase anonymous key
- `ENVIRONMENT`: development, staging, or production
- `ENABLE_CLOUD_SYNC`: Enable/disable cloud sync
- `ENABLE_ANALYTICS`: Enable/disable analytics

## Building

### Android
```bash
make build-android
```

### iOS
```bash
make build-ios
```

### All Platforms
```bash
make build-all
```

## Architecture

The project follows Clean Architecture:

```
lib/
├── core/           # Core utilities (config, theme, DI)
├── domain/         # Business logic (entities, repositories)
├── data/           # Data layer (models, repository implementations)
├── services/       # Business services (BLE, detection, location)
└── presentation/   # UI layer (pages, BLoCs)
```

## Adding New Features

1. Create feature branch from `develop`
2. Implement feature following architecture
3. Add unit tests
4. Update documentation
5. Create pull request

## Reporting Issues

When reporting issues, please include:
- Flutter/Dart version
- Platform (iOS/Android)
- Steps to reproduce
- Expected behavior
- Actual behavior
- Logs/screenshots if applicable

## Questions?

Feel free to open an issue for questions or discussion.
