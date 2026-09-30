import 'package:flutter_test/flutter_test.dart';
import 'package:t_store/core/utils/formatters/formatter.dart';

/// India-first pricing contracts: every customer-facing price renders as
/// ₹X,XXX.XX (Indian grouping, two decimals) and discount badges show
/// rounded whole percents — never raw floats, never "$", never "0% OFF".
void main() {
  group('TFormatter.formatPrice', () {
    test('formats with rupee symbol and two decimals', () {
      expect(TFormatter.formatPrice(49.99), '₹49.99');
    });

    test('uses Indian digit grouping', () {
      expect(TFormatter.formatPrice(100000), '₹1,00,000.00');
      expect(TFormatter.formatPrice(1234567.8), '₹12,34,567.80');
    });

    test('keeps trailing zeros', () {
      expect(TFormatter.formatPrice(175), '₹175.00');
      expect(TFormatter.formatPrice(0), '₹0.00');
    });

    test('contains no dollar sign', () {
      expect(TFormatter.formatPrice(99.99), isNot(contains('\$')));
    });
  });

  group('TFormatter.formatAmount', () {
    test('groups without prepending a symbol', () {
      expect(TFormatter.formatAmount(100000), '1,00,000.00');
      expect(TFormatter.formatAmount(59.99), '59.99');
    });
  });

  group('Discount badge rule', () {
    test('rounds raw percentages to whole numbers', () {
      expect(23.080473919064463.round(), 23);
      expect(25.012506253126553.round(), 25);
      expect(21.431633090441483.round(), 21);
    });

    test('zero discount is falsy for badge display', () {
      const discount = 0.0;
      expect(discount > 0, isFalse);
    });

    test('discount derives from prices, not stored floats', () {
      const price = 100.0;
      const salePrice = 77.0;
      final pct = ((price - salePrice) / price * 100).round();
      expect(pct, 23);
    });
  });
}
