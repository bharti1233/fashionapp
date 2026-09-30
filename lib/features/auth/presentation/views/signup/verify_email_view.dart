import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:t_store/core/enums/status.dart';
import 'package:t_store/core/utils/constants/image_strings.dart';
import 'package:t_store/core/utils/constants/sizes.dart';
import 'package:t_store/core/utils/constants/text_strings.dart';
import 'package:t_store/core/utils/device/device_utility.dart';
import 'package:t_store/core/utils/helpers/helper_functions.dart';
import 'package:t_store/core/utils/helpers/main_navigation.dart';
import 'package:t_store/core/utils/logging/app_log_entry.dart';
import 'package:t_store/core/utils/logging/app_logger.dart';
import 'package:t_store/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:t_store/features/auth/presentation/cubit/auth_state.dart';
import 'package:t_store/features/auth/presentation/views/login/login_view.dart';

/// Email verification screen for the address the account was created with.
///
/// Continue NEVER pretends verification succeeded: it re-checks the real
/// Supabase session and only proceeds when authenticated. Otherwise the
/// user is told to confirm via the email link first. Resend calls the
/// real Supabase resend-confirmation operation.
class VerifyEmailView extends StatelessWidget {
  final String email;

  const VerifyEmailView({super.key, required this.email});

  void _handleContinue(BuildContext context) {
    AppLogger.instance.info(
      message: 'Email verification check started',
      category: LogCategory.authentication,
      event: 'VERIFY_EMAIL_CHECK_START',
      screen: 'VerifyEmailView',
      operation: 'checkVerification',
    );
    context.read<AuthCubit>().checkAuthStatus();
  }

  void _onAuthState(BuildContext context, AuthState state) {
    if (state is AuthAuthenticated) {
      AppLogger.instance.info(
        message: 'Email verified, session active',
        category: LogCategory.authentication,
        event: 'VERIFY_EMAIL_SUCCESS',
        screen: 'VerifyEmailView',
        operation: 'checkVerification',
      );
      THelperFunctions.navigateReplacementToScreen(
        context,
        buildMainNavigation(),
      );
    } else if (state is AuthUnauthenticated) {
      THelperFunctions.showSnackBar(
        context: context,
        message:
            'Email not confirmed yet. '
            'Open the confirmation link in your inbox, then continue.',
        type: SnackBarType.warning,
      );
    } else if (state is AuthError) {
      THelperFunctions.showSnackBar(
        context: context,
        message: state.message,
        type: SnackBarType.error,
      );
    } else if (state is AuthConfirmationResent) {
      THelperFunctions.showSnackBar(
        context: context,
        message: 'Confirmation email resent to ${state.email}',
        type: SnackBarType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: _onAuthState,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: () {
                THelperFunctions.navigateReplacementToScreen(
                  context,
                  const LoginView(),
                );
              },
              icon: const Icon(CupertinoIcons.clear),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              child: Column(
                children: [
                  Image(
                    width: TDeviceUtils.getScreenWidth(context) * .6,
                    image: const AssetImage(TImages.deliveredEmailIllustration),
                  ),
                  const SizedBox(height: TSizes.spaceBtwSections),
                  Text(
                    TTexts.confirmEmailTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  Text(
                    'We sent a confirmation link to:',
                    style: Theme.of(context).textTheme.labelLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems / 2),
                  Text(
                    email,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  Text(
                    '${TTexts.confirmEmailSubTitle}\n$email',
                    style: Theme.of(context).textTheme.labelMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: TSizes.spaceBtwSections),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _handleContinue(context),
                      child: const Text(TTexts.tContinue),
                    ),
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () =>
                          context.read<AuthCubit>().resendConfirmation(email),
                      child: const Text(TTexts.resendEmail),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
