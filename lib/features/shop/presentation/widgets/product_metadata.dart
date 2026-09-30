import 'package:flutter/material.dart';
import 'package:t_store/core/common/view_models/brand_title_with_verification_view_model.dart';
import 'package:t_store/core/common/view_models/product_price_text_view_model.dart';
import 'package:t_store/core/common/view_models/product_title_text_view_model.dart';
import 'package:t_store/core/common/widgets/brand_title_with_verification.dart';
import 'package:t_store/core/common/widgets/product_price_text.dart';
import 'package:t_store/core/common/widgets/product_title_text.dart';
import 'package:t_store/core/utils/constants/colors.dart';
import 'package:t_store/core/utils/constants/sizes.dart';
import 'package:t_store/core/utils/helpers/helper_functions.dart';
import 'package:t_store/features/shop/domain/entities/product_entity.dart';

/// Real product identity block: price, title, stock state and brand name
/// all come from [product]. No static catalog values.
class ProductMetadata extends StatelessWidget {
  final ProductEntity product;

  const ProductMetadata({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final discount = product.salePrice != null && product.price > 0
        ? ((product.price - product.salePrice!) / product.price * 100).round()
        : 0;
    final inStock = product.stock > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (discount > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: TSizes.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: TColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(TSizes.sm),
                ),
                child: Text(
                  '$discount% OFF',
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: TColors.primary),
                ),
              ),
              const SizedBox(width: TSizes.spaceBtwItems),
            ],
            if (product.salePrice != null)
              Text(
                ' ₹${product.price.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleSmall!.apply(
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            const SizedBox(width: TSizes.spaceBtwItems),
            ProductPriceText(
              productPriceTextModel: ProductPriceTextModel(
                price: product.effectivePrice.toStringAsFixed(2),
                smallSize: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: TSizes.spaceBtwItems / 1.5),
        ProductTitleText(
          productTitleTextModel: ProductTitleTextModel(title: product.name),
        ),
        const SizedBox(height: TSizes.spaceBtwItems / 1.5),
        Row(
          children: [
            ProductTitleText(
              productTitleTextModel: ProductTitleTextModel(title: 'Status'),
            ),
            const SizedBox(width: TSizes.spaceBtwItems),
            Text(
              inStock ? 'In Stock (${product.stock})' : 'Out of Stock',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: inStock ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: TSizes.spaceBtwItems / 1.5),
        if ((product.brandName ?? '').isNotEmpty)
          BrandTitleWithVerification(
            brandTitleWithVerificationModel: BrandTitleWithVerificationModel(
              brandName: product.brandName!,
            ),
          ),
      ],
    );
  }
}
