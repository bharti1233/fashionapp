import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:t_store/core/common/view_models/grid_layout_view_model.dart';
import 'package:t_store/core/common/widgets/product_shimmer.dart';
import 'package:t_store/core/common/widgets/vertical_product_card.dart';
import 'package:t_store/core/utils/constants/sizes.dart';
import 'package:t_store/features/auth/presentation/widgets/grid_layout.dart';
import 'package:t_store/features/shop/presentation/cubit/products_cubit.dart';
import 'package:t_store/features/shop/presentation/cubit/products_state.dart';

/// Fashion product sorting options backed by [ProductsCubit].
const _fashionSortOptions = <String>[
  'Newest',
  'Price: Low to High',
  'Price: High to Low',
  'Top Rated',
];

String _sortFieldFor(String option) {
  switch (option) {
    case 'Price: Low to High':
    case 'Price: High to Low':
      return 'price';
    case 'Top Rated':
      return 'rating';
    case 'Newest':
    default:
      return 'created_at';
  }
}

bool _ascendingFor(String option) => option == 'Price: Low to High';

class SortableProducts extends StatefulWidget {
  const SortableProducts({super.key});

  @override
  State<SortableProducts> createState() => _SortableProductsState();
}

class _SortableProductsState extends State<SortableProducts> {
  String _sortBy = _fashionSortOptions.first;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(prefixIcon: Icon(Iconsax.sort)),
          initialValue: _sortBy,
          items: _fashionSortOptions
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() => _sortBy = value);
            context.read<ProductsCubit>().getProducts(
              sortBy: _sortFieldFor(value),
              ascending: _ascendingFor(value),
              refresh: true,
            );
          },
        ),
        const SizedBox(height: TSizes.spaceBtwSections),
        BlocBuilder<ProductsCubit, ProductsState>(
          builder: (context, state) {
            if (state is ProductsLoaded) {
              return GridLayout(
                gridLayoutModel: GridLayoutModel(
                  itemCount: state.products.length,
                  itemBuilder: (context, index) {
                    return VerticalProductCard(product: state.products[index]);
                  },
                ),
              );
            } else if (state is ProductsError) {
              return Text(state.message);
            }

            return const ProductShimmer();
          },
        ),
      ],
    );
  }
}
