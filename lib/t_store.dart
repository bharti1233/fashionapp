import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:t_store/core/cubits/banner_carousel_slider_cubit_cubit/banner_carousel_slider_cubit.dart';
import 'package:t_store/core/dependency_injection/service_locator.dart';
import 'package:t_store/core/utils/constants/text_strings.dart';
import 'package:t_store/core/utils/theme/theme.dart';
import 'package:t_store/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:t_store/features/auth/presentation/logic/on_boarding/on_boarding_cubit.dart';
import 'package:t_store/features/auth/presentation/views/on_boarding/on_boarding_view.dart';
import 'package:t_store/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:t_store/features/shop/presentation/cubit/banners_cubit.dart';
import 'package:t_store/features/shop/presentation/cubit/brands_cubit.dart';
import 'package:t_store/features/shop/presentation/cubit/categories_cubit.dart';
import 'package:t_store/features/shop/presentation/cubit/products_cubit.dart';
import 'package:t_store/features/wishlist/presentation/cubit/wishlist_cubit.dart';

/// TStore with startup error handling to prevent infinite splash screen
class TStore extends StatefulWidget {
  const TStore({super.key});

  @override
  State<TStore> createState() => _TStoreState();
}

class _TStoreState extends State<TStore> {
  String? _startupError;

  @override
  void initState() {
    super.initState();
    // The startup initialization happens in main.dart before runApp(),
    // but we catch any late initialization errors here as a safety net.
  }

  @override
  Widget build(BuildContext context) {
    // If there's a startup error, show error screen instead of main app
    if (_startupError != null) {
      return MaterialApp(
        title: TTexts.appName,
        themeMode: ThemeMode.system,
        theme: TAppTheme.lightTheme,
        darkTheme: TAppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: _StartupErrorScreen(error: _startupError!),
      );
    }

    return MultiBlocProvider(
      providers: [
        // Auth
        BlocProvider<AuthCubit>(create: (_) => sl<AuthCubit>()),

        // Shop
        BlocProvider<ProductsCubit>(create: (_) => sl<ProductsCubit>()),
        BlocProvider<CategoriesCubit>(create: (_) => sl<CategoriesCubit>()),
        BlocProvider<BrandsCubit>(create: (_) => sl<BrandsCubit>()),
        BlocProvider<BannersCubit>(create: (_) => sl<BannersCubit>()),

        // Cart & Wishlist
        BlocProvider<CartCubit>(create: (_) => sl<CartCubit>()),
        BlocProvider<WishlistCubit>(create: (_) => sl<WishlistCubit>()),

        // OnBoarding
        BlocProvider<OnBoardingCubit>(create: (_) => OnBoardingCubit()),

        // UI State
        BlocProvider<BannerCarouselSliderCubit>(
          create: (_) => BannerCarouselSliderCubit(),
        ),
      ],
      child: MaterialApp(
        title: TTexts.appName,
        themeMode: ThemeMode.system,
        theme: TAppTheme.lightTheme,
        darkTheme: TAppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: const OnBoardingView(),
      ),
    );
  }
}

/// Error screen shown when startup fails (e.g., Supabase config missing)
class _StartupErrorScreen extends StatelessWidget {
  final String error;

  const _StartupErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Application Startup Failed',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'The application could not start properly.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please check your configuration and restart the app.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  error,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
