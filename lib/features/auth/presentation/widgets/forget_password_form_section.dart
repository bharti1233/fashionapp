import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:t_store/core/enums/status.dart';
import 'package:t_store/core/utils/constants/sizes.dart';
import 'package:t_store/core/utils/constants/text_strings.dart';
import 'package:t_store/core/utils/helpers/helper_functions.dart';
import 'package:t_store/core/utils/validators/validation.dart';
import 'package:t_store/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:t_store/features/auth/presentation/cubit/auth_state.dart';
import 'package:t_store/features/auth/presentation/views/password_configuration/reset_password_view.dart';

/// Forgot-password form wired to Supabase through [AuthCubit].
///
/// Submit sends a real password-reset email; on success the user is taken
/// to the reset screen with confirmation. Failures surface as snackbars
/// and are logged by the cubit.
class ForgetPasswordFormSection extends StatefulWidget {
  const ForgetPasswordFormSection({super.key});

  @override
  State<ForgetPasswordFormSection> createState() =>
      _ForgetPasswordFormSectionState();
}

class _ForgetPasswordFormSectionState extends State<ForgetPasswordFormSection> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().resetPassword(_emailController.text.trim());
    }
  }

  void _onAuthState(BuildContext context, AuthState state) {
    if (state is AuthPasswordResetSent) {
      THelperFunctions.showSnackBar(
        context: context,
        message: 'Password reset email sent to ${state.email}',
        type: SnackBarType.success,
      );
      THelperFunctions.navigateToScreen(context, const ResetPasswordView());
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
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) => TValidator.validateEmail(value),
              decoration: const InputDecoration(
                prefixIcon: Icon(Iconsax.direct_right),
                labelText: TTexts.email,
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwInputFields),
            SizedBox(
              width: double.infinity,
              child: BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  final loading = state is AuthLoading;
                  return ElevatedButton(
                    onPressed: loading ? null : _handleSubmit,
                    child: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(TTexts.submit),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
