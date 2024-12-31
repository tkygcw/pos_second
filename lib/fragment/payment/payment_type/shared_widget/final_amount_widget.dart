import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../notifier/cart_notifier.dart';

class FinalAmountWidget extends StatelessWidget {
  const FinalAmountWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'MYR: ${Provider.of<CartModel>(context, listen: false).netTotal}',
      style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
    );
  }
}
