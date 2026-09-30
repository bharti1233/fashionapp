import 'package:dartz/dartz.dart';
import 'package:t_store/core/supabase/supabase_service.dart';
import 'package:t_store/core/supabase/supabase_tables.dart';
import 'package:t_store/features/shop/data/models/brand_model.dart';
import 'package:t_store/features/shop/domain/entities/brand_entity.dart';
import 'package:t_store/features/shop/domain/repositories/brand_repository.dart';
import 'package:t_store/core/utils/logging/app_log_entry.dart';
import 'package:t_store/core/utils/logging/app_logger.dart';

class BrandRepositoryImpl implements BrandRepository {
  final SupabaseService supabaseService;

  BrandRepositoryImpl({required this.supabaseService});

  @override
  Future<Either<String, List<BrandEntity>>> getBrands() async {
    try {
      final response = await supabaseService.client
          .from(SupabaseTables.brands)
          .select()
          .eq('is_active', true)
          .order('name', ascending: true);

      final brands = (response as List)
          .map((json) => BrandModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return Right(brands);
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        message: 'Brand getBrands failed',
        category: LogCategory.products,
        event: 'GET_BRANDS_FAILURE',
        screen: 'BrandRepository',
        operation: 'getBrands',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, BrandEntity>> getBrandById(String id) async {
    try {
      final response = await supabaseService.client
          .from(SupabaseTables.brands)
          .select()
          .eq('id', id)
          .single();

      return Right(BrandModel.fromJson(response));
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        message: 'Brand getBrandById failed',
        category: LogCategory.products,
        event: 'GET_BRAND_BY_ID_FAILURE',
        screen: 'BrandRepository',
        operation: 'getBrandById',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<BrandEntity>>> getFeaturedBrands() async {
    try {
      final response = await supabaseService.client
          .from(SupabaseTables.brands)
          .select()
          .eq('is_active', true)
          .eq('is_featured', true)
          .order('name', ascending: true);

      final brands = (response as List)
          .map((json) => BrandModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return Right(brands);
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        message: 'Brand getFeaturedBrands failed',
        category: LogCategory.products,
        event: 'GET_FEATURED_BRANDS_FAILURE',
        screen: 'BrandRepository',
        operation: 'getFeaturedBrands',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(e.toString());
    }
  }
}
