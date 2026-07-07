# Documentation

This directory contains project documentation including architecture decision records (ADRs) and deployment guides.

## Contents

### Architecture Decision Records (ADRs)
- [ADR 001: Architecture Overview](adr/001-architecture-overview.md) - Overall architecture and technology choices
- [ADR 002: Signal Processing with Custom FFT Implementation](adr/002-signal-processing-fft.md) - Custom FFT implementation decision

### Deployment Guides
- [Android Deployment](deployment/android.md) - Guide for building and deploying to Google Play Store
- [iOS Deployment](deployment/ios.md) - Guide for building and deploying to App Store

## Adding New ADRs

When making significant architectural decisions, create a new ADR:

1. Create a new file in `docs/adr/` with the format `###-title.md`
2. Use the following template:
```markdown
# ADR ###: Title

## Status
Proposed | Accepted | Deprecated | Superseded

## Context
What is the issue that we're seeing that is motivating this decision?

## Decision
What is the change that we're proposing and/or doing?

## Consequences
What becomes easier or more difficult to do because of this change?

## Alternatives Considered
What other options did we consider and why did we reject them?

## References
Links to relevant documentation, research papers, etc.
```

3. Update this README to include the new ADR

## Updating Deployment Guides

When deployment processes change, update the relevant deployment guide with:
- New prerequisites
- Updated configuration steps
- New troubleshooting information
- Security considerations
