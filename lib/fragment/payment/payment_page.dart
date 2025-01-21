import 'package:collapsible_sidebar/collapsible_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:optimy_second_device/fragment/payment/payment_method_widget.dart';
import 'package:optimy_second_device/notifier/cart_notifier.dart';
import 'package:optimy_second_device/notifier/theme_color.dart';
import 'package:provider/provider.dart';

import 'cart_detail_widget.dart';

class MakePaymentPage extends StatelessWidget {
  const MakePaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    var color = context.read<ThemeColor>();
    var cart = context.read<CartModel>();
    return SafeArea(
      child: OrientationBuilder(
        builder: (BuildContext context, Orientation orientation) {
          if(orientation == Orientation.landscape){
            return Scaffold(
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
            );
          } else {
            return Scaffold(
              resizeToAvoidBottomInset: false,
              appBar: AppBar(
                automaticallyImplyLeading: false,
                leading: IconButton(
                  color: color.backgroundColor,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: Icon(Icons.arrow_back),
                ),
                actions: [
                  IconButton(
                    onPressed: (){
                      showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return CartDetail();
                        },
                      );
                    },
                    icon: Badge(
                      label: Text(cart.cartNotifierItem.length.toString()),
                      child: Icon(Icons.shopping_cart_rounded),
                    ),
                    color: color.backgroundColor,
                  ),
                ],
                title: Text('Payment detail',
                    style: TextStyle(fontSize: 25, color: Colors.black)),
                backgroundColor: Color(0xffFAFAFA),
                elevation: 0,
              ),
              body: PaymentMethod(),
            );
          }
        },
      ),
    );
  }
}
