import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:t_store/features/personalization/presentation/cubit/profile_cubit.dart';
import 'package:t_store/features/personalization/presentation/cubit/profile_state.dart';
import 'package:t_store/features/personalization/presentation/views/settings_view.dart';

class MockProfileCubit extends MockCubit<ProfileState>
    implements ProfileCubit {}

/// Proves the removed settings are gone and the kept ones remain.
void main() {
  late MockProfileCubit mockCubit;

  setUp(() {
    mockCubit = MockProfileCubit();
    when(() => mockCubit.getProfile()).thenAnswer((_) async {});
    when(() => mockCubit.state).thenReturn(ProfileInitial());
  });

  Widget frame() {
    // SettingsView is a tab body: it expects a Scaffold ancestor (as
    // provided by NavigationMenu in production).
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<ProfileCubit>.value(
          value: mockCubit,
          child: const SettingsView(),
        ),
      ),
    );
  }

  testWidgets('removed settings are absent', (tester) async {
    await tester.pumpWidget(frame());
    await tester.pump();

    expect(find.text('Upload Data'), findsNothing);
    expect(find.text('Geolocation'), findsNothing);
    expect(find.text('Safe Mode'), findsNothing);
    expect(find.text('HD Image Quality'), findsNothing);
    expect(find.text('Bank Account'), findsNothing);
  });

  testWidgets('kept settings are present', (tester) async {
    await tester.pumpWidget(frame());
    await tester.pump();

    expect(find.text('App Logs'), findsOneWidget);
    expect(find.text('My Addresses'), findsOneWidget);
    expect(find.text('My Cart'), findsOneWidget);
    expect(find.text('My Orders'), findsOneWidget);
    expect(find.text('My Coupons'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Account Privacy'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
  });
}
