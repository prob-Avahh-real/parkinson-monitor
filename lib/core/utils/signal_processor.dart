import 'dart:math' as math;
import 'dart:typed_data';

/// 实时信号处理工具 — FFT、滤波、特征提取
class SignalProcessor {
  /// 采样率 (Hz)
  final int sampleRate;

  SignalProcessor({this.sampleRate = 50});

  // ── FFT (Cooley-Tukey 基数-2，原地复数组) ──

  /// 对实数信号执行 FFT，返回幅度谱
  /// [signal] 长度必须是 2 的幂
  static List<double> fftMagnitudes(List<double> signal) {
    final n = signal.length;
    // 填充到 2 的幂
    final padded = _nextPowerOfTwo(n);
    final real = Float64List(padded);
    final imag = Float64List(padded);
    for (int i = 0; i < n; i++) {
      real[i] = signal[i];
    }
    _fft(real, imag);
    // 返回幅度 (只取前半)
    final mags = <double>[];
    final half = padded ~/ 2;
    for (int i = 0; i < half; i++) {
      final mag = math.sqrt(real[i] * real[i] + imag[i] * imag[i]);
      mags.add(mag);
    }
    return mags;
  }

  static void _fft(Float64List real, Float64List imag) {
    final n = real.length;
    // 位反转
    int j = 0;
    for (int i = 0; i < n; i++) {
      if (i < j) {
        double tmp = real[i]; real[i] = real[j]; real[j] = tmp;
        tmp = imag[i]; imag[i] = imag[j]; imag[j] = tmp;
      }
      int m = n >> 1;
      while (m >= 1 && j >= m) {
        j -= m;
        m >>= 1;
      }
      j += m;
    }
    // 蝶形运算
    for (int len = 2; len <= n; len <<= 1) {
      final half = len ~/ 2;
      final angle = -2.0 * math.pi / len;
      final wReal = math.cos(angle);
      final wImag = math.sin(angle);
      for (int i = 0; i < n; i += len) {
        double curReal = 1.0;
        double curImag = 0.0;
        for (int k = 0; k < half; k++) {
          final even = i + k;
          final odd = even + half;
          final tReal = curReal * real[odd] - curImag * imag[odd];
          final tImag = curReal * imag[odd] + curImag * real[odd];
          real[odd] = real[even] - tReal;
          imag[odd] = imag[even] - tImag;
          real[even] += tReal;
          imag[even] += tImag;
          final nextReal = curReal * wReal - curImag * wImag;
          curImag = curReal * wImag + curImag * wReal;
          curReal = nextReal;
        }
      }
    }
  }

  static int _nextPowerOfTwo(int n) {
    int p = 1;
    while (p < n) { p <<= 1; }
    return p;
  }

  // ── 频带功率计算 ──

  /// 计算指定频带的功率
  /// [mags] FFT 幅度
  /// [freqLow] 低频 (Hz)
  /// [freqHigh] 高频 (Hz)
  double bandPower(List<double> mags, double freqLow, double freqHigh) {
    final n = mags.length;
    final freqResolution = sampleRate / (2.0 * n);
    final lowIdx = (freqLow / freqResolution).round().clamp(0, n - 1);
    final highIdx = (freqHigh / freqResolution).round().clamp(0, n - 1);
    double power = 0;
    for (int i = lowIdx; i <= highIdx && i < n; i++) {
      power += mags[i] * mags[i];
    }
    return power / ((highIdx - lowIdx + 1).clamp(1, n));
  }

  /// 计算频带总功率 (不归一化)
  double totalBandPower(List<double> mags, double freqLow, double freqHigh) {
    final n = mags.length;
    final freqResolution = sampleRate / (2.0 * n);
    final lowIdx = (freqLow / freqResolution).round().clamp(0, n - 1);
    final highIdx = (freqHigh / freqResolution).round().clamp(0, n - 1);
    double power = 0;
    for (int i = lowIdx; i <= highIdx && i < n; i++) {
      power += mags[i] * mags[i];
    }
    return power;
  }

  /// 计算冻结指数 (Freeze Index)
  /// FI = P(3-8 Hz) / P(0.5-3 Hz) — 使用总功率
  double freezeIndex(List<double> signal) {
    final mags = fftMagnitudes(signal);
    final locomotionPower = totalBandPower(mags, 0.5, 3.0);
    final freezePower = totalBandPower(mags, 3.0, 8.0);
    if (locomotionPower < 1e-10) return 10.0;
    return freezePower / locomotionPower;
  }

