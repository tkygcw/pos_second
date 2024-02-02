import 'package:flutter/material.dart';

import '../object/table.dart';

class TableModel extends ChangeNotifier {
  List<PosTable> notifierTableList = [];
  bool isChange = false;

  void initialLoad() async {
    print('table notifier called');
    notifyListeners();
  }

  void changeContent(bool action) async {
    print('change content changed in model');
    isChange = action;
    notifyListeners();
  }

  void changeContent2(bool action) async {
    isChange = action;
  }

}