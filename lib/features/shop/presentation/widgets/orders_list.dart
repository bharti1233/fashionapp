import 'package:flutter/material.dart';
import 'package:t_store/core/utils/constants/sizes.dart';
import 'package:t_store/features/orders/domain/entities/order_entity.dart';
import 'package:t_store/features/shop/presentation/widgets/order_list_item.dart';

/// Real order rows from Supabase. Never fabricated.
class OrdersList extends StatelessWidget {
  final List<OrderEntity> orders;
  final void Function(OrderEntity order)? onCancel;

  const OrdersList({super.key, required this.orders, this.onCancel});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return OrderListItem(
          order: order,
          onCancel: onCancel == null ? null : () => onCancel!(order),
        );
      },
      separatorBuilder: (context, index) =>
          const SizedBox(height: TSizes.spaceBtwItems),
    );
  }
}
