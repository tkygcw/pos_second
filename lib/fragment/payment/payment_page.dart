import 'package:flutter/material.dart';
import 'package:optimy_second_device/fragment/payment/payment_method_widget.dart';

import 'cart_detail_widget.dart';

class MakePaymentPage extends StatelessWidget {
  const MakePaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              flex: 1,
              child: CartDetail(),
            ),
            Expanded(
              flex: 2,
              child: PaymentMethod(),
            )
          ],
        ),
      ),
    );
  }
}
