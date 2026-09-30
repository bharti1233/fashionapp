import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:t_store/core/common/view_models/app_bar_view_model.dart';
import 'package:t_store/core/common/view_models/circular_icon_view_model.dart';
import 'package:t_store/core/common/view_models/grid_layout_view_model.dart';
import 'package:t_store/core/common/widgets/app_bar.dart';
import 'package:t_store/core/common/widgets/circular_icon.dart';
import 'package:t_store/core/common/widgets/vertical_product_card.dart';
import 'package:t_store/core/cubits/navigation_menu_cubit/navigation_menu_cubit.dart';
import 'package:t_store/core/utils/constants/colors.dart';
import 'package:t_store/core/utils/constants/sizes.dart';
import 'package:t_store/core/utils/constants/text_strings.dart';
import 'package:t_store/core/utils/helpers/helper_functions.dart';
import 'package:t_store/core/utils/logging/app_log_entry.dart';
import 'package:t_store/core/utils/logging/app_logger.dart';
import 'package:t_store/features/auth/presentation/widgets/grid_layout.dart';
import 'package:t_store/features/wishlist/domain/entities/wishlist_item_entity.dart';
import 'package:t_store/features/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:t_store/features/wishlist/presentation/cubit/wishlist_state.dart';

/// Wishlist screen backed by Supabase through [WishlistCubit].
///
/// Shows loading, sign-in-required, empty, loaded, and error (with retry)
/// states honestly. Items render their real product data; the delete
/// action removes them for real. Nothing is fabricated.
class WishlistView extends StatefulWidget {
  const WishlistView({super.key});

  @override
  State<WishlistView> createState() => _WishlistViewState();
}

class _WishlistViewState extends State<WishlistView> {
  bool _loggedSuccess = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _loggedSuccess = false;
    AppLogger.instance.info(
      message: 'Wishlist loading started',
      category: LogCategory.wishlist,
      event: 'WISHLIST_LOAD_START',
      screen: 'WishlistView',
      operation: 'loadWishlist',
    );
    context.read<WishlistCubit>().getWishlist();
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Scaffold(
      appBar: CustomAppBar(
        appBarModel: AppBarModel(
          actions: [
            CircularIcon(
              circularIconModel: CircularIconModel(
                color: dark ? TColors.white : TColors.dark,
                icon: Iconsax.add,
                onPressed: () =>
                    context.read<NavigationMenuCubit>().changeIndex(0),
              ),
            ),
          ],
          title: Text(
            TTexts.wishlistView,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<WishlistCubit, WishlistState>(
          builder: (context, state) {
            if (state is WishlistLoading ||
                state is WishlistInitial ||
                state is WishlistItemAdded ||
                state is WishlistItemRemoved) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is WishlistError) {
              final needsAuth = state.message.contains('sign in');
              return _MessageState(
                icon: needsAuth ? Iconsax.user_octagon : Iconsax.heart_slash,
                message: state.message,
                actionLabel: needsAuth ? null : 'RETRY',
                onAction: needsAuth ? null : _load,
              );
            }
            final items = _visibleItems(state);
            if (items.isEmpty) {
              return const _MessageState(
                icon: Iconsax.heart,
                message:
                    'Your wishlist is empty.\nTap the heart on any '
                    'product to save it here.',
              );
            }
            if (!_loggedSuccess) {
              _loggedSuccess = true;
              AppLogger.instance.debug(
                message: 'Wishlist loaded: ${items.length} items',
                category: LogCategory.wishlist,
                event: 'WISHLIST_LOAD_SUCCESS',
                screen: 'WishlistView',
                operation: 'loadWishlist',
              );
            }
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(TSizes.defaultSpace),
                child: Column(
                  children: [
                    GridLayout(
                      gridLayoutModel: GridLayoutModel(
                        itemCount: items.length,
                        // Taller than the legacy 280 extent so real two-line
                        // product titles never overflow the card.
                        mainAxisExtent: 300,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Stack(
                            children: [
                              VerticalProductCard(product: item.product!),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.black54,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    iconSize: 16,
                                    icon: const Icon(
                                      Iconsax.trash,
                                      color: Colors.white,
                                    ),
                                    tooltip: 'Remove from wishlist',
                                    onPressed: () => context
                                        .read<WishlistCubit>()
                                        .removeFromWishlist(item.productId),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Items whose joined product row exists and can render a card.
  List<WishlistItemEntity> _visibleItems(WishlistState state) {
    if (state is WishlistLoaded) {
      return state.items.where((i) => i.product != null).toList();
    }
    return const [];
  }
}

/// Honest message state (empty / sign-in-required / error).
class _MessageState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
