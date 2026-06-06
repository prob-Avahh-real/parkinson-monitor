/// 统一的 Result 类型 — Errors-as-values 模式
///
/// 用于替换 try/catch 吞错误，强制调用方处理失败路径。
///
/// 用法：
/// ```dart
/// final result = await someOperation();
/// result.fold(
///   (value) => print('Success: $value'),
///   (error) => print('Failed: $error'),
/// );
/// ```
sealed class Result<T> {
  const Result();

  /// 成功时返回 value，否则返回 orElse
  T getOrElse(T Function(AppError error) orElse);

  /// 成功时执行 [onSuccess]，失败时执行 [onFailure]
  R fold<R>(R Function(T value) onSuccess, R Function(AppError error) onFailure);

  /// 映射成功值
  Result<R> map<R>(R Function(T value) transform);

  /// 是否成功
  bool get isSuccess;

  /// 是否失败
  bool get isFailure;

  /// 获取成功值（失败时抛异常，仅用于非关键路径）
  T get value;

  /// 获取错误（成功时抛异常）
  AppError get error;
}

/// 成功
class Success<T> extends Result<T> {
  final T _value;

  const Success(this._value);

  @override
  T getOrElse(AppError Function(AppError error) orElse) => _value;

  @override
  R fold<R>(R Function(T value) onSuccess, R Function(AppError error) onFailure) {
    return onSuccess(_value);
  }

  @override
  Result<R> map<R>(R Function(T value) transform) {
    return Success(transform(_value));
  }

  @override
  bool get isSuccess => true;

  @override
  bool get isFailure => false;

  @override
  T get value => _value;

  @override
  AppError get error => throw StateError('Cannot get error from Success');
}

/// 失败
class Failure<T> extends Result<T> {
  final AppError _error;

  const Failure(this._error);

  @override
  T getOrElse(T Function(AppError error) orElse) => orElse(_error);

  @override
  R fold<R>(R Function(T value) onSuccess, R Function(AppError error) onFailure) {
    return onFailure(_error);
  }

  @override
  Result<R> map<R>(R Function(T value) transform) {
    return Failure(_error);
  }

  @override
  bool get isSuccess => false;

  @override
  bool get isFailure => true;

  @override
  T get value => throw StateError('Cannot get value from Failure: ${_error.message}');

  @override
  AppError get error => _error;
}

/// 应用错误类型
class AppError {
  final String message;
  final String? code;
  final Object? cause;
  final StackTrace? stackTrace;

  const AppError({
    required this.message,
    this.code,
    this.cause,
    this.stackTrace,
  });

  factory AppError.unknown([Object? cause, StackTrace? stack]) {
    return AppError(
      message: 'An unexpected error occurred',
      code: 'UNKNOWN',
      cause: cause,
      stackTrace: stack,
    );
  }

  factory AppError.fromException(Object e, [StackTrace? stack]) {
    return AppError(
      message: e.toString(),
      code: 'EXCEPTION',
      cause: e,
      stackTrace: stack,
    );
  }

  @override
  String toString() => 'AppError($code, $message)';

  /// 友好消息（给最终用户）
  String get userMessage => switch (code) {
        'BLE_CONNECTION_FAILED' => '蓝牙连接失败，请检查设备是否开启',
        'BLE_DISCONNECTED' => '蓝牙设备已断开连接',
        'BLE_SCAN_FAILED' => '扫描蓝牙设备失败',
        'BLE_PERMISSION_DENIED' => '未授予蓝牙权限',
        'SENSOR_UNAVAILABLE' => '传感器不可用，请使用 BLE 设备',
        'NETWORK_ERROR' => '网络连接失败，请检查网络',
        'SUPABASE_SYNC_FAILED' => '云同步失败，数据已保存到本地',
        'SUPABASE_AUTH_FAILED' => '登录失败，请检查账号',
        'LOCATION_PERMISSION_DENIED' => '未授予位置权限',
        'LOCATION_UNAVAILABLE' => '位置服务不可用',
        'CALIBRATION_FAILED' => '传感器校准失败，请重试',
        'PDF_GENERATION_FAILED' => '报告生成失败，请重试',
        'MODEL_LOAD_FAILED' => 'ML 模型加载失败，使用标准检测',
        'DATA_CORRUPTION' => '本地数据损坏，已重置',
        'UNKNOWN' => '发生未知错误，请重试',
        'EXCEPTION' => '发生异常，请重试',
        _ => message,
      };
}

/// 便捷：结果类型别名
typedef AsyncResult<T> = Future<Result<T>>;
