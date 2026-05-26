import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/monitoring_repository.dart';
import '../../../domain/entities/sensor_reading.dart';
import '../../../domain/entities/detection_event.dart';
import '../../../domain/entities/movement_disorder_type.dart';

part 'monitoring_event.dart';
part 'monitoring_state.dart';

/// 监测 BLoC
class MonitoringBloc extends Bloc<MonitoringEvent, MonitoringState> {
  final MonitoringRepository _monitoringRepository;
  StreamSubscription? _sensorSub;
  StreamSubscription? _detectionSub;

  MonitoringBloc({required this._monitoringRepository}) : super(const MonitoringState()) {
    on<StartMonitoring>(_onStart);
    on<StopMonitoring>(_onStop);
    on<SensorDataReceived>(_onSensorData);
    on<DetectionReceived>(_onDetection);
    on<UpdateMetrics>(_onMetrics);
  }

  Future<void> _onStart(
      StartMonitoring event, Emitter<MonitoringState> emit) async {
    final session = await _monitoringRepository.startSession(event.mode);

    emit(state.copyWith(
      isMonitoring: true,
      mode: event.mode,
      sessionStart: session.startTime,
      status: 'normal',
      recentEvents: [],
    ));

    // 监听传感器数据
    _sensorSub = _monitoringRepository.sensorStream.listen((reading) {
      add(SensorDataReceived(reading));
    });

    // 监听检测事件
    _detectionSub = _monitoringRepository.detectionStream.listen((event) {
      add(DetectionReceived(event));
    });
  }

  void _onSensorData(SensorDataReceived event, Emitter<MonitoringState> emit) {
    emit(state.copyWith(latestReading: event.reading));
  }

  void _onDetection(DetectionReceived event, Emitter<MonitoringState> emit) {
    final updatedEvents = List<DetectionEvent>.from(state.recentEvents)
      ..insert(0, event.event);
    if (updatedEvents.length > 50) {
      updatedEvents.removeLast();
    }

    String status;
    switch (event.event.type) {
      case MovementDisorderType.freezingOfGait:
        status = 'fog';
        break;
      case MovementDisorderType.restingTremor:
        status = 'tremor';
        break;
      case MovementDisorderType.bradykinesia:
        status = 'brady';
        break;
      default:
        status = 'normal';
    }

    emit(state.copyWith(
      status: status,
      recentEvents: updatedEvents,
    ));
  }

  void _onMetrics(UpdateMetrics event, Emitter<MonitoringState> emit) {
    emit(state.copyWith(metrics: event.metrics));
  }

  Future<void> _onStop(
      StopMonitoring event, Emitter<MonitoringState> emit) async {
    await _sensorSub?.cancel();
    await _detectionSub?.cancel();
    await _monitoringRepository.stopSession();

    emit(MonitoringState(
      isMonitoring: false,
      mode: state.mode,
    ));
  }

  @override
  Future<void> close() {
    _sensorSub?.cancel();
    _detectionSub?.cancel();
    return super.close();
  }
}
