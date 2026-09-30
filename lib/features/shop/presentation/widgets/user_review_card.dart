import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:t_store/features/shop/presentation/widgets/custom_rating_bar_indicator.dart';
import 'package:t_store/core/common/widgets/read_more.dart';
import 'package:t_store/core/utils/constants/sizes.dart';
import 'package:t_store/core/utils/helpers/helper_functions.dart';
import 'package:t_store/features/reviews/domain/entities/review_entity.dart';

/// One real customer review from Supabase. No placeholder names, dates,
/// or lorem text.
class UserReviewCard extends StatelessWidget {
  final ReviewEntity review;

  const UserReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final date = review.createdAt != null
        ? DateFormat('dd MMM, yyyy').format(review.createdAt!)
        : '';
    final title = (review.title ?? '').isNotEmpty
        ? review.title!
        : (review.comment ?? '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: dark ? Colors.grey[800] : Colors.grey[300],
                  child: Text(
                    _initial(review.userName),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: TSizes.spaceBtwItems),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName?.isNotEmpty == true
                            ? review.userName!
                            : 'Verified buyer',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (review.isVerifiedPurchase)
                        Text(
                          'Verified purchase',
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(color: Colors.green),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: TSizes.spaceBtwItems / 2),
        Row(
          children: [
            CustomRatingBarIndicator(rating: review.rating.toDouble()),
            const SizedBox(width: TSizes.spaceBtwItems),
            if (date.isNotEmpty)
              Text(date, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        if (title.isNotEmpty) ...[
          const SizedBox(height: TSizes.spaceBtwItems),
          ReadMore(text: title),
        ],
        const SizedBox(height: TSizes.spaceBtwSections),
      ],
    );
  }

  String _initial(String? name) {
    if (name == null || name.isEmpty) return '•';
    return name[0].toUpperCase();
  }
}
