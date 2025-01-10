import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../notifier/cart_notifier.dart';
import '../../notifier/table_notifier.dart';

class PaymentSuccessPage extends StatefulWidget {
  final String change;
  const PaymentSuccessPage({super.key, required this.change});

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> {
  bool isButtonDisable = false;

  @override
  Widget build(BuildContext context) {
    var tableModel = Provider.of<TableModel>(context, listen: false);
    var cartModel = Provider.of<CartModel>(context, listen: false);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Change: ${widget.change}", style: TextStyle(fontSize: 24),),
            ElevatedButton(onPressed: isButtonDisable ? null : (){}, child: Text("Print receipt")),
            ElevatedButton(onPressed: isButtonDisable ? null : (){}, child: Text("Open Cash Drawer")),
            ElevatedButton(
              onPressed: isButtonDisable ? null : () async  {
                isButtonDisable = true;
                await tableModel.getTableFromServer();
                await tableModel.unselectAllOrderCache();
                cartModel.initialLoad();
                Navigator.of(context).pop();
              },
              child: Text("Close"),
            ),
          ],
        ),
      ),
    );
  }
}
