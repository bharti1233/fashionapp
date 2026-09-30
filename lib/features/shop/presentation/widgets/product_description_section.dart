import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:t_store/core/common/view_models/section_heading_view_model.dart';
import 'package:t_store/core/common/widgets/read_more.dart';
import 'package:t_store/core/common/widgets/section_heading.dart';
import 'package:t_store/core/utils/constants/sizes.dart';
import 'package:t_store/core/utils/helpers/helper_functions.dart';
import 'package:t_store/features/shop/domain/entities/product_entity.dart';
import 'package:t_store/features/shop/presentation/views/product_reviews_view.dart';

/// Real product description plus a reviews entry showing the live review
/// count. No lorem text, no hardcoded counts.
class ProductDescriptionAndReviewsSection extends StatelessWidget {
  final ProductEntity product;

  const ProductDescriptionAndReviewsSection({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionHeading(
          sectionHeadingModel: SectionHeadingModel(
            title: 'Description',
            showActionButton: false,
          ),
        ),
        const SizedBox(height: TSizes.spaceBtwItems),
        ReadMore(
          text: (product.description ?? '').isNotEmpty
              ? product.description!
              : 'No description available for this product.',
        ),
        const SizedBox(height: TSizes.spaceBtwItems / 2),
        const Divider(),
        const SizedBox(height: TSizes.spaceBtwItems / 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SectionHeading(
              sectionHeadingModel: SectionHeadingModel(
                title: 'Reviews(${product.reviewsCount})',
                showActionButton: false,
              ),
            ),
            TextButton(
              onPressed: () {
                THelperFunctions.navigateToScreen(
                  context,
                  ProductReviewsView(productId: product.id),
                );
              },
              child: const Icon(Iconsax.arrow_right_3, size: 18),
            ),
          ],
        ),
      ],
    );
  }
}
