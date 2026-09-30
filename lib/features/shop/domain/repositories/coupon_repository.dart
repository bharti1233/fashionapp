import 'package:dartz/dartz.dart';
import 'package:t_store/features/shop/domain/entities/coupon_entity.dart';

/// Reads coupons from the live `coupons` table (public read policy covers
/// active coupons). Never invents discounts: a code either resolves to a
/// real row or validation fails.
abstract class CouponRepository {
  Future<Either<String, CouponEntity>> getCouponByCode(String code);

  /// All currently active coupons for the "My Coupons" list.
  Future<Either<String, List<CouponEntity>>> getActiveCoupons();
}
