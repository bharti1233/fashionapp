import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:t_store/core/utils/logging/app_logger.dart';
import 'package:t_store/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:t_store/core/supabase/supabase_service.dart';

class MockSupabaseService extends Mock implements SupabaseService {}

/// Regression test for the device-observed Google OAuth failure:
///
/// Supabase HTTP 400 `validation_failed` /
/// "unsupported provider: provider is not enabled".
///
/// Contract: the technical error is logged with full detail, while the
/// user receives an honest "not available yet" message — never a fake
/// success and never a silent navigation.
void main() {
  late MockSupabaseService mockService;
  late AuthRepositoryImpl repository;

  setUp(() {
    mockService = MockSupabaseService();
    repository = AuthRepositoryImpl(supabaseService: mockService);
  });

  test(
    'disabled provider logs technical error, returns honest message',
    () async {
      const technical = AuthException(
        'unsupported provider: provider is not enabled',
        statusCode: '400',
        code: 'validation_failed',
      );
      when(() => mockService.signInWithGoogle()).thenThrow(technical);

      final result = await repository.signInWithGoogle();

      expect(result.isLeft(), isTrue);
      result.fold(
        (message) {
          expect(message, contains('not available yet'));
          expect(message, isNot(contains('validation_failed')));
        },
        (_) => fail('expected Left'),
      );

      final logged = AppLogger.instance.searchLogs(
        'GOOGLE_SIGN_IN_FAILURE',
      );
      expect(logged, isNotEmpty);
      expect(logged.last.errorType, 'AuthException');
    },
  );
}
