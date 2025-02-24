import 'package:flutter/material.dart';
import 'package:optimy_second_device/fragment/table/table_view_function.dart';

import '../object/table.dart';

class TableModel extends ChangeNotifier {
  static final TableModel instance = TableModel._init();
  List<PosTable> _notifierTableList = [];

  List<PosTable> get notifierTableList => _notifierTableList;

  bool isChange = false;

  TableModel._init();

  Future<void> unselectAllOrderCache() async {
    await TableViewFunction().unselectAllSubPosOrderCache();
  }

  Future<void> getTableFromServer({bool? resetMainPosOrderCache}) async {
    _notifierTableList = await TableViewFunction().readAllTable(resetMainPosOrderCache: resetMainPosOrderCache);
    notifyListeners();
  }

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