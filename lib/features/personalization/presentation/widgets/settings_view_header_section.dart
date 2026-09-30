import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:t_store/core/common/view_models/app_bar_view_model.dart';
import 'package:t_store/core/common/widgets/app_bar.dart';
import 'package:t_store/core/utils/constants/colors.dart';
import 'package:t_store/core/utils/constants/image_strings.dart';
import 'package:t_store/core/utils/constants/sizes.dart';
import 'package:t_store/core/utils/constants/text_strings.dart';
import 'package:t_store/core/utils/helpers/helper_functions.dart';
import 'package:t_store/features/auth/domain/entities/user_entity.dart';
import 'package:t_store/features/personalization/presentation/cubit/profile_cubit.dart';
import 'package:t_store/features/personalization/presentation/cubit/profile_state.dart';
import 'package:t_store/features/personalization/presentation/view_models/user_profile_tile_model.dart';
import 'package:t_store/features/personalization/presentation/views/profile_view.dart';
import 'package:t_store/features/personalization/presentation/widgets/user_profile_tile.dart';

/// Settings header showing the ACTUAL authenticated user (name/email from
/// the Supabase profile). Falls back to neutral placeholders only while
/// loading — never a hardcoded identity.
class SettingsViewHeaderSection extends StatelessWidget {
  const SettingsViewHeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomAppBar(
          appBarModel: AppBarModel(
            title: Text(
              TTexts.account,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium!.apply(color: TColors.white),
            ),
          ),
        ),
        const SizedBox(height: TSizes.spaceBtwSections),
        BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            final user = _currentUser(state);
            return UserProfileTile(
              userProfileTileModel: UserProfileTileModel(
                title: _displayName(user),
                subtitle: user?.email ?? '',
                onTap: () => THelperFunctions.navigateToScreen(
                  context,
                  const ProfileView(),
                ),
                trailing: Iconsax.edit,
                leading: TImages.user,
              ),
            );
          },
        ),
        const SizedBox(height: TSizes.spaceBtwSections * 1.2),
      ],
    );
  }

  UserEntity? _currentUser(ProfileState state) {
    if (state is ProfileLoaded) return state.user;
    if (state is ProfileUpdated) return state.user;
    return null;
  }

  /// Real profile name, else the account email local-part — both from the
  /// authenticated user. Generic "My Account" only while loading.
  String _displayName(UserEntity? user) {
    if (user == null) return 'My Account';
    final fullName = user.fullName?.trim() ?? '';
    if (fullName.isNotEmpty) return fullName;
    final email = user.email;
    final localPart = email.split('@').first.trim();
    if (localPart.isNotEmpty) return localPart;
    return 'My Account';
  }
}
