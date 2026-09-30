import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:t_store/features/shop/domain/entities/coupon_entity.dart';
import 'package:t_store/features/shop/domain/repositories/coupon_repository.dart';
import 'package:t_store/features/shop/domain/usecases/validate_coupon_usecase.dart';

class MockCouponRepository extends Mock implements CouponRepository {}

/// Validates REAL coupon rules against injected repository rows.
/// No network, no real codes — the logic under test is identical to
/// production: active check, date window, minimum order, percentage cap,
/// fixed amounts, and rejection of unknown types.
void main() {
  late MockCouponRepository mockRepository;
  late ValidateCouponUsecase usecase;

  setUp(() {
    mockRepository = MockCouponRepository();
    usecase = ValidateCouponUsecase(mockRepository);
  });

  CouponEntity coupon({
    String discountType = 'percentage',
    double discountValue = 10,
    double minOrderAmount = 0,
    double? maxDiscount,
    bool isActive = true,
    DateTime? startsAt,
    DateTime? expiresAt,
  }) {
    return CouponEntity(
      id: 'c1',
      code: 'SAVE10',
      discountType: discountType,
      discountValue: discountValue,
      minOrderAmount: minOrderAmount,
      maxDiscount: maxDiscount,
      isActive: isActive,
      startsAt: startsAt,
      expiresAt: expiresAt,
    );
  }

  void stub(CouponEntity c) {
    when(
      () => mockRepository.getCouponByCode(any()),
    ).thenAnswer((_) async => Right(c));
  }

  test('percentage coupon computes subtotal share', () async {
    stub(coupon());
    final result = await usecase(
      const ValidateCouponParams(code: 'SAVE10', subtotal: 1000),
    );
    expect(result.isRight(), isTrue);
    result.fold(
      (_) => fail('expected Right'),
      (applied) => expect(applied.discountAmount, 100),
    );
  });

  test('percentage capped at maxDiscount', () async {
    stub(coupon(discountValue: 50, maxDiscount: 200));
    final result = await usecase(
      const ValidateCouponParams(code: 'SAVE10', subtotal: 1000),
    );
    result.fold(
      (_) => fail('expected Right'),
      (applied) => expect(applied.discountAmount, 200),
    );
  });

  test('fixed coupon returns face value without exceeding subtotal', () async {
    stub(coupon(discountType: 'fixed', discountValue: 500));
    final result = await usecase(
      const ValidateCouponParams(code: 'SAVE10', subtotal: 300),
    );
    result.fold(
      (_) => fail('expected Right'),
      (applied) => expect(applied.discountAmount, 300),
    );
  });

  test('minimum order enforced', () async {
    stub(coupon(minOrderAmount: 999));
    final result = await usecase(
      const ValidateCouponParams(code: 'SAVE10', subtotal: 100),
    );
    expect(result.isLeft(), isTrue);
  });

  test('expired and inactive rejected', () async {
    stub(coupon(expiresAt: DateTime(2020)));
    expect(
      (await usecase(
        const ValidateCouponParams(code: 'SAVE10', subtotal: 1000),
      )).isLeft(),
      isTrue,
    );
    stub(coupon(isActive: false));
    expect(
      (await usecase(
        const ValidateCouponParams(code: 'SAVE10', subtotal: 1000),
      )).isLeft(),
      isTrue,
    );
  });

  test('unknown discount type rejected, never guessed', () async {
    stub(coupon(discountType: 'mystery'));
    final result = await usecase(
      const ValidateCouponParams(code: 'SAVE10', subtotal: 1000),
    );
    expect(result.isLeft(), isTrue);
  });

  test('unknown code propagates repository failure', () async {
    when(
      () => mockRepository.getCouponByCode(any()),
    ).thenAnswer((_) async => const Left('Invalid coupon code'));
    final result = await usecase(
      const ValidateCouponParams(code: 'NOPE', subtotal: 1000),
    );
    expect(result, const Left('Invalid coupon code'));
  });
}
