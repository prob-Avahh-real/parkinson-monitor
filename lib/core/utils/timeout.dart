import 'dart:async';
import 'result.dart';

/// 外部调用超时包装器
///
/// 所有网络/BLE/传感器调用必须设超时——没有超时等于隐式 bug。
/// 用法：
/// ```dart
/// final result = await timeout(
///   () => supabase.from('sessions').select(),
///   const Duration(seconds: 10),
///   code: 'SUPABASE_TIMEOUT',
///   message: '服务器响应超时，请重试',
/// );
/// ```
///
/// 不是选择，是约束。每个外部调用都必须过这一层。
Future<Result<T>> timeout<T>(
  Future<T> Function() fn, {
  required Duration limit,
  String code = 'TIMEOUT',
  String message = '操作超时，请重试',
}) async {
  try {
    final result = await fn().timeout(limit);
    return Success(result);
  } on TimeoutException catch (_, stack) {
    return Failure(AppError(code: code, message: message, stackTrace: stack));
  } catch (e, stack) {
    return Failure(AppError(code: code, message: message, cause: e, stackTrace: stack));
  }
}

/// 带重试的超时调用
///
/// 适用于幂等操作（查询、上报）。写操作慎用。
Future<Result<T>> timeoutWithRetry<T>(
  Future<T> Function() fn, {
  required Duration limit,
  int maxRetries = 2,
  Duration retryDelay = const Duration(seconds: 1),
  String code = 'TIMEOUT',
  String message = '操作多次超时，请稍后重试',
}) async {
  var lastError = '';
  for (var i = 0; i <= maxRetries; i++) {
    final result = await timeout(fn, limit: limit, code: code, message: message);
    if (result.isSuccess) return result;
    lastError = result.error.message;
    if (i < maxRetries) await Future.delayed(retryDelay);
  }
  return Failure(AppError(code: code, message: '$message（已重试 $maxRetries 次）'));
}

/// 批量操作超时包装
///
/// 并发执行多个异步任务，各自有独立超时。任一失败不影响其他。
Future<List<Result<T>>> timeoutAll<T>(
  List<Future<T> Function()> fns, {
  required Duration limit,
}) async {
  final futures = fns.map((fn) => timeout(fn, limit: limit));
  return Future.wait(futures);
}

/// 默认超时常量——按调用类型分
class DefaultTimeout {
  /// Supabase 查询：读操作
  static const supabaseQuery = Duration(seconds: 10);

  /// Supabase 写入：插入/更新
  static const supabaseWrite = Duration(seconds: 15);

  /// BLE 扫描
  static const bleScan = Duration(seconds: 15);

  /// BLE 连接
  static const bleConnect = Duration(seconds: 10);

  /// GPS 定位
  static const location = Duration(seconds: 10);

  /// 文件读写
  static const fileIO = Duration(seconds: 5);

  /// 本地数据库
  static const localDB = Duration(seconds: 3);

  const DefaultTimeout._();
}
