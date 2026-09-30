import 'package:flutter/material.dart';
import 'package:t_store/core/common/view_models/section_heading_view_model.dart';
import 'package:t_store/core/common/widgets/section_heading.dart';
import 'package:t_store/core/utils/constants/sizes.dart';
import 'package:t_store/features/personalization/domain/entities/address_entity.dart';

/// Shipping address for checkout, taken from the user's real address book.
/// Null [address] renders an honest "no address" prompt instead of a
/// placeholder identity.
class BillingAddressSection extends StatelessWidget {
  final AddressEntity? address;
  final VoidCallback? onChange;

  const BillingAddressSection({super.key, this.address, this.onChange});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(
          sectionHeadingModel: SectionHeadingModel(
            title: 'Shipping Address',
            actionButtonOnPressed: onChange ?? () {},
            showActionButton: true,
            actionButtonTitle: 'Change',
          ),
        ),
        if (address == null)
          Text(
            'No delivery address selected. Please add one.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.red),
          )
        else ...[
          Text(address!.fullName, style: Theme.of(context).textTheme.bodyLarge),
          Row(
            children: [
              const Icon(Icons.phone, size: 16, color: Colors.grey),
              const SizedBox(width: TSizes.spaceBtwItems),
              Text(
                address!.phone,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: TSizes.spaceBtwItems / 2),
          Row(
            children: [
              const Icon(Icons.location_history, size: 16, color: Colors.grey),
              const SizedBox(width: TSizes.spaceBtwItems),
              Expanded(
                child: Text(
                  address!.fullAddress,
                  softWrap: true,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: TSizes.spaceBtwItems / 2),
        ],
      ],
    );
  }
}
