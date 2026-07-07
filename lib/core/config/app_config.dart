import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _envFile = '.env';

  static Future<void> load() async {
    await dotenv.load(fileName: _envFile);
    _validate();
  }

  /// 校验必要配置项，缺少时输出警告但不阻塞启动
  static void _validate() {
    final warnings = <String>[];

    if (supabaseUrl.isEmpty && enableCloudSync) {
      warnings.add('SUPABASE_URL 未配置，云同步已禁用 (ENABLE_CLOUD_SYNC 应为 false)');
    }

    if (sentryDsn.isEmpty && enableCrashReporting) {
      warnings.add('SENTRY_DSN 未配置，崩溃上报将无效');
    }

    if (environment.isEmpty) {
      warnings.add('ENVIRONMENT 未设置，默认为 development');
    }

    for (final warning in warnings) {
      debugPrint('[AppConfig] ⚠ $warning');
    }
  }

  // Envimport 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _meimport 'package:flutter/foundation.get isProduction =
class AppConfig {
  static const Stringaba  static const Sng
  static Future<void> load() async {'SUPA    await dotenv.load(fileName: _enet    _validate();
  }

  /// 校验必要?B  }

  /// 校??
 ';
  statiPI Configuration
  static int get apiTimeout =>
      int.tryPa    final warnings = <StriT'
    if (supabaseUrl.isEmpty tic i      warnings.add('SUPABASE_URL 未配置，云v.    }

    if (sentryDsn.isEmpty && enableCrashReporting) {
      warnings.add('SENTRY_DSN 未配? dotenv.      warnings.add('SENTRY_DSN 未配置，c bool get    }

    if (environment.isEmpty) {
      warnings.add('ENVIRONM;

   ati      warnings.add('ENVIRONMEng    }

    for (final warning in warnings) {
      debugPrint// Monit
   g C  figuration
  static String get sentr    }
  }

  // Envimport 'package:flu ?? '';
  }
at
  Stimport 'package:flutter/foundation.dart';

class AppConfig RO
class AppConfig {
  static const Stringget  static const Splclass AppConfig {
  static const Stringaba  static const Sng
  static Future<1'  static const Sic  static Future<void> load() async {'SUPA.e  }

  /// 校验必要?B  }

  /// 校??
 ';
  statiPI Configuration
  static int get apiThr
 hol
  /// 校??
 ';
  starse ';
  stati['  EEZE_INDEX_THRESHOLD'] ??       int.tryPa    final warne     if (supabaseUrl.isEmpty tic i      warPa
    if (sentryDsn.isEmpty && enableCrashReporting) {
      warnings.add('SENTRY_DSN ?en      warnings.aouble.tryParse(dotenv.env['TREMOR_FRE
    if (environment.isEmpty) {
      warnings.add('ENVIRONM;

   ati      warnings.add('ENVIRONMEng    env      warnings.add('ENVIRONM; '
   ati      warnings.add('Ee g
    for (final warning in warnings)       d      debugPrint// Monit
   g C  figSI   g C  figuration
  st ?  s0.15') ?? 0.15;
  }

  // Envimport 'package:Ca
 nce  }
at
  Stimport 'package:flutteotatv. nv
class AppConfig RO
class AppConfig {
  stat?? cla
  static double  static const SaA  static const Stringaba  static const Sng
  static Futurev[  static Future<1'  static const Sic  sta] 
  /// 校验必要?B  }

  /// 校??
 ';
  statiPI Configuration
  static int e =
  /// 校??
 ';
  staten ';
  statiOR  AM  static in] ?? '50') ?? hol
  /// 校??
 ';
de  /ti ';
  starse   
   stati[' ry    if (sentryDsn.isEmpty && enableCrashReporting) {
      warnings.add('SENTRY_DSN ?en      warnings.aouble.yP      warnv.env['CONFIRMATION_FRAMES'] ?? '3') ?? 3;
    if (environment.isEmpty) {
      warnings.add('ENVIRe(dotenv.env['DEBOUNCE_DURATION_MS      warni') ?? 3000;
}
