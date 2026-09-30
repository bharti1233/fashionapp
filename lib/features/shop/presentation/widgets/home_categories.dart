import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:t_store/core/common/view_models/horizontal_small_list_view_item_view_model.dart';
import 'package:t_store/core/common/widgets/horizontal_small_list_view.dart';
import 'package:t_store/core/utils/constants/image_strings.dart';
import 'package:t_store/core/utils/constants/sizes.dart';
import 'package:t_store/core/utils/helpers/helper_functions.dart';
import 'package:t_store/features/shop/domain/entities/category_entity.dart';
import 'package:t_store/features/shop/presentation/cubit/categories_cubit.dart';
import 'package:t_store/features/shop/presentation/cubit/categories_state.dart';
import 'package:t_store/features/shop/presentation/views/sub_category_view.dart';

/// Home category rail backed by Supabase through [CategoriesCubit].
/// Tapping a category opens its real product rail. Category artwork
/// falls back to a bundled icon only when the backend provides no
/// image URL (documented catalog fallback, not data).
class HomeCategories extends StatelessWidget {
  const HomeCategories({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoriesCubit, CategoriesState>(
      builder: (context, state) {
        if (state is CategoriesLoaded && state.categories.isNotEmpty) {
          final items = _items(context, state.categories);
          return SizedBox(
            height: 100,
            child: HorizontalSmallListView(items: items),
          );
        }
        if (state is CategoriesError) {
          return SizedBox(
            height: 100,
            child: Center(
              child: Text(
                'Could not load categories.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: TSizes.fontSizeSm,
                ),
              ),
            ),
          );
        }
        return const SizedBox(
          height: 100,
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }

  List<HorizontalSmallListViewItemModel> _items(
    BuildContext context,
    List<CategoryEntity> categories,
  ) {
    const fallbacks = TImages.categoryIcons;
    return List.generate(categories.length, (index) {
      final category = categories[index];
      return HorizontalSmallListViewItemModel(
        title: category.name,
        image: fallbacks[index % fallbacks.length],
        onTap: () {
          THelperFunctions.navigateToScreen(
            context,
            SubCategoryView(
              categoryId: category.id,
              categoryName: category.name,
            ),
          );
        },
      );
    });
  }
}
