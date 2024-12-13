import 'package:flutter/material.dart';
import 'package:optimy_second_device/fragment/table/table_menu.dart';

class TablePage extends StatelessWidget {
  const TablePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: TableMenu(),
    );
  }
}
