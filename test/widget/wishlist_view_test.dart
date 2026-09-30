import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:t_store/core/cubits/navigation_menu_cubit/navigation_menu_cubit.dart';
import 'package:t_store/core/usecases/usecase.dart';
import 'package:t_store/features/shop/domain/entities/product_entity.dart';
import 'package:t_store/features/shop/presentation/views/wishlist_view.dart';
import 'package:t_store/features/wishlist/domain/entities/wishlist_item_entity.dart';
import 'package:t_store/features/wishlist/domain/usecases/add_to_wishlist_usecase.dart';
import 'package:t_store/features/wishlist/domain/usecases/get_wishlist_usecase.dart';
import 'package:t_store/features/wishlist/domain/usecases/remove_from_wishlist_usecase.dart';
import 'package:t_store/features/wishlist/presentation/cubit/wishlist_cubit.dart';

class MockGetWishlistUsecase extends Mock implements GetWishlistUsecase {}

class MockAddToWishlistUsecase extends Mock implements AddToWishlistUsecase {}

class MockRemoveFromWishlistUsecase extends Mock
    implements RemoveFromWishlistUsecase {}

class FakeNoParams extends Fake implements NoParams {}

/// Proves WishlistView renders REAL repository rows — never fabricated
/// "Product $index" cards — plus the honest empty state.
void main() {
  setUpAll(() {
    registerFallbackValue(FakeNoParams());
  });

  ProductEntity product() {
    return const ProductEntity(
      id: 'p-real-1',
      name: 'Harbor Oxford Shirt',
      price: 49.99,
      categoryId: 'c1',
      stock: 7,
      images: ['https://example.invalid/shirt.png'],
    );
  }

  WishlistCubit cubitWith(List<WishlistItemEntity> items) {
    final mockGet = MockGetWishlistUsecase();
    when(() => mockGet(any())).thenAnswer((_) async => Right(items));
    return WishlistCubit(
      getWishlistUsecase: mockGet,
      addToWishlistUsecase: MockAddToWishlistUsecase(),
      removeFromWishlistUsecase: MockRemoveFromWishlistUsecase(),
    );
  }

  Widget frame(WishlistCubit cubit) {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => NavigationMenuCubit()),
          BlocProvider.value(value: cubit),
        ],
        child: const WishlistView(),
      ),
    );
  }

  testWidgets('renders real product rows from the repository', (tester) async {
    await tester.pumpWidget(
      frame(
        cubitWith([
          WishlistItemEntity(
            id: 'w1',
            userId: 'u1',
            productId: 'p-real-1',
            product: product(),
          ),
        ]),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.text('Harbor Oxford Shirt'), findsOneWidget);
    expect(find.textContaining('Product 0'), findsNothing);
    expect(find.textContaining('picsum'), findsNothing);
  });

  testWidgets('empty wishlist shows honest empty state', (tester) async {
    await tester.pumpWidget(frame(cubitWith([])));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.textContaining('wishlist is empty'), findsOneWidget);
  });

  testWidgets('repository failure shows retryable error', (tester) async {
    final mockGet = MockGetWishlistUsecase();
    when(
      () => mockGet(any()),
    ).thenAnswer((_) async => const Left('Network down'));
    final cubit = WishlistCubit(
      getWishlistUsecase: mockGet,
      addToWishlistUsecase: MockAddToWishlistUsecase(),
      removeFromWishlistUsecase: MockRemoveFromWishlistUsecase(),
    );
    await tester.pumpWidget(frame(cubit));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.text('Network down'), findsOneWidget);
    expect(find.text('RETRY'), findsOneWidget);
  });
}
