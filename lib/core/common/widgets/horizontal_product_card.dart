import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:t_store/core/common/view_models/circular_icon_view_model.dart';
import 'package:t_store/core/common/view_models/circular_container_view_model.dart';
import 'package:t_store/core/common/view_models/product_price_text_view_model.dart';
import 'package:t_store/core/common/view_models/product_title_text_view_model.dart';
import 'package:t_store/core/common/view_models/rounded_image_view_model.dart';
import 'package:t_store/core/common/widgets/brand_title_with_verification.dart';
import 'package:t_store/core/common/view_models/brand_title_with_verification_view_model.dart';
import 'package:t_store/core/common/widgets/circular_container.dart';
import 'package:t_store/core/common/widgets/circular_icon.dart';
import 'package:t_store/core/common/widgets/product_price_text.dart';
import 'package:t_store/core/common/widgets/product_title_text.dart';
import 'package:t_store/core/common/widgets/rounded_image.dart';
import 'package:t_store/core/common/widgets/sale_tag.dart';
import 'package:t_store/core/utils/constants/colors.dart';
import 'package:t_store/core/utils/constants/sizes.dart';
import 'package:t_store/core/utils/helpers/helper_functions.dart';
import 'package:t_store/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:t_store/features/shop/domain/entities/product_entity.dart';
import 'package:t_store/features/shop/presentation/views/product_details_view.dart';
import 'package:t_store/features/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:t_store/core/utils/formatters/formatter.dart';

/// Horizontal product card for a REAL backend [product].
/// Tap opens real details; heart toggles the real wishlist; + adds one
/// unit to the real cart.
class HorizontalProductCard extends StatelessWidget {
  final ProductEntity product;

  const HorizontalProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final image = product.images.isNotEmpty
        ? product.images.first
        : product.thumbnail ?? '';
    final discount = product.salePrice != null && product.price > 0
        ? ((product.price - product.salePrice!) / product.price * 100).round()
        : 0;
    return GestureDetector(
      onTap: () {
        THelperFunctions.navigateToScreen(
          context,
          ProductDetailsView(product: product),
        );
      },
      child: Container(
        width: 310,
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(
            Radius.circular(TSizes.productImageRadius),
          ),
          color: dark ? TColors.darkerGrey : TColors.lightContainer,
        ),
        child: Row(
          children: [
            CircularContainer(
              circularContainerModel: CircularContainerModel(
                padding: const EdgeInsets.all(TSizes.sm),
                height: 120,
                color: dark ? TColors.dark : TColors.light,
                child: Stack(
                  children: [
                    SizedBox(
                      height: 120,
                      width: 120,
                      child: RoundedImage(
                        roundedImageModel: RoundedImageModel(
                          applyImageRadius: true,
                          backgroundColor: dark ? TColors.dark : TColors.light,
                          image: image,
                          isNetworkImage: image.isNotEmpty,
                        ),
                      ),
                    ),
                    if (discount > 0)
                      Positioned(
                        top: 12,
                        child: SaleTag(discountPercentage: discount.toDouble()),
                      ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: CircularIcon(
                        circularIconModel: CircularIconModel(
                          icon:
                              context.watch<WishlistCubit>().isInWishlist(
                                product.id,
                              )
                              ? Iconsax.heart5
                              : Iconsax.heart,
                          color: Colors.red,
                          onPressed: () => context
                              .read<WishlistCubit>()
                              .toggleWishlist(product.id),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 172,
              child: Padding(
                padding: const EdgeInsets.only(top: TSizes.sm, left: TSizes.sm),
                child: Column(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProductTitleText(
                          productTitleTextModel: ProductTitleTextModel(
                            title: product.name,
                            smallSize: true,
                          ),
                        ),
                        const SizedBox(height: TSizes.spaceBtwItems / 2),
                        if ((product.brandName ?? '').isNotEmpty)
                          BrandTitleWithVerification(
                            brandTitleWithVerificationModel:
                                BrandTitleWithVerificationModel(
                                  brandName: product.brandName!,
                                ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: ProductPriceText(
                            productPriceTextModel: ProductPriceTextModel(
                              price: TFormatter.formatAmount(
                                product.effectivePrice,
                              ),
                              smallSize: true,
                            ),
                          ),
                        ),
                        Builder(
                          builder: (iconContext) {
                            return IconButton(
                              onPressed: () => iconContext
                                  .read<CartCubit>()
                                  .addToCart(productId: product.id),
                              icon: const Icon(Iconsax.add),
                              color: TColors.white,
                              style: IconButton.styleFrom(
                                backgroundColor: TColors.primary,
                              ),
                              tooltip: 'Add to cart',
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
