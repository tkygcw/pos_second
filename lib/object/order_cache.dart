String? tableOrderCache = 'tb_order_cache ';

class OrderCacheFields {
  static List<String> values = [
    order_cache_sqlite_id,
    order_cache_id,
    order_cache_key,
    order_queue,
    company_id,
    branch_id,
    order_detail_id,
    custom_table_number,
    table_use_sqlite_id,
    table_use_key,
    other_order_key,
    batch_id,
    dining_id,
    order_sqlite_id,
    order_key,
    order_by,
    order_by_user_id,
    cancel_by,
    cancel_by_user_id,
    customer_id,
    total_amount,
    qr_order,
    qr_order_table_sqlite_id,
    qr_order_table_id,
    accepted,
    payment_status,
    sync_status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String order_cache_sqlite_id = 'order_cache_sqlite_id';
  static String order_cache_id = 'order_cache_id';
  static String order_cache_key = 'order_cache_key';
  static String order_queue = 'order_queue';
  static String company_id = 'company_id';
  static String branch_id = 'branch_id';
  static String order_detail_id = 'order_detail_id';
  static String custom_table_number = 'custom_table_number';
  static String table_use_sqlite_id = 'table_use_sqlite_id';
  static String table_use_key = 'table_use_key';
  static String other_order_key = 'other_order_key';
  static String batch_id = 'batch_id';
  static String dining_id = 'dining_id';
  static String order_sqlite_id = 'order_sqlite_id';
  static String order_key = 'order_key';
  static String order_by = 'order_by';
  static String order_by_user_id = 'order_by_user_id';
  static String cancel_by = 'cancel_by';
  static String cancel_by_user_id = 'cancel_by_user_id';
  static String customer_id = 'customer_id';
  static String total_amount = 'total_amount';
  static String qr_order = 'qr_order';
  static String qr_order_table_sqlite_id = 'qr_order_table_sqlite_id';
  static String qr_order_table_id = 'qr_order_table_id';
  static String accepted = 'accepted';
  static String payment_status = 'payment_status';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
  static String dining_name = 'dining_name';
}

class OrderCache{
  int? order_cache_sqlite_id;
  int? order_cache_id;
  String? order_cache_key;
  String? order_queue;
  String? company_id;
  String? branch_id;
  String? order_detail_id;
  String? custom_table_number;
  String? table_use_sqlite_id;
  String? table_use_key;
  String? other_order_key;
  String? batch_id;
  String? dining_id;
  String? order_sqlite_id;
  String? order_key;
  String? order_by;
  String? order_by_user_id;
  String? cancel_by;
  String? cancel_by_user_id;
  String? customer_id;
  String? total_amount;
  int? qr_order;
  String? qr_order_table_sqlite_id;
  String? qr_order_table_id;
  int? accepted;
  int? payment_status;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;
  String? card_color;
  bool is_selected = false;
  String? dining_name;
  String? table_number;

  OrderCache(
      {this.order_cache_sqlite_id,
        this.order_cache_id,
        this.order_cache_key,
        this.order_queue,
        this.company_id,
        this.branch_id,
        this.order_detail_id,
        this.custom_table_number,
        this.table_use_sqlite_id,
        this.table_use_key,
        this.other_order_key,
        this.batch_id,
        this.dining_id,
        this.order_sqlite_id,
        this.order_key,
        this.order_by,
        this.order_by_user_id,
        this.cancel_by,
        this.cancel_by_user_id,
        this.customer_id,
        this.total_amount,
        this.qr_order,
        this.qr_order_table_sqlite_id,
        this.qr_order_table_id,
        this.accepted,
        this.payment_status,
        this.sync_status,
        this.created_at,
        this.updated_at,
        this.soft_delete,
        this.card_color,
        this.dining_name,
        this.table_number
      });

