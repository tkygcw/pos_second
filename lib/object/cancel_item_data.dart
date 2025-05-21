class CancelItemDataFields {

  static String userId = 'userId';
  static String orderDetailSqliteId = 'orderDetailSqliteId';
  static String restock = 'restock';
  static String cancelQty = 'cancelQty';
  static String reason = 'reason';
}

class CancelItemData {
  int? userId;
  int? orderDetailSqliteId;
  bool? restock;
  num? cancelQty;
  String? reason;

  CancelItemData({
    this.userId,
    this.orderDetailSqliteId,
    this.restock,
    this.cancelQty,
    this.reason
  });

  Map<String, Object?> toJson() => {
    CancelItemDataFields.userId: userId,
    CancelItemDataFields.orderDetailSqliteId: orderDetailSqliteId,
    CancelItemDataFields.restock: restock,
    CancelItemDataFields.cancelQty: cancelQty,
    CancelItemDataFields.reason: reason
  };
}