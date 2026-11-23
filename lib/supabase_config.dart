/// Public client configuration for CHMSU Library Supabase backend.
/// Access is enforced by Supabase Row Level Security (RLS);
/// never embed a service-role key in the mobile app.
abstract final class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}
