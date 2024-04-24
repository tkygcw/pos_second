import 'package:flutter/cupertino.dart';

class AppSettingModel extends ChangeNotifier {
  static final AppSettingModel instance = AppSettingModel.init();
  bool? _show_sku;

  AppSettingModel.init();
  // void initialLoad() async {
  //   AppSetting? data = await PosDatabase.instance.readAppSetting();
  //   if (data != null) {
  //     directPaymentStatus = data.direct_payment == 0 ? false : true;
  //     autoPrintChecklist = data.print_checklist == 0 ? false : true;
  //     autoPrintReceipt = data.print_receipt == 0 ? false : true;
  //     show_sku = data.show_sku == 0 ? false : true;
  //     enable_numbering = data.enable_numbering == null || data.enable_numbering == 0 ? false : true;
  //     starting_number = data.starting_number != null || data.starting_number != 0 ? data.starting_number : 0;
  //     table_order = data.table_order == 0 ? false : true;
  //   }
  // }

  bool? get showSKUStatus => _show_sku;

  void setShowSKUStatus(bool status) {
    _show_sku = status;
    notifyListeners();
  }

}
