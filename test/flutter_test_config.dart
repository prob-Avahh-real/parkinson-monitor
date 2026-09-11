import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

/// Runs before every test file. google_fonts fetches fonts over the network by
/// default, which throws on CI (no egress to fonts.gstatic.com) and makes
/// widget/golden rendering non-deterministic. The app sets the same flag in
/// main(), so tests should behave the same way.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
