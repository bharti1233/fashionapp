import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:t_store/core/common/widgets/primary_header_container.dart';
import 'package:t_store/core/utils/constants/sizes.dart';
import 'package:t_store/core/utils/helpers/helper_functions.dart';
import 'package:t_store/core/utils/logging/app_logger.dart';
import 'package:t_store/core/utils/logging/app_log_entry.dart';
import 'package:t_store/core/utils/logging/app_logs_screen.dart';
import 'package:t_store/features/notifications/presentation/views/notifications_view.dart';
import 'package:t_store/features/personalization/presentation/cubit/profile_cubit.dart';
import 'package:t_store/features/personalization/presentation/view_models/settings_menu_tile_model.dart';
import 'package:t_store/features/personalization/presentation/views/user_addresses_view.dart';
import 'package:t_store/features/personalization/presentation/widgets/account_settings_section.dart';
import 'package:t_store/features/personalization/presentation/widgets/app_settings_section.dart';
import 'package:t_store/features/personalization/presentation/widgets/settings_view_header_section.dart';
import 'package:t_store/features/shop/presentation/views/cart_view.dart';
import 'package:t_store/features/shop/presentation/views/coupons_view.dart';
import 'package:t_store/features/shop/presentation/views/orders_view.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  @override
  void initState() {
    super.initState();
    // The header shows the real profile: ensure it is loaded.
    context.read<ProfileCubit>().getProfile();
  }

  void _showNotAvailable(BuildContext context, String feature) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(feature),
          content: Text('$feature is not available in the app yet.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('CLOSE'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<SettingsMenuTileModel> appSettingsTiles = [
      SettingsMenuTileModel(
        onTap: () {
          AppLogger.instance.info(
            message: 'User opened App Logs',
            category: LogCategory.system,
            screen: 'Settings',
            operation: 'openAppLogs',
          );
          THelperFunctions.navigateToScreen(context, const AppLogsScreen());
        },
        title: "App Logs",
        subtitle: "View Application Error Logs",
        leading: Iconsax.document_text,
      ),
    ];
    final List<SettingsMenuTileModel> accountSettingsTiles = [
      SettingsMenuTileModel(
        onTap: () {
          //navigateToScreen UserAddressesView
          THelperFunctions.navigateToScreen(context, const UserAddressesView());
        },
        title: "My Addresses",
        subtitle: "Set Shopping Delivery Address",
        leading: Iconsax.safe_home,
      ),
      SettingsMenuTileModel(
        onTap: () {
          THelperFunctions.navigateToScreen(context, const CartView());
        },
        title: "My Cart",
        subtitle: "Add, Remove Products And Move To Checkout",
        leading: Iconsax.shopping_cart,
      ),
      SettingsMenuTileModel(
        onTap: () {
          //navigateToScreen UserAddressesView
          THelperFunctions.navigateToScreen(context, const OrdersView());
        },
        title: "My Orders",
        subtitle: "In-Progress And Completed Orders",
        leading: Iconsax.bag,
      ),
      SettingsMenuTileModel(
        onTap: () {
          THelperFunctions.navigateToScreen(context, const CouponsView());
        },
        title: "My Coupons",
        subtitle: "List Of All Discounted Coupons",
        leading: Iconsax.discount_shape,
      ),
      SettingsMenuTileModel(
        onTap: () {
          THelperFunctions.navigateToScreen(context, const NotificationsView());
        },
        title: "Notifications",
        subtitle: "Set Any Kind Of Notifications Message",
        leading: Iconsax.notification,
      ),
      SettingsMenuTileModel(
        onTap: () => _showNotAvailable(context, 'Account Privacy'),
        title: "Account Privacy",
        subtitle: "Manage Data Usage And Connected Accounts",
        leading: Iconsax.security_card,
      ),
    ];
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const PrimaryHeaderContainer(child: SettingsViewHeaderSection()),
            Padding(
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              child: Column(
                children: [
                  AccountSettingsSection(
                    accountSettingsTiles: accountSettingsTiles,
                  ),
                  const SizedBox(height: TSizes.spaceBtwSections),
                  AppSettingsSection(appSettingsTiles: appSettingsTiles),
                  const SizedBox(height: TSizes.spaceBtwItems),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