  /// 检测震颤主频率 (4-6 Hz 典型帕金森震颤)
  double? tremorPeakFrequency(List<double> signal) {
    final mags = fftMagnitudes(signal);
    if (mags.isEmpty) return null;
    final freqResolution = sampleRate / (2.0 * mags.length);
    // 在 3-8 Hz 范围找峰值
    final lowIdx = (3.0 / freqResolution).round().clamp(0, mags.length - 1);
    final highIdx = (8.0 / freqResolution).round().clamp(0, mags.length - 1);
    double maxMag = 0;
    int maxIdx = lowIdx;
    for (int i = lowIdx; i <= highIdx && i < mags.length; i++) {
      if (mags[i] > maxMag) {
        maxMag = mags[i];
        maxIdx = i;
      }
    }
    return maxIdx * freqResolution;
  }

  // ── 时域特征 ──

  /// 均方根 (RMS)
  double rms(List<double> signal) {
    if (signal.isEmpty) return 0;
    double sum = 0;
    for (final v in signal) {
      sum += v * v;
    }
    return math.sqrt(sum / signal.length);
  }

  /// 信号幅值 (peak-to-peak)
  double amplitude(List<double> signal) {
    if (signal.isEmpty) return 0;
    double minVal = signal.first;
    double maxVal = signal.first;
    for (final v in signal) {
      if (v < minVal) minVal = v;
      if (v > maxVal) maxVal = v;
    }
    return maxVal - minVal;
  }

  /// 过零率 (Zero-Crossing Rate)
  int zeroCrossings(List<double> signal) {
    int count = 0;
    for (int i = 1; i < signal.length; i++) {
      if ((signal[i] >= 0 && signal[i - 1] < 0) ||
          (signal[i] < 0 && signal[i - 1] >= 0)) {
        count++;
      }
    }
    return count;
  }

  /// 步频估计 (基于加速度计垂直轴的周期性)
  double estimateCadence(List<double> verticalAccel) {
    final mags = fftMagnitudes(verticalAccel);
    if (mags.isEmpty) return 0;
    final freqResolution = sampleRate / (2.0 * mags.length);
    // 步频通常在 0.5-3 Hz
    final lowIdx = (0.5 / freqResolution).round().clamp(1, mags.length - 1);
    final highIdx = (3.0 / freqResolution).round().clamp(1, mags.length - 1);
    double maxMag = 0;
    int maxIdx = lowIdx;
    for (int i = lowIdx; i <= highIdx && i < mags.length; i++) {
      if (mags[i] > maxMag) {
        maxMag = mags[i];
        maxIdx = i;
      }
    }
    return maxIdx * freqResolution * 60; // 转为步/分钟
  }

  // ── 滑动窗口 (原始 double 缓冲区) ──

  final List<double> _accelMagBuffer = [];
  final List<double> _accelZBuffer = [];
  final List<double> _accelXBuffer = [];
  final List<double> _gyroMagBuffer = [];
  static const int windowSizeSeconds = 6;

  void addReading(double accelX, double accelY, double accelZ,
      double gyroX, double gyroY, double gyroZ) {
    final accelMag = math.sqrt(accelX * accelX + accelY * accelY + accelZ * accelZ);
    final gyroMag = math.sqrt(gyroX * gyroX + gyroY * gyroY + gyroZ * gyroZ);

    _accelMagBuffer.add(accelMag);
    _accelZBuffer.add(accelZ);
    _accelXBuffer.add(accelX);
    _gyroMagBuffer.add(gyroMag);

    final maxSize = sampleRate * windowSizeSeconds;
    while (_accelMagBuffer.length > maxSize) {
      _accelMagBuffer.removeAt(0);
      _accelZBuffer.removeAt(0);
      _accelXBuffer.removeAt(0);
      _gyroMagBuffer.removeAt(0);
    }
  }

  List<double> get accelMagnitudes => List.unmodifiable(_accelMagBuffer);
  List<double> get verticalAccel => List.unmodifiable(_accelZBuffer);
  List<double> get horizontalAccel => List.unmodifiable(_accelXBuffer);
  List<double> get gyroMagnitudes => List.unmodifiable(_gyroMagBuffer);

  int get bufferSize => _accelMagBuffer.length;

  void clear() {
    _accelMagBuffer.clear();
    _accelZBuffer.clear();
    _accelXBuffer.clear();
    _gyroMagBuffer.clear();
  }
}
