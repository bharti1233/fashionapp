/// Coupon from the live `coupons` table.
class CouponEntity {
  final String id;
  final String code;
  final String? description;
  final String discountType;
  final double discountValue;
  final double minOrderAmount;
  final double? maxDiscount;
  final bool isActive;
  final DateTime? startsAt;
  final DateTime? expiresAt;

  const CouponEntity({
    required this.id,
    required this.code,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.minOrderAmount = 0,
    this.maxDiscount,
    this.isActive = true,
    this.startsAt,
    this.expiresAt,
  });
}

/// Validated coupon plus the concrete discount for an order subtotal.
class AppliedCoupon {
  final CouponEntity coupon;
  final double discountAmount;

  const AppliedCoupon({required this.coupon, required this.discountAmount});
}
