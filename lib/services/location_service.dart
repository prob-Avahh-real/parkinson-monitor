import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../domain/entities/monitoring_session.dart';

/// GPS 位置跟踪服务 — 户外模式专用
class LocationService {
  StreamSubscription<Position>? _positionSub;
  final List<GpsPoint> _path = [];
  double _totalDistance = 0;
  Position? _lastPosition;
  bool _isTracking = false;

  List<GpsPoint> get path => List.unmodifiable(_path);
  double get totalDistance => _totalDistance;
  bool get isTracking => _isTracking;

  /// 开始 GPS 跟踪
  Future<bool> startTracking() async {
    // 检查权限
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    _isTracking = true;
    _path.clear();
    _totalDistance = 0;
    _lastPosition = null;

    // 高精度定位，每 5 米或 5 秒更新
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
        timeLimit: null,
      ),
    ).listen(_onPosition);

    return true;
  }

  void _onPosition(Position position) {
    final point = GpsPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: position.timestamp,
    );
    _path.add(point);

    // 累计距离
    if (_lastPosition != null) {
      _totalDistance += Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );
    }
    _lastPosition = position;
  }

  /// 停止 GPS 跟踪，返回路径和总距离
  ({List<GpsPoint> path, double totalDistance}) stopTracking() {
    _isTracking = false;
    _positionSub?.cancel();
    _positionSub = null;
    final result = (path: List<GpsPoint>.from(_path), totalDistance: _totalDistance);
    _path.clear();
    _totalDistance = 0;
    _lastPosition = null;
    return result;
  }

  void dispose() {
    _positionSub?.cancel();
  }
}
