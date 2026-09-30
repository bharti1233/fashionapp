import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:t_store/core/common/view_models/app_bar_view_model.dart';
import 'package:t_store/core/common/view_models/cart_counter_icon_view_model.dart';
import 'package:t_store/core/common/view_models/category_tab_view_model.dart';
import 'package:t_store/core/common/view_models/tab_bar_view_model.dart';
import 'package:t_store/core/common/widgets/app_bar.dart';
import 'package:t_store/core/common/widgets/cart_counter_icon.dart';
import 'package:t_store/core/common/widgets/category_tab.dart';
import 'package:t_store/core/common/widgets/tab_bar.dart';
import 'package:t_store/core/utils/constants/colors.dart';
import 'package:t_store/core/utils/constants/sizes.dart';
import 'package:t_store/core/utils/helpers/helper_functions.dart';
import 'package:t_store/core/utils/logging/app_log_entry.dart';
import 'package:t_store/core/utils/logging/app_logger.dart';
import 'package:t_store/features/shop/domain/entities/category_entity.dart';
import 'package:t_store/features/shop/domain/entities/product_entity.dart';
import 'package:t_store/features/shop/presentation/cubit/brands_cubit.dart';
import 'package:t_store/features/shop/presentation/cubit/brands_state.dart';
import 'package:t_store/features/shop/presentation/cubit/categories_cubit.dart';
import 'package:t_store/features/shop/presentation/cubit/categories_state.dart';
import 'package:t_store/features/shop/presentation/cubit/products_cubit.dart';
import 'package:t_store/features/shop/presentation/cubit/products_state.dart';
import 'package:t_store/features/shop/presentation/views/cart_view.dart';

/// Store screen backed entirely by Supabase.
///
/// Tabs come from real categories; each tab shows real products filtered
/// by category. Loading / error (with retry) / empty states are shown
/// honestly — nothing is fabricated when the backend has no data.
class StoreView extends StatefulWidget {
  const StoreView({super.key});

  @override
  State<StoreView> createState() => _StoreViewState();
}

class _StoreViewState extends State<StoreView> {
  bool _loggedSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  void _loadAll() {
    _loggedSuccess = false;
    AppLogger.instance.info(
      message: 'Store loading started',
      category: LogCategory.products,
      event: 'STORE_LOAD_START',
      screen: 'StoreView',
      operation: 'loadStore',
    );
    context.read<CategoriesCubit>().getCategories();
    context.read<BrandsCubit>().getBrands();
    context.read<ProductsCubit>().getProducts(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: CustomAppBar(
        appBarModel: AppBarModel(
          title: Text(
            'Store',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          actions: [
            CartCounterIcon(
              cartCounterIconModel: CartCounterIconModel(
                onPressed: () {
                  THelperFunctions.navigateToScreen(context, const CartView());
                },
                color: dark ? TColors.white : TColors.dark,
              ),
            ),
          ],
        ),
      ),
      body: BlocBuilder<CategoriesCubit, CategoriesState>(
        builder: (context, categoryState) {
          if (categoryState is CategoriesLoading ||
              categoryState is CategoriesInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (categoryState is CategoriesError) {
            return _ErrorState(
              message: categoryState.message,
              onRetry: _loadAll,
            );
          }
          final categories = (categoryState as CategoriesLoaded).categories;
          if (categories.isEmpty) {
            return const Center(
              child: Text(
                'No categories available yet.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }
          return BlocBuilder<ProductsCubit, ProductsState>(
            builder: (context, productState) {
              if (productState is ProductsLoading ||
                  productState is ProductsInitial) {
                return const Center(child: CircularProgressIndicator());
              }
              if (productState is ProductsError) {
                return _ErrorState(
                  message: productState.message,
                  onRetry: _loadAll,
                );
              }
              final products = _allProducts(productState);
              return BlocBuilder<BrandsCubit, BrandsState>(
                builder: (context, brandState) {
                  if (brandState is BrandsLoading ||
                      brandState is BrandsInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (brandState is BrandsError) {
                    return _ErrorState(
                      message: brandState.message,
                      onRetry: _loadAll,
                    );
                  }
                  if (!_loggedSuccess) {
                    _loggedSuccess = true;
                    AppLogger.instance.debug(
                      message:
                          'Store loaded: ${categories.length} categories, '
                          '${products.length} products',
                      category: LogCategory.products,
                      event: 'STORE_LOAD_SUCCESS',
                      screen: 'StoreView',
                      operation: 'loadStore',
                    );
                  }
                  return DefaultTabController(
                    length: categories.length,
                    initialIndex: 0,
                    child: NestedScrollView(
                      headerSliverBuilder: (context, innerBoxIsScrolled) {
                        return [
                          SliverAppBar(
                            pinned: true,
                            floating: true,
                            automaticallyImplyLeading: false,
                            backgroundColor: Theme.of(
                              context,
                            ).scaffoldBackgroundColor,
                            bottom: CustomTabBar(
                              tabBarModel: TabBarModel(
                                labelColor: dark
                                    ? TColors.white
                                    : TColors.primary,
                                tabs: categories
                                    .map((c) => Tab(text: c.name))
                                    .toList(),
                              ),
                            ),
                          ),
                        ];
                      },
                      body: TabBarView(
                        children: categories
                            .map(
                              (category) => CategoryTab(
                                categoryTabModel: CategoryTabModel(
                                  categoryTitle: category.name,
                                  products: _productsFor(products, category),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// Products currently held by the cubit (all pages loaded so far).
  List<ProductEntity> _allProducts(ProductsState state) {
    if (state is ProductsLoaded) return state.products;
    if (state is ProductsSearchResult) return state.products;
    return const [];
  }

  /// Real products belonging to [category], client-side filtered.
  List<ProductEntity> _productsFor(
    List<ProductEntity> products,
    CategoryEntity category,
  ) {
    return products.where((p) => p.categoryId == category.id).toList();
  }
}

/// Honest error state with retry — never fake content on failure.
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Could not load the store.\n$message',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('RETRY'),
            ),
          ],
        ),
      ),
    );
  }
}
