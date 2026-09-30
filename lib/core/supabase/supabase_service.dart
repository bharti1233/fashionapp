import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:t_store/core/supabase/supabase_config.dart';
import 'package:t_store/core/utils/logging/app_log_entry.dart';
import 'package:t_store/core/utils/logging/operation_logger.dart';

/// Supabase Service - Singleton class for Supabase operations
class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseClient? _client;

  SupabaseService._();

  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  /// Initialize Supabase - Call this in main()
  static Future<void> initialize() async {
    // Prevent double initialization
    if (_client != null) return;

    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
        realtimeClientOptions: const RealtimeClientOptions(
          logLevel: RealtimeLogLevel.info,
        ),
      );
      _client = Supabase.instance.client;
    } on StateError catch (e) {
      // Re-throw configuration errors with context
      throw StateError('Supabase configuration error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to initialize Supabase: $e');
    }
  }

  /// Get Supabase Client
  SupabaseClient get client {
    if (_client == null) {
      throw Exception(
        'Supabase not initialized. Call SupabaseService.initialize() first.',
      );
    }
    return _client!;
  }

  /// Get current user
  User? get currentUser => client.auth.currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  /// Get current session
  Session? get currentSession => client.auth.currentSession;

  /// Auth state changes stream
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  // ============== AUTH METHODS ==============

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) {
    return logSupabaseOperation<AuthResponse>(
      category: LogCategory.authentication,
      operation: 'supabaseSignUp',
      screen: 'SupabaseService',
      startEvent: 'SUPABASE_SIGN_UP_START',
      successEvent: 'SUPABASE_SIGN_UP_SUCCESS',
      failureEvent: 'SUPABASE_SIGN_UP_FAILURE',
      action: () =>
          client.auth.signUp(email: email, password: password, data: data),
    );
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return logSupabaseOperation<AuthResponse>(
      category: LogCategory.authentication,
      operation: 'supabaseSignIn',
      screen: 'SupabaseService',
      startEvent: 'SUPABASE_SIGN_IN_START',
      successEvent: 'SUPABASE_SIGN_IN_SUCCESS',
      failureEvent: 'SUPABASE_SIGN_IN_FAILURE',
      action: () =>
          client.auth.signInWithPassword(email: email, password: password),
    );
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() {
    return logSupabaseOperation<bool>(
      category: LogCategory.authentication,
      operation: 'supabaseGoogleSignIn',
      screen: 'SupabaseService',
      action: () => client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.tstore://login-callback/',
      ),
    );
  }

  /// Sign in with Facebook
  Future<bool> signInWithFacebook() {
    return logSupabaseOperation<bool>(
      category: LogCategory.authentication,
      operation: 'supabaseFacebookSignIn',
      screen: 'SupabaseService',
      action: () => client.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: 'io.supabase.tstore://login-callback/',
      ),
    );
  }

  /// Sign in with Apple
  Future<bool> signInWithApple() {
    return logSupabaseOperation<bool>(
      category: LogCategory.authentication,
      operation: 'supabaseAppleSignIn',
      screen: 'SupabaseService',
      action: () => client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'io.supabase.tstore://login-callback/',
      ),
    );
  }

  /// Sign out
  Future<void> signOut() {
    return logSupabaseOperation<void>(
      category: LogCategory.authentication,
      operation: 'supabaseSignOut',
      screen: 'SupabaseService',
      action: () => client.auth.signOut(),
    );
  }

  /// Reset password
  Future<void> resetPassword(String email) {
    return logSupabaseOperation<void>(
      category: LogCategory.authentication,
      operation: 'supabaseResetPassword',
      screen: 'SupabaseService',
      action: () => client.auth.resetPasswordForEmail(email),
    );
  }

  /// Update password
  Future<UserResponse> updatePassword(String newPassword) {
    return logSupabaseOperation<UserResponse>(
      category: LogCategory.authentication,
      operation: 'supabaseUpdatePassword',
      screen: 'SupabaseService',
      action: () =>
          client.auth.updateUser(UserAttributes(password: newPassword)),
    );
  }

  /// Update user data
  Future<UserResponse> updateUser({
    String? email,
    String? password,
    Map<String, dynamic>? data,
  }) {
    return logSupabaseOperation<UserResponse>(
      category: LogCategory.authentication,
      operation: 'supabaseUpdateUser',
      screen: 'SupabaseService',
      action: () => client.auth.updateUser(
        UserAttributes(email: email, password: password, data: data),
      ),
    );
  }

  /// Resend confirmation email
  Future<ResendResponse> resendConfirmation(String email) {
    return logSupabaseOperation<ResendResponse>(
      category: LogCategory.authentication,
      operation: 'supabaseResendConfirmation',
      screen: 'SupabaseService',
      action: () => client.auth.resend(type: OtpType.signup, email: email),
    );
  }

  // ============== DATABASE METHODS ==============

  /// Get data from table
  Future<List<Map<String, dynamic>>> getAll(
    String table, {
    String? select,
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = true,
    int? limit,
    int? offset,
  }) {
    return logSupabaseOperation<List<Map<String, dynamic>>>(
      category: LogCategory.database,
      operation: 'supabaseGetAll',
      screen: 'SupabaseService',
      action: () async {
        var query = client.from(table).select(select ?? '*');

        if (filters != null) {
          filters.forEach((key, value) {
            query = query.eq(key, value);
          });
        }

        // Chain the transformations
        dynamic result = query;

        if (orderBy != null) {
          result = result.order(orderBy, ascending: ascending);
        }

        if (limit != null) {
          result = result.limit(limit);
        }

        if (offset != null) {
          result = result.range(offset, offset + (limit ?? 10) - 1);
        }

        final response = await result;
        return List<Map<String, dynamic>>.from(response);
      },
    );
  }

  /// Get single record by ID
  Future<Map<String, dynamic>?> getById(String table, String id) {
    return logSupabaseOperation<Map<String, dynamic>?>(
      category: LogCategory.database,
      operation: 'supabaseGetById',
      screen: 'SupabaseService',
      action: () => client.from(table).select().eq('id', id).maybeSingle(),
    );
  }

  /// Insert data
  Future<Map<String, dynamic>> insert(String table, Map<String, dynamic> data) {
    return logSupabaseOperation<Map<String, dynamic>>(
      category: LogCategory.database,
      operation: 'supabaseInsert',
      screen: 'SupabaseService',
      action: () => client.from(table).insert(data).select().single(),
    );
  }

  /// Update data
  Future<Map<String, dynamic>> update(
    String table,
    String id,
    Map<String, dynamic> data,
  ) {
    return logSupabaseOperation<Map<String, dynamic>>(
      category: LogCategory.database,
      operation: 'supabaseUpdate',
      screen: 'SupabaseService',
      action: () =>
          client.from(table).update(data).eq('id', id).select().single(),
    );
  }

  /// Upsert data (insert or update)
  Future<Map<String, dynamic>> upsert(String table, Map<String, dynamic> data) {
    return logSupabaseOperation<Map<String, dynamic>>(
      category: LogCategory.database,
      operation: 'supabaseUpsert',
      screen: 'SupabaseService',
      action: () => client.from(table).upsert(data).select().single(),
    );
  }

  /// Delete data
  Future<void> delete(String table, String id) {
    return logSupabaseOperation<void>(
      category: LogCategory.database,
      operation: 'supabaseDelete',
      screen: 'SupabaseService',
      action: () => client.from(table).delete().eq('id', id),
    );
  }

  /// Delete with filter
  Future<void> deleteWhere(String table, Map<String, dynamic> filters) {
    return logSupabaseOperation<void>(
      category: LogCategory.database,
      operation: 'supabaseDeleteWhere',
      screen: 'SupabaseService',
      action: () async {
        var query = client.from(table).delete();
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
        await query;
      },
    );
  }

  // ============== STORAGE METHODS ==============

  /// Upload file
  Future<String> uploadFile(
    String bucket,
    String path,
    List<int> fileBytes, {
    String? contentType,
  }) {
    return logSupabaseOperation<String>(
      category: LogCategory.storage,
      operation: 'supabaseUploadFile',
      screen: 'SupabaseService',
      action: () async {
        await client.storage
            .from(bucket)
            .uploadBinary(
              path,
              fileBytes as dynamic,
              fileOptions: FileOptions(contentType: contentType),
            );
        return client.storage.from(bucket).getPublicUrl(path);
      },
    );
  }

  /// Get public URL
  String getPublicUrl(String bucket, String path) {
    return client.storage.from(bucket).getPublicUrl(path);
  }

  /// Delete file
  Future<void> deleteFile(String bucket, String path) {
    return logSupabaseOperation<void>(
      category: LogCategory.storage,
      operation: 'supabaseDeleteFile',
      screen: 'SupabaseService',
      action: () => client.storage.from(bucket).remove([path]),
    );
  }

  // ============== REALTIME METHODS ==============

  /// Subscribe to table changes
  RealtimeChannel subscribeToTable(
    String table, {
    required void Function(PostgresChangePayload payload) onInsert,
    void Function(PostgresChangePayload payload)? onUpdate,
    void Function(PostgresChangePayload payload)? onDelete,
    Map<String, String>? filter,
  }) {
    final channel = client.channel('public:$table');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: table,
      filter: filter != null
          ? PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: filter.keys.first,
              value: filter.values.first,
            )
          : null,
      callback: onInsert,
    );

    if (onUpdate != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: table,
        callback: onUpdate,
      );
    }

    if (onDelete != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: table,
        callback: onDelete,
      );
    }

    channel.subscribe();
    return channel;
  }

  /// Unsubscribe from channel
  Future<void> unsubscribe(RealtimeChannel channel) {
    return logSupabaseOperation<void>(
      category: LogCategory.database,
      operation: 'supabaseUnsubscribe',
      screen: 'SupabaseService',
      action: () => client.removeChannel(channel),
    );
  }
}