  OrderCache copy({
    int? order_cache_sqlite_id,
    int? order_cache_id,
    String? order_cache_key,
    String? order_queue,
    String? company_id,
    String? branch_id,
    String? order_detail_id,
    String? custom_table_number,
    String? table_use_sqlite_id,
    String? table_use_key,
    String? other_order_key,
    String? batch_id,
    String? dining_id,
    String? order_sqlite_id,
    String? order_key,
    String? order_by,
    String? order_by_user_id,
    String? cancel_by,
    String? cancel_by_user_id,
    String? customer_id,
    String? total_amount,
    int? qr_order,
    String? qr_order_table_sqlite_id,
    String? qr_order_table_id,
    int? accepted,
    int? payment_status,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      OrderCache(
          order_cache_sqlite_id: order_cache_sqlite_id ?? this.order_cache_sqlite_id,
          order_cache_id: order_cache_id ?? this.order_cache_id,
          order_cache_key: order_cache_key ?? this.order_cache_key,
          order_queue: order_queue ?? this.order_queue,
          company_id: company_id ?? this.company_id,
          branch_id: branch_id ?? this.branch_id,
          order_detail_id: order_detail_id ?? this.order_detail_id,
          custom_table_number: custom_table_number ?? this.custom_table_number,
          table_use_sqlite_id: table_use_sqlite_id ?? this.table_use_sqlite_id,
          table_use_key: table_use_key ?? this.table_use_key,
          other_order_key: other_order_key ?? this.other_order_key,
          batch_id: batch_id ?? this.batch_id,
          dining_id: dining_id ?? this.dining_id,
          order_sqlite_id: order_sqlite_id ?? this.order_sqlite_id,
          order_key: order_key ?? this.order_key,
          order_by: order_by ?? this.order_by,
          order_by_user_id: order_by_user_id ?? this.order_by_user_id,
          cancel_by: cancel_by ?? this.cancel_by,
          cancel_by_user_id: cancel_by_user_id ?? this.cancel_by_user_id,
          customer_id: customer_id ?? this.customer_id,
          total_amount: total_amount ?? this.total_amount,
          qr_order: qr_order ?? this.qr_order,
          qr_order_table_sqlite_id: qr_order_table_sqlite_id ?? this.qr_order_table_sqlite_id,
          qr_order_table_id: qr_order_table_id ?? this.qr_order_table_id,
          accepted: accepted ?? this.accepted,
          payment_status: payment_status ?? this.payment_status,
          sync_status: sync_status ?? this.sync_status,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static OrderCache fromJson(Map<String, Object?> json) => OrderCache(
      order_cache_sqlite_id: json[OrderCacheFields.order_cache_sqlite_id] as int?,
      order_cache_id: json[OrderCacheFields.order_cache_id] as int?,
      order_cache_key: json[OrderCacheFields.order_cache_key] as String?,
      order_queue: json[OrderCacheFields.order_queue] as String?,
      company_id: json[OrderCacheFields.company_id] as String?,
      branch_id: json[OrderCacheFields.branch_id] as String?,
      order_detail_id: json[OrderCacheFields.order_detail_id] as String?,
      custom_table_number: json[OrderCacheFields.custom_table_number] as String?,
      table_use_sqlite_id: json[OrderCacheFields.table_use_sqlite_id] as String?,
      table_use_key: json[OrderCacheFields.table_use_key] as String?,
      other_order_key: json[OrderCacheFields.other_order_key] as String?,
      batch_id: json[OrderCacheFields.batch_id] as String?,
      dining_id: json[OrderCacheFields.dining_id] as String?,
      order_sqlite_id: json[OrderCacheFields.order_sqlite_id] as String?,
      order_key: json[OrderCacheFields.order_key] as String?,
      order_by: json[OrderCacheFields.order_by] as String?,
      order_by_user_id: json[OrderCacheFields.order_by_user_id] as String?,
      cancel_by: json[OrderCacheFields.cancel_by] as String?,
      cancel_by_user_id: json[OrderCacheFields.cancel_by_user_id] as String?,
      customer_id: json[OrderCacheFields.customer_id] as String?,
      total_amount: json[OrderCacheFields.total_amount] as String?,
      qr_order: json[OrderCacheFields.qr_order] as int?,
      qr_order_table_sqlite_id: json[OrderCacheFields.qr_order_table_sqlite_id] as String?,
      qr_order_table_id: json[OrderCacheFields.qr_order_table_id] as String?,
      accepted: json[OrderCacheFields.accepted] as int?,
      payment_status: json[OrderCacheFields.payment_status] as int?,
      sync_status: json[OrderCacheFields.sync_status] as int?,
      created_at: json[OrderCacheFields.created_at] as String?,
      updated_at: json[OrderCacheFields.updated_at] as String?,
      soft_delete: json[OrderCacheFields.soft_delete] as String?,
      card_color: json['card_color'] as String?,
      dining_name: json[OrderCacheFields.dining_name] as String?,
      table_number: json['table_number'] as String?
  );

  Map<String, Object?> toJson() => {
    OrderCacheFields.order_cache_sqlite_id: order_cache_sqlite_id,
    OrderCacheFields.order_cache_id: order_cache_id,
    OrderCacheFields.order_cache_key: order_cache_key,
    OrderCacheFields.order_queue: order_queue,
    OrderCacheFields.company_id: company_id,
    OrderCacheFields.branch_id: branch_id,
    OrderCacheFields.order_detail_id: order_detail_id,
    OrderCacheFields.custom_table_number: custom_table_number,
    OrderCacheFields.table_use_sqlite_id: table_use_sqlite_id,
    OrderCacheFields.table_use_key: table_use_key,
    OrderCacheFields.other_order_key: other_order_key,
    OrderCacheFields.batch_id: batch_id,
    OrderCacheFields.dining_id: dining_id,
    OrderCacheFields.order_sqlite_id: order_sqlite_id,
    OrderCacheFields.order_key: order_key,
    OrderCacheFields.order_by: order_by,
    OrderCacheFields.order_by_user_id: order_by_user_id,
    OrderCacheFields.cancel_by: cancel_by,
    OrderCacheFields.cancel_by_user_id: cancel_by_user_id,
    OrderCacheFields.customer_id: customer_id,
    OrderCacheFields.total_amount: total_amount,
    OrderCacheFields.qr_order: qr_order,
    OrderCacheFields.qr_order_table_sqlite_id: qr_order_table_sqlite_id,
    OrderCacheFields.qr_order_table_id: qr_order_table_id,
    OrderCacheFields.accepted: accepted,
    OrderCacheFields.payment_status: payment_status,
    OrderCacheFields.sync_status: sync_status,
    OrderCacheFields.created_at: created_at,
    OrderCacheFields.updated_at: updated_at,
    OrderCacheFields.soft_delete: soft_delete,
    OrderCacheFields.dining_name: dining_name
  };
}