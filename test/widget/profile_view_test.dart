import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:t_store/features/auth/domain/entities/user_entity.dart';
import 'package:t_store/features/personalization/presentation/cubit/profile_cubit.dart';
import 'package:t_store/features/personalization/presentation/cubit/profile_state.dart';
import 'package:t_store/features/personalization/presentation/views/profile_view.dart';

class MockProfileCubit extends MockCubit<ProfileState>
    implements ProfileCubit {}

/// Proves the Profile screen renders the AUTHENTICATED user's identity —
/// never hardcoded constants — and reloads it on open (no cross-user
/// leakage after logout/login).
void main() {
  late MockProfileCubit mockCubit;

  const realUser = UserEntity(
    id: 'user-real-1',
    email: 'priya@example.in',
    fullName: 'Priya Sharma',
    phone: '+919876543210',
  );

  setUp(() {
    mockCubit = MockProfileCubit();
    when(() => mockCubit.getProfile()).thenAnswer((_) async {});
  });

  Widget frame() {
    return MaterialApp(
      home: BlocProvider<ProfileCubit>.value(
        value: mockCubit,
        child: const ProfileView(),
      ),
    );
  }

  testWidgets('shows real user identity, no hardcoded constants', (
    tester,
  ) async {
    when(() => mockCubit.state).thenReturn(ProfileLoaded(realUser));

    await tester.pumpWidget(frame());
    await tester.pump();

    expect(find.text('Priya Sharma'), findsWidgets);
    expect(find.text('priya@example.in'), findsOneWidget);
    expect(find.text('+919876543210'), findsOneWidget);
    expect(find.text('John Doe'), findsNothing);
    expect(find.text('Elashwah Hamdi'), findsNothing);
    expect(find.text('hmdy7486@gmail.com'), findsNothing);
    expect(find.text('21-02064'), findsNothing);
  });

  testWidgets('reloads profile on open', (tester) async {
    when(() => mockCubit.state).thenReturn(ProfileLoaded(realUser));

    await tester.pumpWidget(frame());
    await tester.pump();

    verify(() => mockCubit.getProfile()).called(1);
  });

  testWidgets('shows loading state while fetching', (tester) async {
    when(() => mockCubit.state).thenReturn(ProfileInitial());

    await tester.pumpWidget(frame());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
