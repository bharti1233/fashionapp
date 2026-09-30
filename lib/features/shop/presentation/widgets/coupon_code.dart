import 'package:flutter/material.dart';
import 'package:t_store/core/common/view_models/circular_container_view_model.dart';
import 'package:t_store/core/common/widgets/circular_container.dart';
import 'package:t_store/core/utils/constants/colors.dart';
import 'package:t_store/core/utils/constants/sizes.dart';
import 'package:t_store/core/utils/helpers/helper_functions.dart';

/// Coupon input wired to real backend validation. [onApply] receives the
/// typed code; [appliedCode] echoes the validated coupon; [errorText]
/// surfaces validation failures honestly. Never invents a discount.
class CouponCode extends StatefulWidget {
  final String? appliedCode;
  final String? errorText;
  final bool applying;
  final ValueChanged<String> onApply;
  final VoidCallback? onRemove;

  const CouponCode({
    super.key,
    this.appliedCode,
    this.errorText,
    this.applying = false,
    required this.onApply,
    this.onRemove,
  });

  @override
  State<CouponCode> createState() => _CouponCodeState();
}

class _CouponCodeState extends State<CouponCode> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return CircularContainer(
      circularContainerModel: CircularContainerModel(
        padding: const EdgeInsets.fromLTRB(
          TSizes.md,
          TSizes.sm,
          TSizes.sm,
          TSizes.sm,
        ),
        showBorder: true,
        color: dark ? TColors.dark : TColors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: TextFormField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'Have a promo code? Enter here',
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(TSizes.md),
                      foregroundColor: dark
                          ? TColors.white.withValues(alpha: .5)
                          : TColors.dark.withValues(alpha: .5),
                      backgroundColor: Colors.grey.withValues(alpha: .2),
                      side: BorderSide(
                        color: Colors.grey.withValues(alpha: .1),
                      ),
                    ),
                    onPressed: widget.applying
                        ? null
                        : () => widget.onApply(_controller.text.trim()),
                    child: widget.applying
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Apply'),
                  ),
                ),
              ],
            ),
            if (widget.appliedCode != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Coupon ${widget.appliedCode} applied',
                      style: const TextStyle(fontSize: 12, color: Colors.green),
                    ),
                  ),
                  if (widget.onRemove != null)
                    TextButton(
                      onPressed: widget.onRemove,
                      child: const Text('Remove'),
                    ),
                ],
              ),
            ],
            if (widget.errorText != null) ...[
              const SizedBox(height: 4),
              Text(
                widget.errorText!,
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
