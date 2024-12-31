import 'package:flutter/material.dart';
import 'package:optimy_second_device/fragment/payment/payment_method_widget.dart';
import 'package:optimy_second_device/fragment/payment/payment_type/shared_widget/button_widget.dart';
import 'package:provider/provider.dart';

import '../../../notifier/cart_notifier.dart';
import 'shared_widget/final_amount_widget.dart';

class FixedAmountView extends StatelessWidget {
  const FixedAmountView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child:
          ///***If you have exported images you must have to copy those images in assets/images directory.
          Image(image: AssetImage("drawable/duitNow.jpg")),
        ),
        ButtonWidget(paymentTypeEnum: PaymentTypeEnum.fixedAmount)
      ],
    );
  }
}



