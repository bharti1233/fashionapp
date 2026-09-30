import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:t_store/core/usecases/usecase.dart';
import 'package:t_store/features/shop/domain/usecases/get_brands_usecase.dart';
import 'package:t_store/features/shop/presentation/cubit/brands_state.dart';
import 'package:t_store/core/utils/logging/app_log_entry.dart';
import 'package:t_store/core/utils/logging/app_logger.dart';

class BrandsCubit extends Cubit<BrandsState> {
  final GetBrandsUsecase getBrandsUsecase;

  BrandsCubit({required this.getBrandsUsecase}) : super(BrandsInitial());

  Future<void> getBrands() async {
    emit(BrandsLoading());

    final result = await getBrandsUsecase(const NoParams());

    result.fold((error) {
      AppLogger.instance.error(
        message: 'Brands getBrands failed: $error',
        category: LogCategory.products,
        event: 'GET_BRANDS_OPERATION_FAILURE',
        screen: 'BrandsCubit',
        operation: 'getBrands',
      );
      emit(BrandsError(error));
    }, (brands) => emit(BrandsLoaded(brands)));
  }
}
