import 'package:optimy_second_device/object/product_variant.dart';
import 'package:optimy_second_device/object/variant_item.dart';

import 'branch_link_product.dart';
import 'categories.dart';
import 'modifier_item.dart';
import 'order_modifier_detail.dart';

String? tableOrderDetail = 'tb_order_detail ';

class OrderDetailFields {
  static List<String> values = [
    order_detail_sqlite_id,
    order_detail_id,
    order_detail_key,
    order_cache_sqlite_id,
    order_cache_key,
    branch_link_product_sqlite_id,
    category_sqlite_id,
    category_name,
    productName,
    has_variant,
    product_variant_name,
    price,
    original_price,
    quantity,
    remark,
    account,
    cancel_by,
    cancel_by_user_id,
    status,
    sync_status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String order_detail_sqlite_id = 'order_detail_sqlite_id';
  static String order_detail_id = 'order_detail_id';
  static String order_detail_key = 'order_detail_key';
  static String order_cache_sqlite_id = 'order_cache_sqlite_id';
  static String order_cache_key = 'order_cache_key';
  static String branch_link_product_sqlite_id = 'branch_link_product_sqlite_id';
  static String category_sqlite_id = 'category_sqlite_id';
  static String category_name = 'category_name';
  static String productName = 'product_name';
  static String has_variant = 'has_variant';
  static String product_variant_name = 'product_variant_name';
  static String price = 'price';
  static String original_price = 'original_price';
  static String quantity = 'quantity';
  static String remark = 'remark';
  static String account = 'account';
  static String cancel_by = 'cancel_by';
  static String cancel_by_user_id = 'cancel_by_user_id';
  static String status = 'status';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class OrderDetail{
  int? order_detail_sqlite_id;
  int? order_detail_id;
  String? order_detail_key;
  String? order_cache_sqlite_id;
  String? order_cache_key;
  String? branch_link_product_sqlite_id;
  String? category_sqlite_id;
  String? category_name;
  String? productName;
  String? has_variant = '';
  String? product_variant_name = '';
  String? price = '';
  String? original_price = '';
  String? quantity;
  String? remark;
  String? account;
  String? cancel_by;
  String? cancel_by_user_id;
  int? status;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;
  String? total_amount;
  String base_price = '0.0';
  String? product_category_id;
  String? mod_item_id;
  ProductVariant? productVariant;
  List<VariantItem>? variantItem = [];
  List<ModifierItem>? modifierItem = [];
  List<OrderModifierDetail>? orderModifierDetail = [];
  List<String>? mod_group_id = [];
  bool? hasModifier = false;
  int? category_id;
  int? branch_link_product_id;
  int? item_sum;
  double? double_price;
  double? gross_price;
  int? total_record;
  String? available_stock;
  bool? isRemove;
  String? item_cancel;

  OrderDetail(
      {this.order_detail_sqlite_id,
        this.order_detail_id,
        this.order_detail_key,
        this.order_cache_sqlite_id,
        this.order_cache_key,
        this.branch_link_product_sqlite_id,
        this.category_sqlite_id,
        this.category_name,
        this.productName,
        this.has_variant,
        this.product_variant_name,
        this.price,
        this.original_price,
        this.quantity,
        this.remark,
        this.account,
        this.cancel_by,
        this.cancel_by_user_id,
        this.status,
        this.sync_status,
        this.created_at,
        this.updated_at,
        this.soft_delete,
        this.total_amount,
        this.product_category_id,
        this.mod_item_id,
        this.productVariant,
        this.variantItem,
        this.modifierItem,
        this.orderModifierDetail,
        this.mod_group_id,
        this.hasModifier,
        this.category_id,
        this.branch_link_product_id,
        this.item_sum,
        this.double_price,
        this.gross_price,
        this.total_record,
        this.available_stock,
        this.isRemove,
        this.item_cancel
      });

  OrderDetail copy({
    int? order_detail_sqlite_id,
    int? order_detail_id,
    String? order_detail_key,
    String? order_cache_sqlite_id,
    String? order_cache_key,
    String? branch_link_product_sqlite_id,
    String? category_sqlite_id,
    String? category_name,
    String? productName,
    String? has_variant,
    String? product_variant_name,
    String? price,
    String? original_price,
    String? quantity,
    String? remark,
    String? account,
    String? cancel_by,
    String? cancel_by_user_id,
    int? status,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete
  }) =>
      OrderDetail(
          order_detail_sqlite_id: order_detail_sqlite_id ?? this.order_detail_sqlite_id,
          order_detail_id: order_detail_id ?? this.order_detail_id,
          order_detail_key: order_detail_key ?? this.order_detail_key,
          order_cache_sqlite_id: order_cache_sqlite_id ?? this.order_cache_sqlite_id,
          order_cache_key: order_cache_key ?? this.order_cache_key,
          branch_link_product_sqlite_id: branch_link_product_sqlite_id ?? this.branch_link_product_sqlite_id,
          category_sqlite_id: category_sqlite_id ?? this.category_sqlite_id,
          category_name: category_name ?? this.category_name,
          productName: productName ?? this.productName,
          has_variant: has_variant ?? this.has_variant,
          product_variant_name: product_variant_name ?? this.product_variant_name,
          price: price ?? this.price,
          original_price: original_price ?? this.original_price,
          quantity: quantity ?? this.quantity,
          remark: remark ?? this.remark,
          account: account ?? this.account,
          cancel_by: cancel_by ?? this.cancel_by,
          cancel_by_user_id: cancel_by_user_id ?? this.cancel_by_user_id,
          status: status ?? this.status,
          sync_status: sync_status ?? this.sync_status,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static OrderDetail fromJson(Map<String, Object?> json) {
    List<VariantItem>? variantItem;
    List<ModifierItem>? modItem;
    List<OrderModifierDetail>? orderModDetail;
    if(json['variantItem'] != null){
      var variantJson = json['variantItem'] as List;
      variantItem = variantJson.map((tagJson) => VariantItem.fromJson(tagJson)).toList();
    }
    if(json['modifierItem'] != null){
      var modJson = json['modifierItem'] as List;
      modItem = modJson.map((tagJson) => ModifierItem.fromJson(tagJson)).toList();
    }
    if(json['order_modifier_detail'] != null){
      var modJson = json['order_modifier_detail'] as List;
      orderModDetail = modJson.map((tagJson) => OrderModifierDetail.fromJson(tagJson)).toList();
    }

    List<String> stringList = List<String>.from(json['mod_group_id'] as Iterable);
    return OrderDetail(
        order_detail_sqlite_id: json[OrderDetailFields.order_detail_sqlite_id] as int?,
        order_detail_id: json[OrderDetailFields.order_detail_id] as int?,
        order_detail_key: json[OrderDetailFields.order_detail_key] as String?,
        order_cache_sqlite_id: json[OrderDetailFields.order_cache_sqlite_id] as String?,
        order_cache_key: json[OrderDetailFields.order_cache_key] as String?,
        branch_link_product_sqlite_id: json[OrderDetailFields.branch_link_product_sqlite_id] as String?,
        category_sqlite_id: json[OrderDetailFields.category_sqlite_id] as String?,
        category_name: json[OrderDetailFields.category_name] as String?,
        productName: json[OrderDetailFields.productName] as String?,
        has_variant: json[OrderDetailFields.has_variant] as String?,
        product_variant_name: json[OrderDetailFields.product_variant_name] as String?,
        price: json[OrderDetailFields.price] as String?,
        original_price: json[OrderDetailFields.original_price] as String?,
        quantity: json[OrderDetailFields.quantity] as String?,
        remark: json[OrderDetailFields.remark] as String?,
        account: json[OrderDetailFields.account] as String?,
        cancel_by: json[OrderDetailFields.cancel_by] as String?,
        cancel_by_user_id: json[OrderDetailFields.cancel_by_user_id] as String?,
        status: json[OrderDetailFields.status] as int?,
        sync_status: json[OrderDetailFields.sync_status] as int?,
        created_at: json[OrderDetailFields.created_at] as String?,
        updated_at: json[OrderDetailFields.updated_at] as String?,
        soft_delete: json[OrderDetailFields.soft_delete] as String?,
        product_category_id: json['product_category_id'] as String?,
        mod_item_id: json['mod_item_id'] as String?,
        productVariant: json['productVariant'] as ProductVariant?,
        variantItem: variantItem,
        modifierItem: modItem,
        orderModifierDetail: orderModDetail,
        mod_group_id: stringList,
        available_stock: json['available_stock'] as String?,
        isRemove: json['isRemove'] as bool?
      // total_amount: json['total_amount'] as String?,
      // category_id: json['category_id'] as int?,
      // branch_link_product_id: json['branch_link_product_id'] as int?,
      //category_name: json['category_name'] as String?,
      // item_sum: json['item_sum'] as int?,
      // double_price: json['net_sales'] as double?,
      // gross_price: json['gross_price'] as double?,
      // total_record: json['total_record'] as int?,
      // item_cancel: json['item_cancel'] as String?

    );
  }

  Map<String, Object?> toJson() => {
    OrderDetailFields.order_detail_sqlite_id: order_detail_sqlite_id,
    OrderDetailFields.order_detail_id: order_detail_id,
    OrderDetailFields.order_detail_key: order_detail_key,
    OrderDetailFields.order_cache_sqlite_id: order_cache_sqlite_id,
    OrderDetailFields.order_cache_key: order_cache_key,
    OrderDetailFields.branch_link_product_sqlite_id: branch_link_product_sqlite_id,
    OrderDetailFields.category_sqlite_id: category_sqlite_id,
    OrderDetailFields.category_name: category_name,
    OrderDetailFields.productName: productName,
    OrderDetailFields.has_variant: has_variant,
    OrderDetailFields.product_variant_name: product_variant_name,
    OrderDetailFields.price: price,
    OrderDetailFields.original_price: original_price,
    OrderDetailFields.quantity: quantity,
    OrderDetailFields.remark: remark,
    OrderDetailFields.account: account,
    OrderDetailFields.cancel_by: cancel_by,
    OrderDetailFields.cancel_by_user_id: cancel_by_user_id,
    OrderDetailFields.status: status,
    OrderDetailFields.sync_status: sync_status,
    OrderDetailFields.created_at: created_at,
    OrderDetailFields.updated_at: updated_at,
    OrderDetailFields.soft_delete: soft_delete,
    'product_category_id': product_category_id,
    'mod_item_id': mod_item_id,
    'productVariant': productVariant,
    'variantItem': variantItem,
    'modifierItem': modifierItem,
    'mod_group_id': mod_group_id,
    'hasModifier': hasModifier
  };

  Map syncJson() => {
    OrderDetailFields.order_detail_key: order_detail_key,
    OrderDetailFields.order_cache_key: order_cache_key,
    OrderDetailFields.category_name: category_name,
    OrderDetailFields.productName: productName,
    OrderDetailFields.has_variant: has_variant,
    OrderDetailFields.product_variant_name: product_variant_name,
    OrderDetailFields.price: price,
    OrderDetailFields.original_price: original_price,
    OrderDetailFields.quantity: quantity,
    OrderDetailFields.remark: remark,
    OrderDetailFields.account: account,
    OrderDetailFields.cancel_by: cancel_by,
    OrderDetailFields.cancel_by_user_id: cancel_by_user_id,
    OrderDetailFields.status: status,
    OrderDetailFields.sync_status: sync_status,
    OrderDetailFields.created_at: created_at,
    OrderDetailFields.updated_at: updated_at,
    OrderDetailFields.soft_delete: soft_delete,
    CategoriesFields.category_id: category_id,
    BranchLinkProductFields.branch_link_product_id: branch_link_product_id
  };
}
