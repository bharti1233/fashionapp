import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:t_store/core/usecases/usecase.dart';
import 'package:t_store/features/shop/domain/usecases/get_banners_usecase.dart';
import 'package:t_store/features/shop/presentation/cubit/banners_state.dart';
import 'package:t_store/core/utils/logging/app_log_entry.dart';
import 'package:t_store/core/utils/logging/app_logger.dart';

class BannersCubit extends Cubit<BannersState> {
  final GetBannersUsecase getBannersUsecase;

  BannersCubit({required this.getBannersUsecase}) : super(BannersInitial());

  Future<void> getBanners() async {
    emit(BannersLoading());

    final result = await getBannersUsecase(const NoParams());

    result.fold((error) {
      AppLogger.instance.error(
        message: 'Banners getBanners failed: $error',
        category: LogCategory.products,
        event: 'GET_BANNERS_OPERATION_FAILURE',
        screen: 'BannersCubit',
        operation: 'getBanners',
      );
      emit(BannersError(error));
    }, (banners) => emit(BannersLoaded(banners)));
  }
}
