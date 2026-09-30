import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:t_store/core/common/view_models/circular_icon_view_model.dart';
import 'package:t_store/core/common/widgets/circular_icon.dart';
import 'package:t_store/core/enums/status.dart';
import 'package:t_store/core/utils/constants/colors.dart';
import 'package:t_store/core/utils/constants/sizes.dart';
import 'package:t_store/core/utils/helpers/helper_functions.dart';
import 'package:t_store/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:t_store/features/cart/presentation/cubit/cart_state.dart';
import 'package:t_store/features/shop/domain/entities/product_entity.dart';

/// Quantity selector + Add To Cart wired to [CartCubit] for [product].
/// Out-of-stock products cannot be added. Selectable variant attributes
/// travel into the cart item.
class BottomAddToCart extends StatefulWidget {
  final ProductEntity product;
  final Map<String, dynamic> selectedAttributes;

  const BottomAddToCart({
    super.key,
    required this.product,
    this.selectedAttributes = const {},
  });

  @override
  State<BottomAddToCart> createState() => _BottomAddToCartState();
}

class _BottomAddToCartState extends State<BottomAddToCart> {
  int _quantity = 1;

  void _addToCart() {
    context.read<CartCubit>().addToCart(
      productId: widget.product.id,
      quantity: _quantity,
      selectedAttributes: widget.selectedAttributes.isEmpty
          ? null
          : Map.of(widget.selectedAttributes),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final inStock = widget.product.stock > 0;
    return BlocListener<CartCubit, CartState>(
      listener: (context, state) {
        if (state is CartItemAdded) {
          THelperFunctions.showSnackBar(
            context: context,
            message: 'Added to cart',
            type: SnackBarType.success,
          );
        } else if (state is CartError) {
          THelperFunctions.showSnackBar(
            context: context,
            message: state.message,
            type: SnackBarType.error,
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        decoration: BoxDecoration(
          color: dark ? TColors.darkGrey : TColors.light,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(TSizes.cardRadiusLg),
            topRight: Radius.circular(TSizes.cardRadiusLg),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircularIcon(
                  circularIconModel: CircularIconModel(
                    icon: Iconsax.minus,
                    height: 40,
                    width: 40,
                    color: TColors.white,
                    backgroundColor: TColors.darkerGrey,
                    onPressed: () {
                      if (_quantity > 1) setState(() => _quantity--);
                    },
                  ),
                ),
                const SizedBox(width: TSizes.spaceBtwItems),
                Text(
                  '$_quantity',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(width: TSizes.spaceBtwItems),
                CircularIcon(
                  circularIconModel: CircularIconModel(
                    icon: Iconsax.add,
                    height: 40,
                    width: 40,
                    color: TColors.white,
                    backgroundColor: TColors.black,
                    onPressed: () {
                      if (_quantity < widget.product.stock) {
                        setState(() => _quantity++);
                      }
                    },
                  ),
                ),
                const SizedBox(width: TSizes.spaceBtwItems),
              ],
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(TSizes.md),
                backgroundColor: TColors.primary,
                side: const BorderSide(color: TColors.primary),
              ),
              onPressed: inStock ? _addToCart : null,
              child: Text(inStock ? 'Add To Cart' : 'Out of Stock'),
            ),
          ],
        ),
      ),
    );
  }
}
