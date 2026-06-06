# ADR 002: Signal Processing with Custom FFT Implementation

## Status
Accepted

## Context
The application requires real-time analysis of accelerometer and gyroscope data to detect Parkinson's disease symptoms (Freezing of Gait, Resting Tremor, Bradykinesia). The detection algorithms rely on frequency domain analysis using Fast Fourier Transform (FFT).

## Decision
We implemented a custom Cooley-Tukey radix-2 FFT algorithm in pure Dart instead of using external libraries.

### Implementation Details
- **Algorithm**: Cooley-Tukey radix-2 FFT
- **Language**: Pure Dart (no native dependencies)
- **Window Size**: 6 seconds sliding window (300 samples at 50Hz)
- **Frequency Bands**:
  - Freeze Index: 3-8Hz vs 0.5-3Hz power ratio
  - Tremor: 4-6Hz peak detection
  - Bradykinesia: Multi-dimensional time-domain analysis

### Key Features
- Offline capability (no network required)
- Real-time processing (50Hz sampling rate)
- Cross-platform (works on all Flutter platforms)
- Customizable thresholds per user

## Consequences
### Positive
- No external dependencies
- Offline-first capability
- Cross-platform compatibility
- Full control over algorithm
- Optimized for mobile devices

### Negative
- Maintenance burden (custom code)
- Limited to radix-2 (power of 2 sizes)
- Performance may be lower than native implementations
- Requires thorough testing

## Alternatives Considered
- **dart FFT libraries**: Limited ecosystem, often unmaintained
- **Platform channels**: Adds complexity, breaks offline capability
- **WebAssembly**: Not supported on all platforms
- **Native plugins**: Platform-specific, increases complexity

## References
- Moore et al. (2008), "Automatic detection of freezing of gait"
- Deuschl et al. (1998), "Tremor in Parkinson's disease"
- Cooley & Tukey (1965), "An algorithm for the machine calculation of complex Fourier series"
