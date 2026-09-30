import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:t_store/core/common/view_models/product_price_text_view_model.dart';
import 'package:t_store/core/common/view_models/product_title_text_view_model.dart';
import 'package:t_store/core/common/view_models/rounded_image_view_model.dart';
import 'package:t_store/core/common/widgets/product_price_text.dart';
import 'package:t_store/core/common/widgets/product_title_text.dart';
import 'package:t_store/core/common/widgets/rounded_image.dart';
import 'package:t_store/core/utils/constants/sizes.dart';
import 'package:t_store/features/cart/domain/entities/cart_item_entity.dart';
import 'package:t_store/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:t_store/core/utils/formatters/formatter.dart';

/// Real cart line items from [CartItemEntity] (Supabase-backed).
/// Quantity controls and remove act on [CartCubit] for real.
class CartItemsList extends StatelessWidget {
  const CartItemsList({super.key, required this.items});

  final List<CartItemEntity> items;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: TSizes.spaceBtwItems),
      itemBuilder: (context, index) {
        final item = items[index];
        final product = item.product;
        final image = product?.images.isNotEmpty == true
            ? product!.images.first
            : product?.thumbnail;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RoundedImage(
              roundedImageModel: RoundedImageModel(
                image: image ?? '',
                isNetworkImage: (image ?? '').isNotEmpty,
                width: 70,
                height: 90,
                padding: const EdgeInsets.all(4),
              ),
            ),
            const SizedBox(width: TSizes.spaceBtwItems),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProductTitleText(
                    productTitleTextModel: ProductTitleTextModel(
                      title: product?.name ?? 'Product',
                      smallSize: true,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Qty: ${item.quantity}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  ProductPriceText(
                    productPriceTextModel: ProductPriceTextModel(
                      price: TFormatter.formatAmount(item.totalPrice),
                      smallSize: true,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Iconsax.add, size: 20),
                  tooltip: 'Increase quantity',
                  onPressed: () =>
                      context.read<CartCubit>().incrementQuantity(item.id),
                ),
                Text('${item.quantity}'),
                IconButton(
                  icon: const Icon(Iconsax.minus, size: 20),
                  tooltip: 'Decrease quantity',
                  onPressed: () =>
                      context.read<CartCubit>().decrementQuantity(item.id),
                ),
                IconButton(
                  icon: const Icon(Iconsax.trash, size: 20, color: Colors.red),
                  tooltip: 'Remove from cart',
                  onPressed: () =>
                      context.read<CartCubit>().removeFromCart(item.id),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
