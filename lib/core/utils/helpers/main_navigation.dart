import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:t_store/core/common/widgets/navigation_menu.dart';
import 'package:t_store/core/cubits/navigation_menu_cubit/navigation_menu_cubit.dart';
import 'package:t_store/core/dependency_injection/service_locator.dart';
import 'package:t_store/features/shop/presentation/cubit/products_cubit.dart';

/// Builds the authenticated main navigation with the cubits it needs.
///
/// Used after login, signup verification, and session restoration so all
/// three entries construct the identical provider tree.
Widget buildMainNavigation() {
  return MultiBlocProvider(
    providers: [
      BlocProvider(create: (context) => sl<NavigationMenuCubit>()),
      BlocProvider.value(
        value: sl<ProductsCubit>()
          ..getProducts(sortBy: 'rating', ascending: false, refresh: true),
      ),
    ],
    child: const NavigationMenu(),
  );
}
