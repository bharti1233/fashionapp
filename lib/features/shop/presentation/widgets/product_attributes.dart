import 'package:flutter/material.dart';
import 'package:t_store/core/common/view_models/choice_chip_view_model.dart';
import 'package:t_store/core/common/view_models/circular_container_view_model.dart';
import 'package:t_store/core/common/view_models/product_price_text_view_model.dart';
import 'package:t_store/core/common/view_models/product_title_text_view_model.dart';
import 'package:t_store/core/common/view_models/section_heading_view_model.dart';
import 'package:t_store/core/common/widgets/circular_container.dart';
import 'package:t_store/core/common/widgets/custom_choice_chip.dart';
import 'package:t_store/core/common/widgets/product_price_text.dart';
import 'package:t_store/core/common/widgets/product_title_text.dart';
import 'package:t_store/core/common/widgets/section_heading.dart';
import 'package:t_store/core/utils/constants/colors.dart';
import 'package:t_store/core/utils/constants/sizes.dart';
import 'package:t_store/core/utils/helpers/helper_functions.dart';
import 'package:t_store/features/shop/domain/entities/product_entity.dart';

/// Real variation block for [product]: live price/stock plus the variant
/// groups stored in `attributes` (e.g. colors, sizes). Groups absent from
/// the backend are hidden, never filled with static chips. The current
/// selection is reported through [onAttributesChanged] so it flows into
/// the cart item.
class ProductAttributes extends StatefulWidget {
  final ProductEntity product;
  final ValueChanged<Map<String, dynamic>>? onAttributesChanged;

  const ProductAttributes({
    super.key,
    required this.product,
    this.onAttributesChanged,
  });

  @override
  State<ProductAttributes> createState() => _ProductAttributesState();
}

class _ProductAttributesState extends State<ProductAttributes> {
  final Map<String, dynamic> _selection = {};

  /// Variant groups are the list-valued entries of the attributes map.
  Map<String, List<String>> get _groups {
    final attributes = widget.product.attributes;
    if (attributes == null) return const {};
    final groups = <String, List<String>>{};
    for (final entry in attributes.entries) {
      if (entry.value is List) {
        final values = (entry.value as List)
            .map((v) => v.toString())
            .where((v) => v.isNotEmpty)
            .toList();
        if (values.isNotEmpty) groups[entry.key] = values;
      }
    }
    return groups;
  }

  void _select(String group, String value) {
    setState(() => _selection[group] = value);
    widget.onAttributesChanged?.call(Map.of(_selection));
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final product = widget.product;
    final inStock = product.stock > 0;
    return Column(
      children: [
        CircularContainer(
          circularContainerModel: CircularContainerModel(
            color: dark ? TColors.darkerGrey : TColors.grey,
            padding: const EdgeInsets.all(TSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SectionHeading(
                      sectionHeadingModel: SectionHeadingModel(
                        title: 'Variation',
                        showActionButton: false,
                      ),
                    ),
                    const SizedBox(width: TSizes.spaceBtwItems),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ProductTitleText(
                              productTitleTextModel: ProductTitleTextModel(
                                title: 'Price : ',
                                smallSize: true,
                              ),
                            ),
                            if (product.salePrice != null)
                              Text(
                                ' ₹${product.price.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.titleSmall!
                                    .apply(
                                      decoration: TextDecoration.lineThrough,
                                    ),
                              ),
                            const SizedBox(width: TSizes.spaceBtwItems),
                            ProductPriceText(
                              productPriceTextModel: ProductPriceTextModel(
                                price: product.effectivePrice.toStringAsFixed(
                                  2,
                                ),
                                smallSize: true,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            ProductTitleText(
                              productTitleTextModel: ProductTitleTextModel(
                                title: 'Stock : ',
                                smallSize: true,
                              ),
                            ),
                            Text(
                              inStock ? 'In Stock' : 'Out of Stock',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                if ((product.description ?? '').isNotEmpty)
                  ProductTitleText(
                    productTitleTextModel: ProductTitleTextModel(
                      title: product.description!,
                      maxLines: 4,
                      smallSize: true,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: TSizes.spaceBtwItems),
        for (final group in _groups.entries)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeading(
                sectionHeadingModel: SectionHeadingModel(
                  showActionButton: false,
                  title: _titleCase(group.key),
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwItems / 2),
              Wrap(
                spacing: 8,
                children: [
                  for (final value in group.value)
                    CustomChoiceChip(
                      choiceChipModel: ChoiceChipModel(
                        label: value,
                        selected: _selection[group.key] == value,
                        onSelected: (_) => _select(group.key, value),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
            ],
          ),
      ],
    );
  }

  String _titleCase(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }
}
