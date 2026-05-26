import 'package:equatable/equatable.dart';

/// 单次传感器读数
class SensorReading extends Equatable {
  final DateTime timestamp;
  final double accelX;
  final double accelY;
  final double accelZ;
  final double gyroX;
  final double gyroY;
  final double gyroZ;

  const SensorReading({
    required this.timestamp,
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
  });

  /// 加速度幅值 (g-force magnitude)
  double get accelMagnitude =>
      _sqrt(accelX * accelX + accelY * accelY + accelZ * accelZ);

  /// 角速度幅值
  double get gyroMagnitude =>
      _sqrt(gyroX * gyroX + gyroY * gyroY + gyroZ * gyroZ);

  static double _sqrt(double v) =>
      v <= 0 ? 0 : _sqrtIter(v, v, 20);
  static double _sqrtIter(double x, double guess, int iterations) {
    if (iterations == 0) return guess;
    final next = (guess + x / guess) * 0.5;
    return _sqrtIter(x, next, iterations - 1);
  }

  @override
  List<Object?> get props => [
        timestamp,
        accelX,
        accelY,
        accelZ,
        gyroX,
        gyroY,
        gyroZ,
      ];
}
