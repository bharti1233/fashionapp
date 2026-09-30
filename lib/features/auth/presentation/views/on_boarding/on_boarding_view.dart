import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:t_store/core/utils/constants/image_strings.dart';
import 'package:t_store/core/utils/constants/text_strings.dart';
import 'package:t_store/core/utils/helpers/main_navigation.dart';
import 'package:t_store/core/utils/logging/app_log_entry.dart';
import 'package:t_store/core/utils/logging/app_logger.dart';
import 'package:t_store/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:t_store/features/auth/presentation/cubit/auth_state.dart';
import 'package:t_store/features/auth/presentation/view_models/on_boarding_model.dart';
import 'package:t_store/features/auth/presentation/logic/on_boarding/on_boarding_cubit.dart';
import 'package:t_store/features/auth/presentation/widgets/on_boarding_dot_navigation.dart';
import 'package:t_store/features/auth/presentation/widgets/on_boarding_next_button.dart';
import 'package:t_store/features/auth/presentation/widgets/on_boarding_page.dart';
import 'package:t_store/features/auth/presentation/widgets/on_boarding_skip_button.dart';

/// First screen. Restores any existing Supabase session on startup:
/// an already-authenticated user skips onboarding and lands directly
/// in the main app. Logged-out users see onboarding as before.
class OnBoardingView extends StatefulWidget {
  const OnBoardingView({super.key});

  @override
  State<OnBoardingView> createState() => _OnBoardingViewState();
}

class _OnBoardingViewState extends State<OnBoardingView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppLogger.instance.info(
        message: 'Session restoration check started',
        category: LogCategory.authentication,
        event: 'SESSION_RESTORE_START',
        screen: 'OnBoardingView',
        operation: 'checkAuthStatus',
      );
      context.read<AuthCubit>().checkAuthStatus();
    });
  }

  void _onAuthState(BuildContext context, AuthState state) {
    if (state is AuthAuthenticated) {
      AppLogger.instance.info(
        message: 'Existing session restored for ${state.user.email}',
        category: LogCategory.authentication,
        event: 'SESSION_RESTORE_SUCCESS',
        screen: 'OnBoardingView',
        operation: 'checkAuthStatus',
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => buildMainNavigation()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: _onAuthState,
      child: BlocBuilder<OnBoardingCubit, OnBoardingState>(
        builder: (context, state) {
          final onBoardingCubit = context.read<OnBoardingCubit>();
          final pageController = onBoardingCubit.pageController;
          return Scaffold(
            body: Stack(
              children: [
                PageView(
                  controller: pageController,
                  onPageChanged: (index) {
                    context.read<OnBoardingCubit>().updatePageIndicator(index);
                  },
                  physics: const BouncingScrollPhysics(),
                  children: [
                    OnBoardingPage(
                      onBoardingModel: OnBoardingModel(
                        image: TImages.onBoardingImage1,
                        title: TTexts.onBoardingTitle1,
                        subTitle: TTexts.onBoardingSubTitle1,
                      ),
                    ),
                    OnBoardingPage(
                      onBoardingModel: OnBoardingModel(
                        image: TImages.onBoardingImage2,
                        title: TTexts.onBoardingTitle2,
                        subTitle: TTexts.onBoardingSubTitle2,
                      ),
                    ),
                    OnBoardingPage(
                      onBoardingModel: OnBoardingModel(
                        image: TImages.onBoardingImage3,
                        title: TTexts.onBoardingTitle3,
                        subTitle: TTexts.onBoardingSubTitle3,
                      ),
                    ),
                  ],
                ),
                const OnBoardingSkipButton(),
                const OnBoardingDotNavigation(),
                const OnBoardingNextButton(),
              ],
            ),
          );
        },
      ),
    );
  }
}
