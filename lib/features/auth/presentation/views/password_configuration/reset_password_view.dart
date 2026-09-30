import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:t_store/core/enums/status.dart';
import 'package:t_store/core/utils/constants/image_strings.dart';
import 'package:t_store/core/utils/constants/sizes.dart';
import 'package:t_store/core/utils/constants/text_strings.dart';
import 'package:t_store/core/utils/device/device_utility.dart';
import 'package:t_store/core/utils/helpers/helper_functions.dart';
import 'package:t_store/core/utils/validators/validation.dart';
import 'package:t_store/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:t_store/features/auth/presentation/cubit/auth_state.dart';
import 'package:t_store/features/auth/presentation/views/login/login_view.dart';

/// Reset-password screen wired to Supabase through [AuthCubit].
///
/// Opened from the recovery link (or after the reset email is sent).
/// Done updates the real password — never pretends to. The password
/// values themselves are never logged.
class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({super.key});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _handleDone() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().updatePassword(_passwordController.text);
    }
  }

  void _onAuthState(BuildContext context, AuthState state) {
    if (state is AuthPasswordUpdated) {
      THelperFunctions.showSnackBar(
        context: context,
        message: 'Password updated. Please sign in with the new password.',
        type: SnackBarType.success,
      );
      THelperFunctions.navigateReplacementToScreen(context, const LoginView());
    } else if (state is AuthError) {
      THelperFunctions.showSnackBar(
        context: context,
        message: state.message,
        type: SnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: _onAuthState,
      child: Scaffold(
        appBar: AppBar(
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
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: TSizes.paddingWithAppBarHeight,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Image(
                      width: TDeviceUtils.getScreenWidth(context) * .6,
                      image: const AssetImage(
                        TImages.deliveredEmailIllustration,
                      ),
                    ),
                    const SizedBox(height: TSizes.spaceBtwSections),
                    Text(
                      TTexts.changeYourPasswordTitle,
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: TSizes.spaceBtwItems),
                    Text(
                      TTexts.changeYourPasswordSubTitle,
                      style: Theme.of(context).textTheme.labelMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: TSizes.spaceBtwSections),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      validator: (value) => TValidator.validatePassword(value),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Iconsax.password_check),
                        labelText: TTexts.newPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: TSizes.spaceBtwInputFields),
                    TextFormField(
                      controller: _confirmController,
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Iconsax.password_check),
                        labelText: TTexts.confirmPassword,
                      ),
                    ),
                    const SizedBox(height: TSizes.spaceBtwSections),
                    SizedBox(
                      width: double.infinity,
                      child: BlocBuilder<AuthCubit, AuthState>(
                        builder: (context, state) {
                          final loading = state is AuthLoading;
                          return ElevatedButton(
                            onPressed: loading ? null : _handleDone,
                            child: loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(TTexts.done),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
