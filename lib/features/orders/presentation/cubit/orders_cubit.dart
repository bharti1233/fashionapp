import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:t_store/core/usecases/usecase.dart';
import 'package:t_store/features/orders/domain/repositories/order_repository.dart';
import 'package:t_store/features/orders/domain/usecases/get_orders_usecase.dart';
import 'package:t_store/features/orders/domain/usecases/get_order_by_id_usecase.dart';
import 'package:t_store/features/orders/domain/usecases/create_order_usecase.dart';
import 'package:t_store/features/orders/domain/usecases/cancel_order_usecase.dart';
import 'package:t_store/features/orders/presentation/cubit/orders_state.dart';
import 'package:t_store/core/utils/logging/app_log_entry.dart';
import 'package:t_store/core/utils/logging/app_logger.dart';

class OrdersCubit extends Cubit<OrdersState> {
  final GetOrdersUsecase getOrdersUsecase;
  final GetOrderByIdUsecase getOrderByIdUsecase;
  final CreateOrderUsecase createOrderUsecase;
  final CancelOrderUsecase cancelOrderUsecase;

  OrdersCubit({
    required this.getOrdersUsecase,
    required this.getOrderByIdUsecase,
    required this.createOrderUsecase,
    required this.cancelOrderUsecase,
  }) : super(OrdersInitial());

  Future<void> getOrders() async {
    emit(OrdersLoading());

    final result = await getOrdersUsecase(const NoParams());

    result.fold((error) {
      AppLogger.instance.error(
        message: 'Orders getOrders failed: $error',
        category: LogCategory.orders,
        event: 'GET_ORDERS_OPERATION_FAILURE',
        screen: 'OrdersCubit',
        operation: 'getOrders',
      );
      emit(OrdersError(error));
    }, (orders) => emit(OrdersLoaded(orders)));
  }

  Future<void> getOrderById(String id) async {
    emit(OrderDetailLoading());

    final result = await getOrderByIdUsecase(id);

    result.fold((error) {
      AppLogger.instance.error(
        message: 'Orders getOrderById failed: $error',
        category: LogCategory.orders,
        event: 'GET_ORDER_BY_ID_OPERATION_FAILURE',
        screen: 'OrdersCubit',
        operation: 'getOrderById',
      );
      emit(OrdersError(error));
    }, (order) => emit(OrderDetailLoaded(order)));
  }

  Future<void> createOrder({
    required String addressId,
    required List<CreateOrderItemParams> items,
    required String paymentMethod,
    String? couponCode,
    String? notes,
    double shippingCost = 0,
    double discount = 0,
  }) async {
    emit(OrderCreating());

    final result = await createOrderUsecase(
      CreateOrderParams(
        addressId: addressId,
        items: items,
        paymentMethod: paymentMethod,
        couponCode: couponCode,
        notes: notes,
        shippingCost: shippingCost,
        discount: discount,
      ),
    );

    result.fold((error) {
      AppLogger.instance.error(
        message: 'Orders createOrder failed: $error',
        category: LogCategory.orders,
        event: 'CREATE_ORDER_OPERATION_FAILURE',
        screen: 'OrdersCubit',
        operation: 'createOrder',
      );
      emit(OrdersError(error));
    }, (order) => emit(OrderCreated(order)));
  }

  Future<void> cancelOrder(String orderId) async {
    emit(OrderCancelling());

    final result = await cancelOrderUsecase(orderId);

    result.fold((error) {
      AppLogger.instance.error(
        message: 'Orders cancelOrder failed: $error',
        category: LogCategory.orders,
        event: 'CANCEL_ORDER_OPERATION_FAILURE',
        screen: 'OrdersCubit',
        operation: 'cancelOrder',
      );
      emit(OrdersError(error));
    }, (order) => emit(OrderCancelled(order)));
  }
}
