/// Public client configuration for CHMSU Library Supabase backend.
/// Access is enforced by Supabase Row Level Security (RLS);
/// never embed a service-role key in the mobile app.
abstract final class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ayjvgmbwhanikoqfkrym.supabase.co',
  );
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_t0m2Uv5Zq7M6R7SGJve47w_8MmLt0p6',
  );

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}
