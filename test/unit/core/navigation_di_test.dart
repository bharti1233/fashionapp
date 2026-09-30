import 'package:flutter_test/flutter_test.dart';
import 'package:t_store/core/cubits/navigation_menu_cubit/navigation_menu_cubit.dart';
import 'package:t_store/core/dependency_injection/service_locator.dart';

/// Proves the post-login route's dependencies resolve.
///
/// `buildMainNavigation()` creates `sl<NavigationMenuCubit>()` during
/// route build; if unregistered, provider creation throws a GetIt
/// StateError and release Flutter shows a blank grey screen. This test
/// verifies the registration without pumping widgets.
void main() {
  setUpAll(() async {
    await setupServiceLocator();
  });

  test('NavigationMenuCubit resolves from the service locator', () {
    expect(sl<NavigationMenuCubit>(), isA<NavigationMenuCubit>());
  });
}
