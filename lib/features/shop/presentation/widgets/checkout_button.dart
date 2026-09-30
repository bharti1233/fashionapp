import 'package:flutter/material.dart';
import 'package:t_store/core/utils/helpers/helper_functions.dart';
import 'package:t_store/features/shop/presentation/views/cart_view.dart';

/// Navigates to the real cart. The cart screen itself is Supabase-backed.
class CheckoutButton extends StatelessWidget {
  const CheckoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          THelperFunctions.navigateToScreen(context, const CartView());
        },
        child: const Text('Go to Cart'),
      ),
    );
  }
}
