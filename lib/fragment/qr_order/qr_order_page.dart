import 'package:flutter/material.dart';
import 'package:optimy_second_device/fragment/qr_order/qr_main_page.dart';

class QrOrderPage extends StatefulWidget {
  const QrOrderPage({Key? key}) : super(key: key);

  @override
  State<QrOrderPage> createState() => _QrOrderPageState();
}

class _QrOrderPageState extends State<QrOrderPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(flex: 12, child: QrMainPage())
        ],
      ),
    );
  }
}
