import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:t_store/core/common/widgets/navigation_menu.dart';
import 'package:t_store/core/cubits/banner_carousel_slider_cubit_cubit/banner_carousel_slider_cubit.dart';
import 'package:t_store/core/dependency_injection/service_locator.dart';
import 'package:t_store/core/usecases/usecase.dart';
import 'package:t_store/core/utils/helpers/main_navigation.dart';
import 'package:t_store/features/cart/domain/usecases/add_to_cart_usecase.dart';
import 'package:t_store/features/cart/domain/usecases/clear_cart_usecase.dart';
import 'package:t_store/features/cart/domain/usecases/get_cart_items_usecase.dart';
import 'package:t_store/features/cart/domain/usecases/remove_from_cart_usecase.dart';
import 'package:t_store/features/cart/domain/usecases/update_cart_item_usecase.dart';
import 'package:t_store/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:t_store/features/shop/domain/usecases/get_banners_usecase.dart';
import 'package:t_store/features/shop/domain/usecases/get_categories_usecase.dart';
import 'package:t_store/features/shop/domain/usecases/get_product_by_id_usecase.dart';
import 'package:t_store/features/shop/domain/usecases/get_products_usecase.dart';
import 'package:t_store/features/shop/domain/usecases/search_products_usecase.dart';
import 'package:t_store/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:t_store/features/auth/presentation/cubit/auth_state.dart';
import 'package:t_store/features/shop/presentation/cubit/banners_cubit.dart';
import 'package:t_store/features/shop/presentation/cubit/categories_cubit.dart';
import 'package:t_store/features/shop/presentation/cubit/products_cubit.dart';
import 'package:t_store/features/wishlist/domain/usecases/add_to_wishlist_usecase.dart';
import 'package:t_store/features/wishlist/domain/usecases/get_wishlist_usecase.dart';
import 'package:t_store/features/wishlist/domain/usecases/remove_from_wishlist_usecase.dart';
import 'package:t_store/features/wishlist/presentation/cubit/wishlist_cubit.dart';

class MockGetProductsUsecase extends Mock implements GetProductsUsecase {}

class MockGetProductByIdUsecase extends Mock implements GetProductByIdUsecase {}

class MockSearchProductsUsecase extends Mock implements SearchProductsUsecase {}

class MockGetCategoriesUsecase extends Mock implements GetCategoriesUsecase {}

class MockGetBannersUsecase extends Mock implements GetBannersUsecase {}

class MockGetWishlistUsecase extends Mock implements GetWishlistUsecase {}

class MockAddToWishlistUsecase extends Mock implements AddToWishlistUsecase {}

class MockRemoveFromWishlistUsecase extends Mock
    implements RemoveFromWishlistUsecase {}

class MockGetCartItemsUsecase extends Mock implements GetCartItemsUsecase {}

class MockAddToCartUsecase extends Mock implements AddToCartUsecase {}

class MockUpdateCartItemUsecase extends Mock implements UpdateCartItemUsecase {}

class MockRemoveFromCartUsecase extends Mock implements RemoveFromCartUsecase {}

class MockClearCartUsecase extends Mock implements ClearCartUsecase {}

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class FakeGetProductsParams extends Fake implements GetProductsParams {}

class FakeNoParams extends Fake implements NoParams {}

/// Regression test for the device-observed blank grey screen after
/// email/password login.
///
/// Root cause: `buildMainNavigation()` (the post-login route) resolved
/// `sl<NavigationMenuCubit>()`, which was never registered in
/// `setupServiceLocator()`. Provider creation threw a GetIt StateError
/// during route build; release Flutter renders that as a blank grey
/// screen with no error message.
///
/// The test mirrors production: global providers above, post-login
/// route below. Backend calls resolve to empty lists.
void main() {
  setUpAll(() async {
    await setupServiceLocator();
    registerFallbackValue(FakeGetProductsParams());
    registerFallbackValue(FakeNoParams());
  });

  Widget frame() {
    final productsCubit = ProductsCubit(
      getProductsUsecase: MockGetProductsUsecase(),
      getProductByIdUsecase: MockGetProductByIdUsecase(),
      searchProductsUsecase: MockSearchProductsUsecase(),
    );
    final categoriesCubit = CategoriesCubit(
      getCategoriesUsecase: MockGetCategoriesUsecase(),
    );
    final bannersCubit = BannersCubit(
      getBannersUsecase: MockGetBannersUsecase(),
    );
    final wishlistCubit = WishlistCubit(
      getWishlistUsecase: MockGetWishlistUsecase(),
      addToWishlistUsecase: MockAddToWishlistUsecase(),
      removeFromWishlistUsecase: MockRemoveFromWishlistUsecase(),
    );
    final cartCubit = CartCubit(
      getCartItemsUsecase: MockGetCartItemsUsecase(),
      addToCartUsecase: MockAddToCartUsecase(),
      updateCartItemUsecase: MockUpdateCartItemUsecase(),
      removeFromCartUsecase: MockRemoveFromCartUsecase(),
      clearCartUsecase: MockClearCartUsecase(),
    );
    when(
      () => productsCubit.getProductsUsecase(any()),
    ).thenAnswer((_) async => const Right([]));
    when(
      () => categoriesCubit.getCategoriesUsecase(any()),
    ).thenAnswer((_) async => const Right([]));
    when(
      () => bannersCubit.getBannersUsecase(any()),
    ).thenAnswer((_) async => const Right([]));
    final authCubit = MockAuthCubit();
    when(() => authCubit.state).thenReturn(AuthUnauthenticated());
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: productsCubit),
          BlocProvider.value(value: categoriesCubit),
          BlocProvider.value(value: bannersCubit),
          BlocProvider.value(value: wishlistCubit),
          BlocProvider.value(value: cartCubit),
          BlocProvider<AuthCubit>.value(value: authCubit),
          BlocProvider(create: (_) => BannerCarouselSliderCubit()),
        ],
        child: Builder(builder: (context) => buildMainNavigation()),
      ),
    );
  }

  testWidgets('post-login route builds without errors', (tester) async {
    await tester.pumpWidget(frame());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(NavigationMenu), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
