import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:t_store/core/common/view_models/app_bar_view_model.dart';
import 'package:t_store/core/common/view_models/circular_container_view_model.dart';
import 'package:t_store/core/common/view_models/success_view_model.dart';
import 'package:t_store/core/common/widgets/app_bar.dart';
import 'package:t_store/core/common/widgets/circular_container.dart';
import 'package:t_store/core/common/widgets/navigation_menu.dart';
import 'package:t_store/core/common/widgets/success_view.dart';
import 'package:t_store/core/dependency_injection/service_locator.dart';
import 'package:t_store/core/enums/status.dart';
import 'package:t_store/core/utils/constants/colors.dart';
import 'package:t_store/core/utils/constants/image_strings.dart';
import 'package:t_store/core/utils/constants/sizes.dart';
import 'package:t_store/core/utils/helpers/helper_functions.dart';
import 'package:t_store/core/utils/logging/app_log_entry.dart';
import 'package:t_store/core/utils/logging/app_logger.dart';
import 'package:t_store/features/cart/domain/entities/cart_item_entity.dart';
import 'package:t_store/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:t_store/features/cart/presentation/cubit/cart_state.dart';
import 'package:t_store/features/orders/domain/repositories/order_repository.dart';
import 'package:t_store/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:t_store/features/orders/presentation/cubit/orders_state.dart';
import 'package:t_store/features/personalization/domain/entities/address_entity.dart';
import 'package:t_store/features/personalization/presentation/cubit/addresses_cubit.dart';
import 'package:t_store/features/personalization/presentation/cubit/addresses_state.dart';
import 'package:t_store/features/personalization/presentation/views/user_addresses_view.dart';
import 'package:t_store/features/shop/domain/entities/coupon_entity.dart';
import 'package:t_store/features/shop/domain/usecases/validate_coupon_usecase.dart';
import 'package:t_store/features/shop/presentation/widgets/billing_address_section.dart';
import 'package:t_store/features/shop/presentation/widgets/billing_amount_sction.dart';
import 'package:t_store/features/shop/presentation/widgets/billing_payment_section.dart';
import 'package:t_store/features/shop/presentation/widgets/cart_items_list.dart';
import 'package:t_store/features/shop/presentation/widgets/coupon_code.dart';

/// Checkout backed by real Supabase data.
///
/// - Items, subtotal and total come from [CartCubit].
/// - Address comes from [AddressesCubit] (default or first).
/// - Coupons are validated against the live `coupons` table.
/// - Placing the order creates a real `pending` order via [OrdersCubit]
///   with Cash on Delivery. There is NO payment SDK: the confirmation
///   honestly states payment is pending — "Payment Successful" is never
///   shown without a transaction.
class CheckoutView extends StatefulWidget {
  const CheckoutView({super.key});

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  AppliedCoupon? _appliedCoupon;
  String? _couponError;
  bool _applyingCoupon = false;
  bool _placingOrder = false;

  @override
  void initState() {
    super.initState();
    context.read<CartCubit>().getCartItems();
    context.read<AddressesCubit>().getAddresses();
  }

  double get _discount => _appliedCoupon?.discountAmount ?? 0;

  Future<void> _applyCoupon(String code, double subtotal) async {
    if (code.isEmpty) {
      setState(() => _couponError = 'Enter a coupon code first');
      return;
    }
    setState(() {
      _applyingCoupon = true;
      _couponError = null;
    });
    final result = await sl<ValidateCouponUsecase>()(
      ValidateCouponParams(code: code, subtotal: subtotal),
    );
    if (!mounted) return;
    result.fold(
      (error) {
        AppLogger.instance.warning(
          message: 'Coupon validation failed: $error',
          category: LogCategory.products,
          event: 'COUPON_VALIDATION_FAILURE',
          screen: 'CheckoutView',
          operation: 'applyCoupon',
        );
        setState(() {
          _applyingCoupon = false;
          _appliedCoupon = null;
          _couponError = error;
        });
      },
      (applied) {
        AppLogger.instance.info(
          message: 'Coupon ${applied.coupon.code} applied',
          category: LogCategory.products,
          event: 'COUPON_APPLIED',
          screen: 'CheckoutView',
          operation: 'applyCoupon',
        );
        setState(() {
          _applyingCoupon = false;
          _appliedCoupon = applied;
          _couponError = null;
        });
      },
    );
  }

  void _placeOrder(List<CartItemEntity> items, AddressEntity address) {
    final subtotal = items.fold<double>(
      0,
      (sum, item) => sum + item.totalPrice,
    );
    final total = subtotal - _discount;
    setState(() => _placingOrder = true);
    AppLogger.instance.info(
      message: 'Order placement started (${items.length} items)',
      category: LogCategory.orders,
      event: 'ORDER_PLACEMENT_START',
      screen: 'CheckoutView',
      operation: 'placeOrder',
    );
    context.read<OrdersCubit>().createOrder(
      addressId: address.id,
      items: items
          .map(
            (item) => CreateOrderItemParams(
              productId: item.productId,
              productName: item.product?.name ?? 'Product',
              productImage: item.product?.images.isNotEmpty == true
                  ? item.product!.images.first
                  : item.product?.thumbnail,
              price: item.product?.effectivePrice ?? 0,
              quantity: item.quantity,
              selectedAttributes: item.selectedAttributes,
            ),
          )
          .toList(),
      paymentMethod: BillingPaymentSection.cashOnDelivery,
      couponCode: _appliedCoupon?.coupon.code,
      discount: _discount,
    );
  }

