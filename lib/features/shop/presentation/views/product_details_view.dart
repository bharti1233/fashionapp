import 'package:flutter/material.dart';
import 'package:t_store/core/utils/constants/sizes.dart';
import 'package:t_store/features/shop/domain/entities/product_entity.dart';
import 'package:t_store/features/shop/presentation/widgets/bottom_add_to_cart.dart';
import 'package:t_store/features/shop/presentation/widgets/checkout_button.dart';
import 'package:t_store/features/shop/presentation/widgets/product_attributes.dart';
import 'package:t_store/features/shop/presentation/widgets/product_description_section.dart';
import 'package:t_store/features/shop/presentation/widgets/product_image_slider.dart';
import 'package:t_store/features/shop/presentation/widgets/product_metadata.dart';
import 'package:t_store/features/shop/presentation/widgets/rating_and_share.dart';

/// Product details for a REAL backend product.
///
/// Holds the selected variant attributes so they flow into the cart.
/// Every section below renders [product] data — nothing static.
class ProductDetailsView extends StatefulWidget {
  final ProductEntity product;

  const ProductDetailsView({super.key, required this.product});

  @override
  State<ProductDetailsView> createState() => _ProductDetailsViewState();
}

class _ProductDetailsViewState extends State<ProductDetailsView> {
  Map<String, dynamic> _selectedAttributes = {};

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return Scaffold(
      bottomNavigationBar: BottomAddToCart(
        product: product,
        selectedAttributes: _selectedAttributes,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              ProductImageSlider(
                images: product.images.isNotEmpty
                    ? product.images
                    : [if (product.thumbnail != null) product.thumbnail!],
                productId: product.id,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TSizes.defaultSpace,
                  0,
                  TSizes.defaultSpace,
                  TSizes.defaultSpace,
                ),
                child: Column(
                  children: [
                    RatingAndShare(
                      rating: product.rating,
                      reviewsCount: product.reviewsCount,
                    ),
                    ProductMetadata(product: product),
                    ProductAttributes(
                      product: product,
                      onAttributesChanged: (selection) {
                        setState(() => _selectedAttributes = selection);
                      },
                    ),
                    const SizedBox(height: TSizes.spaceBtwSections),
                    const CheckoutButton(),
                    const SizedBox(height: TSizes.spaceBtwSections),
                    ProductDescriptionAndReviewsSection(product: product),
                    const SizedBox(height: TSizes.spaceBtwSections),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
