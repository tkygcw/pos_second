import 'package:flutter/material.dart';

import '../../translation/AppLocalizations.dart';
import 'cart_detail_widget.dart';
import 'payment_method_widget.dart';

class MakePaymentDialog extends StatelessWidget {
  const MakePaymentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Text(AppLocalizations.of(context)!.translate('payment_detail')),
          Spacer(),
          IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: Icon(Icons.close),
          )
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: CartDetail(),
            ),
            Expanded(
                child: PaymentMethod()
            )
          ],
        ),
      ),
    );
  }
}


