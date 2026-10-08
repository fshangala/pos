import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvService {
  static String? get supabaseUrl => _read('SUPABASE_URL');

  static String? get supabaseAnonKey => _read('SUPABASE_ANON_KEY');

  static bool get isSupabaseConfigured =>
      supabaseUrl != null && supabaseAnonKey != null;

  static String? get configurationError {
    if (supabaseUrl == null) return 'SUPABASE_URL is missing or invalid.';
    if (supabaseAnonKey == null) {
      return 'SUPABASE_ANON_KEY is missing.';
    }
    return null;
  }

  static String? _read(String name) {
    final value = dotenv.env[name]?.trim();
    if (value == null || value.isEmpty) return null;
    if (name == 'SUPABASE_URL') {
      final uri = Uri.tryParse(value);
      if (uri == null || !uri.hasAuthority || !uri.hasScheme) return null;
      if (uri.scheme != 'https' && uri.scheme != 'http') return null;
    }
    return value;
  }
}
