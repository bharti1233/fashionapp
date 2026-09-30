import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:t_store/core/common/view_models/app_bar_view_model.dart';
import 'package:t_store/core/common/widgets/app_bar.dart';
import 'package:t_store/core/utils/constants/sizes.dart';
import 'package:t_store/core/utils/helpers/helper_functions.dart';
import 'package:t_store/core/utils/logging/app_log_entry.dart';
import 'package:t_store/core/utils/logging/app_logger.dart';
import 'package:t_store/features/cart/domain/entities/cart_item_entity.dart';
import 'package:t_store/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:t_store/features/cart/presentation/cubit/cart_state.dart';
import 'package:t_store/features/shop/presentation/views/checkout_view.dart';
import 'package:t_store/features/shop/presentation/widgets/cart_items_list.dart';
import 'package:t_store/core/utils/formatters/formatter.dart';

/// Cart screen backed by Supabase through [CartCubit].
///
/// Shows loading, sign-in-required, empty, loaded (real subtotal/total),
/// and error (with retry) states. The checkout button carries the real
/// total and is only enabled for a non-empty cart.
class CartView extends StatefulWidget {
  const CartView({super.key});

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    AppLogger.instance.info(
      message: 'Cart loading started',
      category: LogCategory.cart,
      event: 'CART_LOAD_START',
      screen: 'CartView',
      operation: 'loadCart',
    );
    context.read<CartCubit>().getCartItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        appBarModel: AppBarModel(
          title: Text('Cart', style: Theme.of(context).textTheme.headlineSmall),
          hasArrowBack: true,
        ),
      ),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          if (state is CartLoading || state is CartInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CartError) {
            return _CartMessage(
              icon: Icons.shopping_cart_outlined,
              message: state.message,
              actionLabel: 'RETRY',
              onAction: _load,
            );
          }
          final items = state is CartLoaded
              ? state.items
              : const <CartItemEntity>[];
          if (items.isEmpty) {
            return const _CartMessage(
              icon: Icons.shopping_cart_outlined,
              message: 'Your cart is empty.',
            );
          }
          final total = (state as CartLoaded).totalPrice;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CartItemsList(items: items),
                  const SizedBox(height: TSizes.spaceBtwSections),
                  Text(
                    'Subtotal (${state.itemCount} items): '
                    TFormatter.formatPrice(total),
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  ElevatedButton(
                    onPressed: () {
                      THelperFunctions.navigateToScreen(
                        context,
                        const CheckoutView(),
                      );
                    },
                    child: Text('Checkout ${TFormatter.formatPrice(total)}'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CartMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _CartMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
