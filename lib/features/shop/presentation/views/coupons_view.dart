import 'package:dartz/dartz.dart' as dartz;
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:t_store/core/common/view_models/app_bar_view_model.dart';
import 'package:t_store/core/common/widgets/app_bar.dart';
import 'package:t_store/core/dependency_injection/service_locator.dart';
import 'package:t_store/core/utils/constants/sizes.dart';
import 'package:t_store/core/utils/formatters/formatter.dart';
import 'package:t_store/core/utils/logging/app_log_entry.dart';
import 'package:t_store/core/utils/logging/app_logger.dart';
import 'package:t_store/features/shop/domain/entities/coupon_entity.dart';
import 'package:t_store/features/shop/domain/repositories/coupon_repository.dart';

/// "My Coupons" list backed by the live `coupons` table.
///
/// Shows real active coupons with their actual terms. Empty/error states
/// are honest — codes are never invented.
class CouponsView extends StatefulWidget {
  const CouponsView({super.key});

  @override
  State<CouponsView> createState() => _CouponsViewState();
}

class _CouponsViewState extends State<CouponsView> {
  late Future<dartz.Either<String, List<CouponEntity>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<dartz.Either<String, List<CouponEntity>>> _load() {
    AppLogger.instance.info(
      message: 'Coupons list loading started',
      category: LogCategory.products,
      event: 'COUPONS_LIST_START',
      screen: 'CouponsView',
      operation: 'loadCoupons',
    );
    return sl<CouponRepository>().getActiveCoupons();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        appBarModel: AppBarModel(
          hasArrowBack: true,
          title: Text(
            'My Coupons',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ),
      body: FutureBuilder<dartz.Either<String, List<CouponEntity>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _CouponsMessage(
              message: 'Could not load coupons.',
              actionLabel: 'RETRY',
              onAction: () => setState(() => _future = _load()),
            );
          }
          return snapshot.data!.fold(
            (error) => _CouponsMessage(
              message: error,
              actionLabel: 'RETRY',
              onAction: () => setState(() => _future = _load()),
            ),
            (coupons) {
              if (coupons.isEmpty) {
                return const _CouponsMessage(
                  message: 'No coupons available right now.',
                );
              }
              return RefreshIndicator(
                onRefresh: () async => setState(() => _future = _load()),
                child: ListView.separated(
                  padding: const EdgeInsets.all(TSizes.defaultSpace),
                  itemCount: coupons.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: TSizes.spaceBtwItems / 2),
                  itemBuilder: (context, index) =>
                      _CouponTile(coupon: coupons[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CouponTile extends StatelessWidget {
  final CouponEntity coupon;

  const _CouponTile({required this.coupon});

  @override
  Widget build(BuildContext context) {
    final terms = <String>[
      coupon.discountType.toLowerCase().contains('percent')
          ? '${coupon.discountValue.toStringAsFixed(coupon.discountValue.truncateToDouble() == coupon.discountValue ? 0 : 1)}% off'
          : '${TFormatter.formatPrice(coupon.discountValue)} off',
      if (coupon.minOrderAmount > 0)
        'on orders above ${TFormatter.formatPrice(coupon.minOrderAmount)}',
    ].join(' ');
    return Card(
      child: ListTile(
        leading: const Icon(Iconsax.discount_shape, color: Colors.green),
        title: Text(
          coupon.code,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((coupon.description ?? '').isNotEmpty)
              Text(coupon.description!),
            Text(terms, style: const TextStyle(color: Colors.green)),
            if (coupon.expiresAt != null)
              Text(
                'Valid till ${TFormatter.formatDate(coupon.expiresAt)}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
          ],
        ),
      ),
    );
  }
}

class _CouponsMessage extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _CouponsMessage({
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
            const Icon(Iconsax.discount_shape, size: 64, color: Colors.grey),
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
