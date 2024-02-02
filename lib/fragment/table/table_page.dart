import 'package:flutter/material.dart';
import 'package:optimy_second_device/fragment/table/table_menu.dart';
import 'package:provider/provider.dart';

import '../../notifier/cart_notifier.dart';

class TablePage extends StatefulWidget {
  const TablePage({Key? key}) : super(key: key);

  @override
  State<TablePage> createState() => _TablePageState();
}

class _TablePageState extends State<TablePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Consumer<CartModel>(builder: (context, CartModel cart, child) {
          return Row(
            children: [Expanded(flex: 12, child: TableMenu(callBack: () {}, cartModel: cart,))],
          );
        }));
  }
}
