import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../notifier/cart_notifier.dart';
import 'display_order.dart';

class OtherOrderPage extends StatefulWidget {
  const OtherOrderPage({Key? key}) : super(key: key);

  @override
  State<OtherOrderPage> createState() => _OtherOrderPageState();
}

class _OtherOrderPageState extends State<OtherOrderPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<CartModel>(builder: (context, CartModel cart, child) {
        return Row(
          children: [
            Expanded(flex: 12,child: DisplayOrderPage(cartModel: cart,))
          ],
        );
      }),
    );
  }
}
