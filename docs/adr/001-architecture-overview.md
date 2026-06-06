# ADR 001: Architecture Overview

## Status
Accepted

## Context
Parkinson Monitor is a cross-platform Flutter application for monitoring Parkinson's disease symptoms through BLE wearable devices and phone sensors. The application requires real-time signal processing, offline capability, and optional cloud synchronization.

## Decision
We adopted Clean Architecture with the following layers:

### Layer Structure
```
lib/
├── core/           # Core utilities (config, theme, DI, signal processing)
├── domain/         # Business logic (entities, repository interfaces)
├── data/           # Data layer (models, repository implementations)
├── services/       # Business services (BLE, detection, location, feedback)
└── presentation/   # UI layer (pages, BLoCs)
```

### Key Architectural Patterns
- **Clean Architecture**: Separation of concerns with dependency inversion
- **BLoC Pattern**: State management using flutter_bloc
- **Repository Pattern**: Data access abstraction
- **Dependency Injection**: GetIt for service locator pattern
- **Signal Processing**: Custom FFT implementation for real-time analysis

### Technology Choices
- **Flutter**: Cross-platform UI framework
- **Dart**: Programming language
- **BLoC**: State management
- **GetIt**: Dependency injection
- **Hive**: Local storage
- **Supabase**: Cloud sync
- **flutter_blue_plus**: BLE communication

## Consequences
### Positive
- Clear separation of concerns
- Testable components
- Maintainable codebase
- Platform independence
- Offline-first capability

### Negative
- Increased boilerplate code
- Learning curve for team members
- Initial setup complexity

## Alternatives Considered
- **Provider**: Simpler but less scalable for complex state
- **Riverpod**: More modern but smaller ecosystem
- **GetX**: Less opinionated but less structured
- **Redux**: Overkill for this use case

## References
- Clean Architecture by Robert C. Martin
- Flutter BLoC documentation
- GetIt documentation
