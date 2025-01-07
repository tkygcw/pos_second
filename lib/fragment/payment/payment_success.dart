import 'package:flutter/material.dart';

class PaymentSuccessPage extends StatelessWidget {
  final String change;

  const PaymentSuccessPage({super.key, required this.change});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Change: $change", style: TextStyle(fontSize: 24),),
            ElevatedButton(onPressed: (){}, child: Text("Print receipt")),
            ElevatedButton(onPressed: (){}, child: Text("Open Cash Drawer")),
            ElevatedButton(onPressed: () => Navigator.of(context).pop() , child: Text("Close")),
          ],
        ),
      ),
    );
  }
}
