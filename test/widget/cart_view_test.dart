import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:t_store/core/usecases/usecase.dart';
import 'package:t_store/features/cart/domain/entities/cart_item_entity.dart';
import 'package:t_store/features/cart/domain/usecases/add_to_cart_usecase.dart';
import 'package:t_store/features/cart/domain/usecases/clear_cart_usecase.dart';
import 'package:t_store/features/cart/domain/usecases/get_cart_items_usecase.dart';
import 'package:t_store/features/cart/domain/usecases/remove_from_cart_usecase.dart';
import 'package:t_store/features/cart/domain/usecases/update_cart_item_usecase.dart';
import 'package:t_store/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:t_store/features/shop/domain/entities/product_entity.dart';
import 'package:t_store/features/shop/presentation/views/cart_view.dart';

class MockGetCartItemsUsecase extends Mock implements GetCartItemsUsecase {}

class MockAddToCartUsecase extends Mock implements AddToCartUsecase {}

class MockUpdateCartItemUsecase extends Mock implements UpdateCartItemUsecase {}

class MockRemoveFromCartUsecase extends Mock implements RemoveFromCartUsecase {}

class MockClearCartUsecase extends Mock implements ClearCartUsecase {}

class FakeNoParams extends Fake implements NoParams {}

/// Proves CartView renders REAL cart rows with computed totals —
/// never the static item or hardcoded 175.
void main() {
  setUpAll(() {
    registerFallbackValue(FakeNoParams());
  });

  CartItemEntity item() {
    return const CartItemEntity(
      id: 'ci-1',
      userId: 'u1',
      productId: 'p-real-9',
      quantity: 2,
      product: ProductEntity(
        id: 'p-real-9',
        name: 'Metro Slim Chinos',
        price: 59.99,
        categoryId: 'c1',
        stock: 4,
        images: ['https://example.invalid/chinos.png'],
      ),
    );
  }

  CartCubit cubitWith(List<CartItemEntity> items) {
    final mockGet = MockGetCartItemsUsecase();
    when(() => mockGet(any())).thenAnswer((_) async => Right(items));
    return CartCubit(
      getCartItemsUsecase: mockGet,
      addToCartUsecase: MockAddToCartUsecase(),
      updateCartItemUsecase: MockUpdateCartItemUsecase(),
      removeFromCartUsecase: MockRemoveFromCartUsecase(),
      clearCartUsecase: MockClearCartUsecase(),
    );
  }

  testWidgets('renders real lines with computed total', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubitWith([item()]),
          child: const CartView(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.text('Metro Slim Chinos'), findsOneWidget);
    // 2 × 59.99 = 119.98 real arithmetic, not a constant.
    expect(find.textContaining('119.98'), findsWidgets);
    expect(find.textContaining('175'), findsNothing);
  });

  testWidgets('empty cart shows honest empty state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: cubitWith([]), child: const CartView()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.text('Your cart is empty.'), findsOneWidget);
  });
}
