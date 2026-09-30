import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:t_store/core/common/view_models/app_bar_view_model.dart';
import 'package:t_store/core/common/widgets/app_bar.dart';
import 'package:t_store/core/utils/constants/colors.dart';
import 'package:t_store/core/utils/constants/sizes.dart';
import 'package:t_store/core/utils/logging/app_log_entry.dart';
import 'package:t_store/core/utils/logging/app_logger.dart';
import 'package:t_store/features/auth/domain/entities/user_entity.dart';
import 'package:t_store/features/personalization/presentation/cubit/profile_cubit.dart';
import 'package:t_store/features/personalization/presentation/cubit/profile_state.dart';
import 'package:t_store/features/personalization/presentation/view_models/profile_entity_tile_model.dart';
import 'package:t_store/features/personalization/presentation/widgets/personal_information_section.dart';
import 'package:t_store/features/personalization/presentation/widgets/profile_information_section.dart';

/// Profile screen backed by Supabase through [ProfileCubit].
///
/// Shows the authenticated user's real profile data. Fields the backend
/// does not store (e.g. gender, date of birth) are NOT shown at all —
/// inventing them would be fabrication. Account deletion has no backend
/// yet, so the button explains that honestly instead of pretending.
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    AppLogger.instance.info(
      message: 'Profile loading started',
      category: LogCategory.profile,
      event: 'PROFILE_LOAD_START',
      screen: 'ProfileView',
      operation: 'loadProfile',
    );
    context.read<ProfileCubit>().getProfile();
  }

  void _showDeleteAccountNotice() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'Account deletion is not available in the app yet. '
            'Please contact support to delete your account.',
          ),
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
    return Scaffold(
      appBar: CustomAppBar(
        appBarModel: AppBarModel(
          title: const Text('Profile'),
          hasArrowBack: true,
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading ||
                state is ProfileInitial ||
                state is ProfileUpdating ||
                state is AvatarUploading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ProfileError) {
              return _ProfileMessage(
                icon: Iconsax.user_octagon,
                message: state.message,
                actionLabel: 'RETRY',
                onAction: _load,
              );
            }
            final user = _currentUser(state);
            if (user == null) {
              return _ProfileMessage(
                icon: Iconsax.user,
                message: 'No profile found for this account yet.',
                actionLabel: 'RETRY',
                onAction: _load,
              );
            }
            final profileInformation = [
              ProfileEntityTileModel(
                title: 'Name',
                value: user.fullName?.isNotEmpty == true
                    ? user.fullName!
                    : 'Not set',
                onTap: () {},
              ),
            ];
            final personalInformation = [
              ProfileEntityTileModel(
                trailing: Iconsax.copy,
                title: 'User ID',
                value: user.id,
                onTap: () {
                  Clipboard.setData(ClipboardData(text: user.id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User ID copied')),
                  );
                },
              ),
              ProfileEntityTileModel(title: 'Email', value: user.email),
              ProfileEntityTileModel(
                title: 'Phone Number',
                value: user.phone?.isNotEmpty == true ? user.phone! : 'Not set',
              ),
            ];
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(TSizes.defaultSpace),
                child: Column(
                  children: [
                    ProfileInformationSection(
                      profileInformation: profileInformation,
                    ),
                    const SpaceBetweenSectionsWithDivider(),
                    PersonalInformationSection(
                      personalInformation: personalInformation,
                    ),
                    const SpaceBetweenSectionsWithDivider(),
                    TextButton(
                      onPressed: _showDeleteAccountNotice,
                      child: const Text(
                        'Delete Account',
                        style: TextStyle(color: TColors.error),
                      ),
                    ),
                    const SizedBox(height: TSizes.spaceBtwItems / 1.5),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  UserEntity? _currentUser(ProfileState state) {
    if (state is ProfileLoaded) return state.user;
    if (state is ProfileUpdated) return state.user;
    return null;
  }
}

class SpaceBetweenSectionsWithDivider extends StatelessWidget {
  const SpaceBetweenSectionsWithDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: TSizes.spaceBtwItems / 1.5),
        Divider(),
        SizedBox(height: TSizes.spaceBtwItems / 1.5),
      ],
    );
  }
}

class _ProfileMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _ProfileMessage({
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
