import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:t_store/core/common/view_models/app_bar_view_model.dart';
import 'package:t_store/core/common/view_models/rounded_image_view_model.dart';
import 'package:t_store/core/common/view_models/section_heading_view_model.dart';
import 'package:t_store/core/common/widgets/app_bar.dart';
import 'package:t_store/core/common/widgets/horizontal_product_card.dart';
import 'package:t_store/core/common/widgets/rounded_image.dart';
import 'package:t_store/core/common/widgets/section_heading.dart';
import 'package:t_store/core/utils/constants/image_strings.dart';
import 'package:t_store/core/utils/constants/sizes.dart';
import 'package:t_store/core/utils/logging/app_log_entry.dart';
import 'package:t_store/core/utils/logging/app_logger.dart';
import 'package:t_store/features/shop/domain/entities/product_entity.dart';
import 'package:t_store/features/shop/presentation/cubit/products_cubit.dart';
import 'package:t_store/features/shop/presentation/cubit/products_state.dart';

/// Sub-category product rail for a REAL backend category.
/// Products are loaded from Supabase filtered by [categoryId].
class SubCategoryView extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const SubCategoryView({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<SubCategoryView> createState() => _SubCategoryViewState();
}

class _SubCategoryViewState extends State<SubCategoryView> {
  @override
  void initState() {
    super.initState();
    context.read<ProductsCubit>().getProducts(
      categoryId: widget.categoryId,
      refresh: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        appBarModel: AppBarModel(
          hasArrowBack: true,
          title: Text(widget.categoryName),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(TSizes.defaultSpace),
            child: Column(
              children: [
                RoundedImage(
                  roundedImageModel: RoundedImageModel(
                    image: TImages.promoBanner2,
                    applyImageRadius: true,
                    width: double.infinity,
                  ),
                ),
                const SizedBox(height: TSizes.spaceBtwSections),
                Column(
                  children: [
                    SectionHeading(
                      sectionHeadingModel: SectionHeadingModel(
                        title: widget.categoryName,
                      ),
                    ),
                    const SizedBox(height: TSizes.spaceBtwItems / 2),
                    BlocBuilder<ProductsCubit, ProductsState>(
                      builder: (context, state) {
                        if (state is ProductsLoading ||
                            state is ProductsInitial) {
                          return const SizedBox(
                            height: 128,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (state is ProductsError) {
                          return Text(
                            state.message,
                            style: const TextStyle(color: Colors.grey),
                          );
                        }
                        final products = _forCategory(state);
                        if (products.isEmpty) {
                          return const Text(
                            'No products in this category yet.',
                            style: TextStyle(color: Colors.grey),
                          );
                        }
                        return SizedBox(
                          height: 128,
                          child: ListView.separated(
                            itemCount: products.length,
                            shrinkWrap: true,
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) =>
                                HorizontalProductCard(product: products[index]),
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: TSizes.spaceBtwItems),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<ProductEntity> _forCategory(ProductsState state) {
    final List<ProductEntity> all;
    if (state is ProductsLoaded) {
      all = state.products;
    } else if (state is ProductsSearchResult) {
      all = state.products;
    } else {
      return const [];
    }
    final filtered = all
        .where((p) => p.categoryId == widget.categoryId)
        .toList();
    AppLogger.instance.debug(
      message: 'Sub-category ${widget.categoryName}: ${filtered.length} items',
      category: LogCategory.products,
      event: 'SUBCATEGORY_LOAD_SUCCESS',
      screen: 'SubCategoryView',
      operation: 'loadSubCategory',
    );
    return filtered;
  }
}
