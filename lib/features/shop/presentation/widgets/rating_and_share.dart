import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:t_store/core/utils/constants/sizes.dart';

/// Real rating summary for a product.
class RatingAndShare extends StatelessWidget {
  final double rating;
  final int reviewsCount;

  const RatingAndShare({
    super.key,
    required this.rating,
    required this.reviewsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Iconsax.star5, color: Colors.amber, size: 24),
            const SizedBox(width: TSizes.spaceBtwItems / 2),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${rating.toStringAsFixed(1)} ',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  TextSpan(text: '($reviewsCount)'),
                ],
              ),
            ),
          ],
        ),
        const Icon(Icons.share, size: TSizes.iconMd),
      ],
    );
  }
}
