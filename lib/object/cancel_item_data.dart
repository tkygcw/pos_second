import 'package:optimy_second_device/object/table.dart';

class CancelItemDataFields {

  static String userId = 'userId';
  static String orderDetailSqliteId = 'orderDetailSqliteId';
  static String restock = 'restock';
  static String cancelQty = 'cancelQty';
  static String reason = 'reason';
  static String selectedTable = 'selectedTable';
}

class CancelItemData {
  int? userId;
  int? orderDetailSqliteId;
  bool? restock;
  num? cancelQty;
  String? reason;
  List<PosTable>? selectedTable;

  CancelItemData({
    this.userId,
    this.orderDetailSqliteId,
    this.restock,
    this.cancelQty,
    this.reason,
    this.selectedTable
  });

  Map<String, Object?> toJson() => {
    CancelItemDataFields.userId: userId,
    CancelItemDataFields.orderDetailSqliteId: orderDetailSqliteId,
    CancelItemDataFields.restock: restock,
    CancelItemDataFields.cancelQty: cancelQty,
    CancelItemDataFields.reason: reason,
    CancelItemDataFields.selectedTable: selectedTable

  };
}