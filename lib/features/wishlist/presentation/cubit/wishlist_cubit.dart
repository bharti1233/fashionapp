import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:t_store/core/usecases/usecase.dart';
import 'package:t_store/features/wishlist/domain/entities/wishlist_item_entity.dart';
import 'package:t_store/features/wishlist/domain/usecases/get_wishlist_usecase.dart';
import 'package:t_store/features/wishlist/domain/usecases/add_to_wishlist_usecase.dart';
import 'package:t_store/features/wishlist/domain/usecases/remove_from_wishlist_usecase.dart';
import 'package:t_store/features/wishlist/presentation/cubit/wishlist_state.dart';
import 'package:t_store/core/utils/logging/app_log_entry.dart';
import 'package:t_store/core/utils/logging/app_logger.dart';

class WishlistCubit extends Cubit<WishlistState> {
  final GetWishlistUsecase getWishlistUsecase;
  final AddToWishlistUsecase addToWishlistUsecase;
  final RemoveFromWishlistUsecase removeFromWishlistUsecase;

  WishlistCubit({
    required this.getWishlistUsecase,
    required this.addToWishlistUsecase,
    required this.removeFromWishlistUsecase,
  }) : super(WishlistInitial());

  List<WishlistItemEntity> _items = [];
  Set<String> _productIds = {};

  Future<void> getWishlist() async {
    emit(WishlistLoading());

    final result = await getWishlistUsecase(const NoParams());

    result.fold(
      (error) {
        AppLogger.instance.error(
          message: 'Wishlist getWishlist failed: $error',
          category: LogCategory.wishlist,
          event: 'GET_WISHLIST_OPERATION_FAILURE',
          screen: 'WishlistCubit',
          operation: 'getWishlist',
        );
        emit(WishlistError(error));
      },
      (items) {
        _items = items;
        _productIds = items.map((e) => e.productId).toSet();
        emit(WishlistLoaded(items));
      },
    );
  }

  Future<void> addToWishlist(String productId) async {
    final result = await addToWishlistUsecase(productId);

    result.fold(
      (error) {
        AppLogger.instance.error(
          message: 'Wishlist addToWishlist failed: $error',
          category: LogCategory.wishlist,
          event: 'ADD_TO_WISHLIST_OPERATION_FAILURE',
          screen: 'WishlistCubit',
          operation: 'addToWishlist',
        );
        emit(WishlistError(error));
      },
      (item) {
        emit(WishlistItemAdded(item));
        getWishlist();
      },
    );
  }

  Future<void> removeFromWishlist(String productId) async {
    final result = await removeFromWishlistUsecase(productId);

    result.fold(
      (error) {
        AppLogger.instance.error(
          message: 'Wishlist removeFromWishlist failed: $error',
          category: LogCategory.wishlist,
          event: 'REMOVE_FROM_WISHLIST_OPERATION_FAILURE',
          screen: 'WishlistCubit',
          operation: 'removeFromWishlist',
        );
        emit(WishlistError(error));
      },
      (_) {
        emit(WishlistItemRemoved(productId));
        getWishlist();
      },
    );
  }

  Future<void> toggleWishlist(String productId) async {
    if (isInWishlist(productId)) {
      await removeFromWishlist(productId);
    } else {
      await addToWishlist(productId);
    }
  }

  bool isInWishlist(String productId) {
    return _productIds.contains(productId);
  }

  int get itemCount => _items.length;
}
