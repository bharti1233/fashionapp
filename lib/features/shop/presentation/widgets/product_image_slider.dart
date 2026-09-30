import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:t_store/core/common/view_models/app_bar_view_model.dart';
import 'package:t_store/core/common/view_models/circular_icon_view_model.dart';
import 'package:t_store/core/common/view_models/rounded_image_view_model.dart';
import 'package:t_store/core/common/widgets/app_bar.dart';
import 'package:t_store/core/common/widgets/circular_icon.dart';
import 'package:t_store/core/common/widgets/curved_widget.dart';
import 'package:t_store/core/common/widgets/rounded_image.dart';
import 'package:t_store/core/utils/constants/colors.dart';
import 'package:t_store/core/utils/helpers/helper_functions.dart';import 'package:t_store/features/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:t_store/features/wishlist/presentation/cubit/wishlist_state.dart';

/// Product image gallery for REAL backend image URLs with the wishlist
/// heart wired to [WishlistCubit] for the shown product.
class ProductImageSlider extends StatelessWidget {
  final List<String> images;
  final String productId;

  const ProductImageSlider({
    super.key,
    required this.images,
    required this.productId,
  });

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final displayImages = images.isNotEmpty ? images : const [''];

    return CurvedWidget(
      child: Container(
        decoration: BoxDecoration(
          color: dark ? TColors.darkGrey : TColors.light,
        ),
        child: Stack(
          children: [
            SizedBox(
              height: 400,
              child: PageView.builder(
                itemCount: displayImages.length,
                itemBuilder: (context, index) {
                  final url = displayImages[index];
                  if (url.isEmpty) {
                    return const Center(
                      child: Icon(Iconsax.image, size: 64, color: Colors.grey),
                    );
                  }
                  return RoundedImage(
                    roundedImageModel: RoundedImageModel(
                      image: url,
                      isNetworkImage: true,
                      fit: BoxFit.contain,
                    ),
                  );
                },
              ),
            ),
            CustomAppBar(
              appBarModel: AppBarModel(
                hasArrowBack: true,
                actions: [
                  BlocBuilder<WishlistCubit, WishlistState>(
                    builder: (context, state) {
                      final saved = context.read<WishlistCubit>().isInWishlist(
                        productId,
                      );
                      return CircularIcon(
                        circularIconModel: CircularIconModel(
                          icon: saved ? Iconsax.heart5 : Iconsax.heart,
                          color: Colors.red,
                          onPressed: () => context
                              .read<WishlistCubit>()
                              .toggleWishlist(productId),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
