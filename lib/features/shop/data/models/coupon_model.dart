import 'package:t_store/features/shop/domain/entities/coupon_entity.dart';

class CouponModel extends CouponEntity {
  const CouponModel({
    required super.id,
    required super.code,
    super.description,
    required super.discountType,
    required super.discountValue,
    super.minOrderAmount,
    super.maxDiscount,
    super.isActive,
    super.startsAt,
    super.expiresAt,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id'] as String,
      code: json['code'] as String,
      description: json['description'] as String?,
      discountType: json['discount_type'] as String? ?? 'fixed',
      discountValue: (json['discount_value'] as num).toDouble(),
      minOrderAmount: (json['min_order_amount'] as num?)?.toDouble() ?? 0,
      maxDiscount: (json['max_discount'] as num?)?.toDouble(),
      isActive: json['is_active'] as bool? ?? true,
      startsAt: json['starts_at'] != null
          ? DateTime.parse(json['starts_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }
}
