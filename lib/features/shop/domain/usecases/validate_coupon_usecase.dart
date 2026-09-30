import 'package:dartz/dartz.dart';
import 'package:t_store/core/usecases/usecase.dart';
import 'package:t_store/features/shop/domain/entities/coupon_entity.dart';
import 'package:t_store/features/shop/domain/repositories/coupon_repository.dart';
import 'package:t_store/core/utils/formatters/formatter.dart';

/// Validates a coupon code against the live `coupons` table and computes
/// the concrete discount for [ValidateCouponParams.subtotal].
///
/// Rules (all from the real row, never invented): the coupon must be
/// active, within its date window, and the subtotal must reach
/// `min_order_amount`. Percentage discounts are capped at `max_discount`
/// when set. Unknown discount types are rejected, not guessed.
class ValidateCouponUsecase
    implements UseCase<AppliedCoupon, ValidateCouponParams> {
  final CouponRepository repository;

  ValidateCouponUsecase(this.repository);

  @override
  Future<Either<String, AppliedCoupon>> call(
    ValidateCouponParams params,
  ) async {
    final result = await repository.getCouponByCode(params.code);
    return result.fold((error) => Left(error), (coupon) {
      final now = DateTime.now();
      if (!coupon.isActive) {
        return const Left('This coupon is no longer active');
      }
      if (coupon.startsAt != null && now.isBefore(coupon.startsAt!)) {
        return const Left('This coupon is not valid yet');
      }
      if (coupon.expiresAt != null && now.isAfter(coupon.expiresAt!)) {
        return const Left('This coupon has expired');
      }
      if (params.subtotal < coupon.minOrderAmount) {
        return Left(
          'This coupon needs a minimum order of '
          '${TFormatter.formatPrice(coupon.minOrderAmount)}',
        );
      }
      final double raw;
      switch (coupon.discountType.toLowerCase()) {
        case 'percentage':
        case 'percent':
          raw = params.subtotal * coupon.discountValue / 100;
        case 'fixed':
        case 'amount':
          raw = coupon.discountValue;
        default:
          return const Left('This coupon type is not supported');
      }
      var discount = raw;
      if (coupon.maxDiscount != null && discount > coupon.maxDiscount!) {
        discount = coupon.maxDiscount!;
      }
      if (discount > params.subtotal) {
        discount = params.subtotal;
      }
      return Right(AppliedCoupon(coupon: coupon, discountAmount: discount));
    });
  }
}

class ValidateCouponParams {
  final String code;
  final double subtotal;

  const ValidateCouponParams({required this.code, required this.subtotal});
}
