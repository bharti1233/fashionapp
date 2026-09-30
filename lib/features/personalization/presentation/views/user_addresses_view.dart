import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:t_store/core/common/view_models/app_bar_view_model.dart';
import 'package:t_store/core/common/widgets/app_bar.dart';
import 'package:t_store/core/utils/constants/colors.dart';
import 'package:t_store/core/utils/constants/sizes.dart';
import 'package:t_store/core/utils/helpers/helper_functions.dart';
import 'package:t_store/core/utils/logging/app_log_entry.dart';
import 'package:t_store/core/utils/logging/app_logger.dart';
import 'package:t_store/features/personalization/domain/entities/address_entity.dart';
import 'package:t_store/features/personalization/presentation/cubit/addresses_cubit.dart';
import 'package:t_store/features/personalization/presentation/cubit/addresses_state.dart';
import 'package:t_store/features/personalization/presentation/view_models/single_address_model.dart';
import 'package:t_store/features/personalization/presentation/views/add_new_addresses_view.dart';
import 'package:t_store/features/personalization/presentation/widgets/single_address.dart';

/// Address list backed by Supabase through [AddressesCubit].
///
/// Renders the user's real addresses (name, phone, full address from the
/// backend). Loading / empty / error (with retry) states are honest —
/// no placeholder identities or phone numbers.
///
/// In [selectMode] (used from checkout), tapping an address marks it as
/// the default delivery address and closes the screen with `true`, so
/// the caller can refresh.
class UserAddressesView extends StatefulWidget {
  final bool selectMode;

  const UserAddressesView({super.key, this.selectMode = false});

  @override
  State<UserAddressesView> createState() => _UserAddressesViewState();
}

class _UserAddressesViewState extends State<UserAddressesView> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    AppLogger.instance.info(
      message: 'Addresses loading started',
      category: LogCategory.addresses,
      event: 'ADDRESSES_LOAD_START',
      screen: 'UserAddressesView',
      operation: 'loadAddresses',
    );
    context.read<AddressesCubit>().getAddresses();
  }

  /// Select-mode tap: mark the tapped address as default (updating the
  /// SAME record — never inserting a duplicate) and return to checkout.
  /// Failures remain visible as the cubit's error state and are logged;
  /// checkout reloads authoritative state on return either way.
  Future<void> _selectAddress(AddressEntity address) async {
    if (address.isDefault) {
      if (mounted) Navigator.of(context).pop(true);
      return;
    }
    AppLogger.instance.info(
      message: 'Default address selection started',
      category: LogCategory.addresses,
      event: 'ADDRESS_SELECT_START',
      screen: 'UserAddressesView',
      operation: 'selectAddress',
    );
    await context.read<AddressesCubit>().updateAddress(
      id: address.id,
      fullName: address.fullName,
      phone: address.phone,
      addressLine1: address.addressLine1,
      addressLine2: address.addressLine2,
      city: address.city,
      state: address.state,
      postalCode: address.postalCode,
      country: address.country,
      isDefault: true,
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: TColors.primary,
        onPressed: () {
          THelperFunctions.navigateToScreen(
            context,
            const AddNewAddressesView(),
          );
        },
        child: const Icon(Iconsax.add, color: TColors.white),
      ),
      appBar: CustomAppBar(
        appBarModel: AppBarModel(
          hasArrowBack: true,
          title: Text(
            'Addresses',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<AddressesCubit, AddressesState>(
          builder: (context, state) {
            if (state is AddressesLoading || state is AddressesInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is AddressesError) {
              return _AddressesMessage(
                icon: Iconsax.location_slash,
                message: state.message,
                actionLabel: 'RETRY',
                onAction: _load,
              );
            }
            final addresses = _visibleAddresses(state);
            if (addresses.isEmpty) {
              return const _AddressesMessage(
                icon: Iconsax.location,
                message:
                    'No addresses saved yet.\n'
                    'Tap + to add your first delivery address.',
              );
            }
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(TSizes.defaultSpace),
                child: Column(
                  children: [
                    if (widget.selectMode)
                      const Padding(
                        padding: EdgeInsets.only(bottom: TSizes.spaceBtwItems),
                        child: Text(
                          'Tap an address to use it for this order.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    for (final address in addresses)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: TSizes.spaceBtwItems,
                        ),
                        child: GestureDetector(
                          onTap: widget.selectMode
                              ? () => _selectAddress(address)
                              : null,
                          behavior: HitTestBehavior.opaque,
                          child: SingleAddress(
                            singleAddressModel: SingleAddressModel(
                              name: address.fullName,
                              phoneNumber: address.phone,
                              address: address.fullAddress,
                              isSelected: address.isDefault,
                            ),
                          ),
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

  List<AddressEntity> _visibleAddresses(AddressesState state) {
    if (state is AddressesLoaded) return state.addresses;
    return const [];
  }
}

class _AddressesMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _AddressesMessage({
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