  void _onOrdersState(BuildContext context, OrdersState state) {
    if (state is OrderCreated) {
      AppLogger.instance.info(
        message: 'Order placed: ${state.order.id}',
        category: LogCategory.orders,
        event: 'ORDER_PLACEMENT_SUCCESS',
        screen: 'CheckoutView',
        operation: 'placeOrder',
      );
      context.read<CartCubit>().clearCart();
      if (!mounted) return;
      setState(() => _placingOrder = false);
      THelperFunctions.navigateReplacementToScreen(
        context,
        SuccessView(
          successModel: SuccessModel(
            onPressed: () {
              THelperFunctions.navigateReplacementToScreen(
                context,
                const NavigationMenu(),
              );
            },
            image: TImages.successfulPaymentIcon,
            buttonText: 'Done',
            subTitle:
                'Order #${_shortId(state.order.id)} is confirmed and will '
                'be shipped soon. Payment: Cash on Delivery — '
                'online payment is not integrated yet.',
            title: 'Order Placed Successfully',
          ),
        ),
      );
    } else if (state is OrdersError) {
      if (!mounted) return;
      setState(() => _placingOrder = false);
      THelperFunctions.showSnackBar(
        context: context,
        message: state.message,
        type: SnackBarType.error,
      );
    }
  }

  String _shortId(String id) => id.length > 8 ? id.substring(0, 8) : id;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return BlocListener<OrdersCubit, OrdersState>(
      listener: _onOrdersState,
      child: Scaffold(
        appBar: CustomAppBar(
          appBarModel: AppBarModel(
            hasArrowBack: true,
            title: Text(
              'Order Review',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ),
        body: SafeArea(
          child: BlocBuilder<CartCubit, CartState>(
            builder: (context, cartState) {
              final items = cartState is CartLoaded
                  ? cartState.items
                  : const <CartItemEntity>[];
              final subtotal = cartState is CartLoaded
                  ? cartState.totalPrice
                  : 0.0;
              final total = subtotal - _discount;
              final canOrder =
                  items.isNotEmpty && cartState is CartLoaded && !_placingOrder;
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(TSizes.defaultSpace),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (cartState is CartLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (items.isEmpty)
                        const Text(
                          'Your cart is empty.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        )
                      else
                        CartItemsList(items: items),
                      const SizedBox(height: TSizes.spaceBtwSections),
                      CouponCode(
                        appliedCode: _appliedCoupon?.coupon.code,
                        errorText: _couponError,
                        applying: _applyingCoupon,
                        onApply: (code) => _applyCoupon(code, subtotal),
                        onRemove: () => setState(() {
                          _appliedCoupon = null;
                          _couponError = null;
                        }),
                      ),
                      const SizedBox(height: TSizes.spaceBtwSections),
                      CircularContainer(
                        circularContainerModel: CircularContainerModel(
                          showBorder: true,
                          padding: const EdgeInsets.all(TSizes.md),
                          color: dark ? TColors.black : TColors.white,
                          child: Column(
                            children: [
                              BillingAmountSection(
                                subtotal: subtotal,
                                discount: _discount,
                                total: total,
                              ),
                              const SizedBox(height: TSizes.spaceBtwItems),
                              const Divider(),
                              const SizedBox(height: TSizes.spaceBtwItems),
                              const BillingPaymentSection(),
                              const SizedBox(height: TSizes.spaceBtwItems),
                              const Divider(),
                              const SizedBox(height: TSizes.spaceBtwItems),
                              BlocBuilder<AddressesCubit, AddressesState>(
                                builder: (context, addressState) {
                                  final address =
                                      addressState is AddressesLoaded
                                      ? _defaultOrFirst(addressState.addresses)
                                      : null;
                                  return BillingAddressSection(
                                    address: address,
                                    onChange: () {
                                      THelperFunctions.navigateToScreen(
                                        context,
                                        const UserAddressesView(),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: TSizes.spaceBtwSections),
                      BlocBuilder<AddressesCubit, AddressesState>(
                        builder: (context, addressState) {
                          final address = addressState is AddressesLoaded
                              ? _defaultOrFirst(addressState.addresses)
                              : null;
                          final ready =
                              canOrder && address != null && !_placingOrder;
                          return ElevatedButton(
                            onPressed: ready
                                ? () => _placeOrder(items, address!)
                                : null,
                            child: _placingOrder
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    address == null
                                        ? 'Add a delivery address first'
                                        : 'Place Order ₹${total.toStringAsFixed(2)}',
                                  ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  AddressEntity? _defaultOrFirst(List<AddressEntity> addresses) {
    if (addresses.isEmpty) return null;
    for (final address in addresses) {
      if (address.isDefault) return address;
    }
    return addresses.first;
  }
}
