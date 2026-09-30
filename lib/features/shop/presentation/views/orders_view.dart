import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:t_store/core/common/view_models/app_bar_view_model.dart';
import 'package:t_store/core/common/widgets/app_bar.dart';
import 'package:t_store/core/utils/constants/sizes.dart';
import 'package:t_store/core/utils/logging/app_log_entry.dart';
import 'package:t_store/core/utils/logging/app_logger.dart';
import 'package:t_store/features/orders/domain/entities/order_entity.dart';
import 'package:t_store/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:t_store/features/orders/presentation/cubit/orders_state.dart';
import 'package:t_store/features/shop/presentation/widgets/orders_list.dart';

/// Order history backed by Supabase through [OrdersCubit].
///
/// Loading / empty / error (with retry) states are honest. Cancel is
/// offered only where the backend supports it (pending/confirmed).
class OrdersView extends StatefulWidget {
  const OrdersView({super.key});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    AppLogger.instance.info(
      message: 'Orders loading started',
      category: LogCategory.orders,
      event: 'ORDERS_LOAD_START',
      screen: 'OrdersView',
      operation: 'loadOrders',
    );
    context.read<OrdersCubit>().getOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        appBarModel: AppBarModel(
          title: Text(
            'My Orders',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ),
      body: BlocBuilder<OrdersCubit, OrdersState>(
        builder: (context, state) {
          if (state is OrdersLoading || state is OrdersInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is OrdersError) {
            return _OrdersMessage(
              message: state.message,
              actionLabel: 'RETRY',
              onAction: _load,
            );
          }
          final orders = _visibleOrders(state);
          if (orders.isEmpty) {
            return const _OrdersMessage(
              message:
                  'You have no orders yet.\n'
                  'Your orders will appear here after checkout.',
            );
          }
          return Padding(
            padding: const EdgeInsets.all(TSizes.defaultSpace),
            child: OrdersList(
              orders: orders,
              onCancel: (order) =>
                  context.read<OrdersCubit>().cancelOrder(order.id),
            ),
          );
        },
      ),
    );
  }

  List<OrderEntity> _visibleOrders(OrdersState state) {
    if (state is OrdersLoaded) return state.orders;
    return const [];
  }
}

class _OrdersMessage extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _OrdersMessage({
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
              Icons.shopping_bag_outlined,
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
