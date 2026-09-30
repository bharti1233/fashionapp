import 'package:flutter/material.dart';
import 'package:t_store/core/common/view_models/category_tab_view_model.dart';
import 'package:t_store/core/common/view_models/grid_layout_view_model.dart';
import 'package:t_store/core/common/view_models/section_heading_view_model.dart';
import 'package:t_store/core/common/widgets/section_heading.dart';
import 'package:t_store/core/common/widgets/vertical_product_card.dart';
import 'package:t_store/core/utils/constants/sizes.dart';
import 'package:t_store/features/auth/presentation/widgets/grid_layout.dart';

/// One store category tab: a "You Might Like" grid of REAL backend
/// products for the category. Shows an honest empty state when the
/// category has no (image-bearing) products instead of fabricating cards.
class CategoryTab extends StatelessWidget {
  const CategoryTab({super.key, required this.categoryTabModel});

  final CategoryTabModel categoryTabModel;

  @override
  Widget build(BuildContext context) {
    // A card cannot render without an image: only image-bearing rows
    // reach the grid. The count shown is always the real visible count.
    final products = categoryTabModel.products
        .where((p) => p.images.isNotEmpty)
        .toList();

    return Padding(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      child: SingleChildScrollView(
        child: Column(
          children: [
            SectionHeading(
              sectionHeadingModel: SectionHeadingModel(
                title: 'You Might Like',
                showActionButton: true,
                actionButtonOnPressed: () {},
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwItems),
            if (products.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(
                  vertical: TSizes.spaceBtwSections,
                ),
                child: Text(
                  'No products in this category yet.',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              )
            else
              GridLayout(
                gridLayoutModel: GridLayoutModel(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return VerticalProductCard(product: products[index]);
                  },
                  // Taller than the legacy 280 extent so real two-line
                  // product titles never overflow the card.
                  mainAxisExtent: 300,
                ),
              ),
            const SizedBox(height: TSizes.spaceBtwSections),
          ],
        ),
      ),
    );
  }
}
