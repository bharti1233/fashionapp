import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:t_store/core/common/view_models/app_bar_view_model.dart';
import 'package:t_store/core/common/widgets/app_bar.dart';
import 'package:t_store/core/utils/constants/sizes.dart';
import 'package:t_store/core/utils/logging/app_log_entry.dart';
import 'package:t_store/core/utils/logging/app_logger.dart';
import 'package:t_store/features/reviews/domain/entities/review_entity.dart';
import 'package:t_store/features/reviews/presentation/cubit/reviews_cubit.dart';
import 'package:t_store/features/reviews/presentation/cubit/reviews_state.dart';
import 'package:t_store/features/shop/presentation/widgets/custom_rating_bar_indicator.dart';
import 'package:t_store/features/shop/presentation/widgets/user_review_card.dart';

/// Product reviews backed by Supabase through [ReviewsCubit].
///
/// Average, count and cards all come from real review rows. Empty and
/// error states are honest — no hardcoded ratings or lorem reviews.
class ProductReviewsView extends StatefulWidget {
  final String productId;

  const ProductReviewsView({super.key, required this.productId});

  @override
  State<ProductReviewsView> createState() => _ProductReviewsViewState();
}

class _ProductReviewsViewState extends State<ProductReviewsView> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    AppLogger.instance.info(
      message: 'Product reviews loading started',
      category: LogCategory.reviews,
      event: 'REVIEWS_LOAD_START',
      screen: 'ProductReviewsView',
      operation: 'loadReviews',
    );
    context.read<ReviewsCubit>().getProductReviews(
      widget.productId,
      refresh: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        appBarModel: AppBarModel(
          hasArrowBack: true,
          title: const Text('Reviews & Ratings'),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<ReviewsCubit, ReviewsState>(
          builder: (context, state) {
            if (state is ReviewsLoading || state is ReviewsInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ReviewsError) {
              return _ReviewsMessage(
                message: state.message,
                actionLabel: 'RETRY',
                onAction: _load,
              );
            }
            final reviews = _visibleReviews(state);
            if (reviews.isEmpty) {
              return const _ReviewsMessage(
                message:
                    'No reviews yet.\nBe the first to review this product.',
              );
            }
            final average = _average(
              reviews.map((r) => r.rating.toDouble()).toList(),
            );
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(TSizes.defaultSpace),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ratings and reviews are from verified purchasers.',
                    ),
                    const SizedBox(height: TSizes.spaceBtwItems),
                    CustomRatingBarIndicator(rating: average),
                    Text(
                      '${average.toStringAsFixed(1)} · ${reviews.length} review${reviews.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: TSizes.spaceBtwSections),
                    for (final review in reviews)
                      UserReviewCard(review: review),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<ReviewEntity> _visibleReviews(ReviewsState state) {
    if (state is ReviewsLoaded) return state.reviews;
    return const [];
  }

  double _average(List<double> ratings) {
    if (ratings.isEmpty) return 0;
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }
}

class _ReviewsMessage extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _ReviewsMessage({
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
            const Icon(
              Icons.rate_review_outlined,
              size: 64,
              color: Colors.grey,
            ),
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
