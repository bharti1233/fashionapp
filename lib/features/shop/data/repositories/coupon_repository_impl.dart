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
}
