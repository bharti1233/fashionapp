import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:t_store/core/common/view_models/app_bar_view_model.dart';
import 'package:t_store/core/common/view_models/cart_counter_icon_view_model.dart';
import 'package:t_store/core/common/widgets/app_bar.dart';
import 'package:t_store/core/common/widgets/cart_counter_icon.dart';
import 'package:t_store/core/utils/constants/colors.dart';
import 'package:t_store/core/utils/constants/text_strings.dart';
import 'package:t_store/core/utils/helpers/helper_functions.dart';
import 'package:t_store/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:t_store/features/auth/presentation/cubit/auth_state.dart';
import 'package:t_store/features/shop/presentation/views/cart_view.dart';

/// Home app bar. The greeting line shows the ACTUAL authenticated user's
/// name (profile full name, else the email local-part) — never a
/// hardcoded identity.
class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomAppBar(
      appBarModel: AppBarModel(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              TTexts.homeAppbarTitle,
              style: Theme.of(
                context,
              ).textTheme.labelMedium!.apply(color: TColors.grey),
            ),
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                return Text(
                  _greetingName(state),
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall!.apply(color: TColors.white),
                );
              },
            ),
          ],
        ),
        actions: [
          CartCounterIcon(
            cartCounterIconModel: CartCounterIconModel(
              color: TColors.white,
              onPressed: () {
                THelperFunctions.navigateToScreen(context, const CartView());
              },
            ),
          ),
        ],
      ),
    );
  }

  String _greetingName(AuthState state) {
    if (state is AuthAuthenticated) {
      final fullName = state.user.fullName?.trim() ?? '';
      if (fullName.isNotEmpty) return fullName;
      final localPart = state.user.email.split('@').first.trim();
      if (localPart.isNotEmpty) return localPart;
    }
    return 'Welcome';
  }
}
