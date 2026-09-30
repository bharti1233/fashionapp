import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:t_store/core/common/view_models/section_heading_view_model.dart';
import 'package:t_store/core/common/widgets/section_heading.dart';
import 'package:t_store/core/utils/constants/colors.dart';
import 'package:t_store/core/utils/constants/sizes.dart';

/// Payment method selection. Cash on Delivery is the only available
/// method: there is no payment SDK integrated, so online payment is
/// explicitly marked unavailable instead of faking a success.
class BillingPaymentSection extends StatelessWidget {
  final String selectedMethod;
  final ValueChanged<String>? onMethodSelected;

  const BillingPaymentSection({
    super.key,
    this.selectedMethod = 'Cash on Delivery',
    this.onMethodSelected,
  });

  static const String cashOnDelivery = 'Cash on Delivery';

  void _onMethodChanged(String? value) {
    onMethodSelected?.call(value ?? cashOnDelivery);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(
          sectionHeadingModel: SectionHeadingModel(
            title: 'Payment Method',
            actionButtonOnPressed: () {},
            showActionButton: false,
          ),
        ),
        const SizedBox(height: TSizes.spaceBtwItems / 2),
        RadioGroup<String>(
          groupValue: selectedMethod,
          onChanged: _onMethodChanged,
          child: Container(
            decoration: BoxDecoration(
              color: TColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: TColors.primary.withValues(alpha: 0.4)),
            ),
            child: RadioListTile<String>(
              value: cashOnDelivery,
              title: const Text('Cash on Delivery'),
              subtitle: const Text('Pay when your order arrives'),
              secondary: const Icon(Iconsax.money),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
        ),
        const SizedBox(height: TSizes.spaceBtwItems / 2),
        const Text(
          'Online payment (UPI, cards) is not integrated yet.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
