import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:t_store/core/common/view_models/brand_title_with_verification_view_model.dart';
import 'package:t_store/core/common/view_models/circular_container_view_model.dart';
import 'package:t_store/core/common/view_models/circular_icon_view_model.dart';
import 'package:t_store/core/common/view_models/product_price_text_view_model.dart';
import 'package:t_store/core/common/view_models/product_title_text_view_model.dart';
import 'package:t_store/core/common/view_models/rounded_image_view_model.dart';
import 'package:t_store/core/common/widgets/brand_title_with_verification.dart';
import 'package:t_store/core/common/widgets/circular_container.dart';
import 'package:t_store/core/common/widgets/circular_icon.dart';
import 'package:t_store/core/common/widgets/product_price_text.dart';
import 'package:t_store/core/common/widgets/product_title_text.dart';
import 'package:t_store/core/common/widgets/rounded_image.dart';
import 'package:t_store/core/common/widgets/sale_tag.dart';
import 'package:t_store/core/utils/constants/colors.dart';
import 'package:t_store/core/utils/constants/shadow_styles.dart';
import 'package:t_store/core/utils/constants/sizes.dart';
import 'package:t_store/core/utils/formatters/formatter.dart';
import 'package:t_store/core/utils/helpers/helper_functions.dart';
import 'package:t_store/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:t_store/features/cart/presentation/cubit/cart_state.dart';
import 'package:t_store/features/shop/domain/entities/product_entity.dart';
import 'package:t_store/features/shop/presentation/views/product_details_view.dart';
import 'package:t_store/features/wishlist/presentation/cubit/wishlist_cubit.dart';

class VerticalProductCard extends StatelessWidget {
  const VerticalProductCard({super.key, required this.product});
  final ProductEntity product;
  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    // Never crash on imageless rows: fall back to a neutral tile.
    final image = product.images.isNotEmpty
        ? product.images.first
        : (product.thumbnail ?? '');
    final saved = context.watch<WishlistCubit>().isInWishlist(product.id);
    return GestureDetector(
      onTap: () {
        THelperFunctions.navigateToScreen(
          context,
          ProductDetailsView(product: product),
        );
      },
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          boxShadow: [TShadowStyle.verticalProductCardShadow],
          borderRadius: const BorderRadius.all(
            Radius.circular(TSizes.productImageRadius),
          ),
          color: dark ? TColors.darkerGrey : TColors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircularContainer(
              circularContainerModel: CircularContainerModel(
                padding: const EdgeInsets.all(TSizes.sm),
                // 168 (not 180): keeps two-line titles + price row inside
                // the grid extent instead of overflowing it.
                height: 168,
                color: dark ? TColors.dark : TColors.light,
                child: Stack(
                  children: [
                    if (image.isEmpty)
                      const Center(
                        child: Icon(
                          Iconsax.image,
                          size: 48,
                          color: Colors.grey,
                        ),
                      )
                    else
                      RoundedImage(
                        roundedImageModel: RoundedImageModel(
                          isNetworkImage: true,
                          backgroundColor: dark ? TColors.dark : TColors.light,
                          image: image,
                          onTap: () {},
                          applyImageRadius: true,
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (product.hasDiscount)
                          SaleTag(
                            discountPercentage: product.discountPercentage,
                          )
                        else
                          const SizedBox(width: TSizes.iconLg * 1.2),
                        CircularIcon(
                          circularIconModel: CircularIconModel(
                            height: TSizes.iconLg * 1.2,
                            width: TSizes.iconLg * 1.2,
                            iconSize: TSizes.iconMd,
                            icon: saved ? Iconsax.heart5 : Iconsax.heart,
                            color: Colors.red,
                            backgroundColor: dark
                                ? TColors.darkerGrey
                                : TColors.white,
                            onPressed: () => context
                                .read<WishlistCubit>()
                                .toggleWishlist(product.id),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(left: TSizes.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ProductTitleText(
                      productTitleTextModel: ProductTitleTextModel(
                        title: product.name,
                      ),
                    ),
                    const SizedBox(height: TSizes.spaceBtwItems / 2),
                    BrandTitleWithVerification(
                      brandTitleWithVerificationModel:
                          BrandTitleWithVerificationModel(
                            brandName: product.brandName ?? '',
                          ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: ProductPriceText(
                            productPriceTextModel: ProductPriceTextModel(
                              price: TFormatter.formatAmount(
                                product.effectivePrice,
                              ),
                              maxLines: 1,
                              smallSize: true,
                            ),
                          ),
                        ),
                        BlocListener<CartCubit, CartState>(
                          listener: (context, state) {
                            if (state is CartItemAdded) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Added to cart'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                          child: IconButton(
                            iconSize: TSizes.iconMd,
                            color: TColors.white,
                            style: IconButton.styleFrom(
                              backgroundColor: TColors.primary,
                            ),
                            tooltip: 'Add to cart',
                            icon: const Icon(Iconsax.add),
                            onPressed: () => context
                                .read<CartCubit>()
                                .addToCart(productId: product.id),
                          ),
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
