import 'package:dartz/dartz.dart';
import 'package:t_store/core/supabase/supabase_service.dart';
import 'package:t_store/core/supabase/supabase_tables.dart';
import 'package:t_store/core/utils/logging/app_log_entry.dart';
import 'package:t_store/core/utils/logging/app_logger.dart';
import 'package:t_store/features/shop/data/models/coupon_model.dart';
import 'package:t_store/features/shop/domain/entities/coupon_entity.dart';
import 'package:t_store/features/shop/domain/repositories/coupon_repository.dart';

class CouponRepositoryImpl implements CouponRepository {
  final SupabaseService supabaseService;

  CouponRepositoryImpl({required this.supabaseService});

  @override
  Future<Either<String, CouponEntity>> getCouponByCode(String code) async {
    try {
      final response = await supabaseService.client
          .from(SupabaseTables.coupons)
          .select()
          .eq('code', code.trim().toUpperCase())
          .maybeSingle();

      if (response == null) {
        return const Left('Invalid coupon code');
      }
      return Right(CouponModel.fromJson(response));
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        message: 'Coupon lookup failed',
        category: LogCategory.products,
        event: 'COUPON_LOOKUP_FAILURE',
        screen: 'CouponRepository',
        operation: 'getCouponByCode',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<CouponEntity>>> getActiveCoupons() async {
    try {
      final response = await supabaseService.client
          .from(SupabaseTables.coupons)
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      final coupons = (response as List)
          .map((json) => CouponModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return Right(coupons);
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        message: 'Active coupons lookup failed',
        category: LogCategory.products,
        event: 'COUPONS_LIST_FAILURE',
        screen: 'CouponRepository',
        operation: 'getActiveCoupons',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(e.toString());
    }
  }
}
