import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Build-time/runtime config loaded from `.env` (gitignored; see
/// `.env.example`). See docs/supabase-migration-plan.md.
class Env {
  static Future<void> load() => dotenv.load(fileName: '.env');

  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';

  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  /// Feature flag: route auth/queue through Supabase instead of the local
  /// drift-only path. Defaults to false until Phase 2/3 are validated.
  static bool get useSupabase =>
      (dotenv.env['USE_SUPABASE'] ?? 'false').toLowerCase() == 'true';
}
