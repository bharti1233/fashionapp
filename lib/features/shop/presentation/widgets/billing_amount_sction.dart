import 'package:flutter/material.dart';
import 'package:t_store/core/utils/constants/sizes.dart';
import 'package:t_store/core/utils/formatters/formatter.dart';

/// Real order amounts computed from the cart and validated coupon.
/// Shipping is free (₹0.00) — shown honestly, never invented.
///
/// Text styles are hoisted into short locals so the layout stays
/// formatter-stable: no chained splits.
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
    final label = Theme.of(context).textTheme.bodyMedium;
    final value = Theme.of(context).textTheme.labelLarge;
    final totalStyle = Theme.of(context).textTheme.titleMedium;
    final base = Theme.of(context).textTheme.labelLarge;
    final discountStyle = base?.copyWith(color: Colors.green);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Subtotal', style: label),
            Text(TFormatter.formatPrice(subtotal), style: value),
          ],
        ),
        const SizedBox(height: TSizes.spaceBtwItems / 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Shipping Fee', style: label),
            Text(
              shippingCost == 0
                  ? 'Free'
                  : TFormatter.formatPrice(shippingCost),
              style: value,
            ),
          ],
        ),
        if (discount > 0) ...[
          const SizedBox(height: TSizes.spaceBtwItems / 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Coupon Discount', style: label),
              Text(
                '-${TFormatter.formatPrice(discount)}',
                style: discountStyle,
              ),
            ],
          ),
        ],
        const SizedBox(height: TSizes.spaceBtwItems / 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Order Total', style: label),
            Text(TFormatter.formatPrice(total), style: totalStyle),
          ],
        ),
      ],
    );
  }
}
