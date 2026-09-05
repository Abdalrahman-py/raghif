import 'package:drift/drift.dart';

/// Unreachable in practice: [main] always calls `initDependencies()` before
/// building a [QueueController], so this no-DI fallback never fires on web.
/// It exists only to give the native/`dart:ffi` fallback a web-safe stand-in
/// so the app still compiles for web.
QueryExecutor inMemoryExecutor() => throw UnsupportedError(
      'No no-DI fallback database on web; initDependencies() must run first.',
    );
