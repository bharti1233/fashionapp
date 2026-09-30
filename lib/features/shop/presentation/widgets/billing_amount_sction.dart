import 'package:flutter/material.dart';
import 'package:t_store/core/utils/constants/sizes.dart';
import 'package:t_store/core/utils/formatters/formatter.dart';

/// Real order amounts computed from the cart and validated coupon.
/// Shipping is free (₹0.00) — shown honestly, never invented.
class BillingAmountSection extends StatelessWidget {
  final double subtotal;
  final double shippingCost;
  final double discount;
  final double total;

  const BillingAmountSection({
    super.key,
    required this.subtotal,
    this.shippingCost = 0,
    this.discount = 0,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Subtotal', style: Theme.of(context).textTheme.bodyMedium),
            Text(
              '${TFormatter.formatPrice(subtotal)}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: TSizes.spaceBtwItems / 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Shipping Fee', style: Theme.of(context).textTheme.bodyMedium),
            Text(
              shippingCost == 0
                  ? 'Free'
                  : '${TFormatter.formatPrice(shippingCost)}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
        if (discount > 0) ...[
          const SizedBox(height: TSizes.spaceBtwItems / 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Coupon Discount',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '-${TFormatter.formatPrice(discount)}',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: Colors.green),
              ),
            ],
          ),
        ],
        const SizedBox(height: TSizes.spaceBtwItems / 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Order Total', style: Theme.of(context).textTheme.bodyMedium),
            Text(
              '${TFormatter.formatPrice(total)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ],
    );
  }
}
