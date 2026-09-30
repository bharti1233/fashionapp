import 'package:t_store/features/shop/domain/entities/product_entity.dart';

/// Data for one store category tab. All values come from the backend —
/// products are real Supabase rows filtered by category, never fabricated.
class CategoryTabModel {
  final List<ProductEntity> products;
  final String categoryTitle;

  CategoryTabModel({required this.products, required this.categoryTitle});
}
