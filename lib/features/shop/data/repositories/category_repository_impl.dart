import 'package:dartz/dartz.dart';
import 'package:t_store/core/supabase/supabase_service.dart';
import 'package:t_store/core/supabase/supabase_tables.dart';
import 'package:t_store/features/shop/data/models/category_model.dart';
import 'package:t_store/features/shop/domain/entities/category_entity.dart';
import 'package:t_store/features/shop/domain/repositories/category_repository.dart';
import 'package:t_store/core/utils/logging/app_log_entry.dart';
import 'package:t_store/core/utils/logging/app_logger.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final SupabaseService supabaseService;

  CategoryRepositoryImpl({required this.supabaseService});

  @override
  Future<Either<String, List<CategoryEntity>>> getCategories() async {
    try {
      final response = await supabaseService.client
          .from(SupabaseTables.categories)
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      final categories = (response as List)
          .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return Right(categories);
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        message: 'Category getCategories failed',
        category: LogCategory.products,
        event: 'GET_CATEGORIES_FAILURE',
        screen: 'CategoryRepository',
        operation: 'getCategories',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, CategoryEntity>> getCategoryById(String id) async {
    try {
      final response = await supabaseService.client
          .from(SupabaseTables.categories)
          .select()
          .eq('id', id)
          .single();

      return Right(CategoryModel.fromJson(response));
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        message: 'Category getCategoryById failed',
        category: LogCategory.products,
        event: 'GET_CATEGORY_BY_ID_FAILURE',
        screen: 'CategoryRepository',
        operation: 'getCategoryById',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<CategoryEntity>>> getParentCategories() async {
    try {
      final response = await supabaseService.client
          .from(SupabaseTables.categories)
          .select()
          .eq('is_active', true)
          .isFilter('parent_id', null)
          .order('sort_order', ascending: true);

      final categories = (response as List)
          .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return Right(categories);
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        message: 'Category getParentCategories failed',
        category: LogCategory.products,
        event: 'GET_PARENT_CATEGORIES_FAILURE',
        screen: 'CategoryRepository',
        operation: 'getParentCategories',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<CategoryEntity>>> getSubCategories(
    String parentId,
  ) async {
    try {
      final response = await supabaseService.client
          .from(SupabaseTables.categories)
          .select()
          .eq('is_active', true)
          .eq('parent_id', parentId)
          .order('sort_order', ascending: true);

      final categories = (response as List)
          .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return Right(categories);
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        message: 'Category getSubCategories failed',
        category: LogCategory.products,
        event: 'GET_SUB_CATEGORIES_FAILURE',
        screen: 'CategoryRepository',
        operation: 'getSubCategories',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(e.toString());
    }
  }
}
