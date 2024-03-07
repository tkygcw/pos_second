import 'package:flutter/cupertino.dart';

import '../object/order_detail.dart';

class FailPrintModel extends ChangeNotifier {
  static final FailPrintModel instance = FailPrintModel();
  final List<OrderDetail> _failedPrintOrderDetail = [];
  bool _selectAll = true;
  Set<String> _selectedOrder = {};

  bool get isSelectAll  => _selectAll;

  List<OrderDetail> get failPrintOrderDetails => _failedPrintOrderDetail;

  Set<String> get selectedOrder => _selectedOrder;

  void addAllFailedOrderDetail(List<OrderDetail> orderDetail) {
    _failedPrintOrderDetail.addAll(orderDetail);
    notifyListeners();
  }

  void addFailedOrderDetail(OrderDetail orderDetail) {
    _failedPrintOrderDetail.add(orderDetail);
    notifyListeners();
  }

  void removeAllFailedOrderDetail() {
    _failedPrintOrderDetail.clear();
    notifyListeners();
  }

  void setAllAsSelected() {
    _selectAll = true;
    notifyListeners();
  }

  void setAllAsUnselected() {
    _selectAll = false;
    notifyListeners();
  }

  void clearAllSelectedOrder(){
    _selectedOrder.clear();
    notifyListeners();
  }
}