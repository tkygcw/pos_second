import 'dart:async';
import 'dart:convert';

import 'package:optimy_second_device/object/branch_link_dining_option.dart';
import 'package:optimy_second_device/object/order_cache.dart';
import 'package:optimy_second_device/object/product.dart';
import 'package:optimy_second_device/object/product_variant.dart';
import 'package:optimy_second_device/object/user.dart';

import '../main.dart';
import 'app_setting.dart';
import 'branch_link_modifier.dart';
import 'branch_link_product.dart';
import 'categories.dart';

class DecodeAction {
  StreamController cartController = StreamController();
  StreamController cartProductController = StreamController();
  StreamController qrOrderController = StreamController();
  StreamController otherOrderController = StreamController();
  late Stream cartStream = cartController.stream.asBroadcastStream();
  late Stream cartProductStream = cartProductController.stream.asBroadcastStream();
  late Stream qrStream = qrOrderController.stream.asBroadcastStream();
  late Stream otherOrderStream = otherOrderController.stream.asBroadcastStream();
  List<String> decodedBase64ImageList = [];
  List<Product>? decodedProductList = [];
  List<Categories>? decodedCategoryList = [];
  List<BranchLinkProduct>? decodedBranchLinkProductList = [];
  List<BranchLinkModifier>? decodedBranchLinkModifierList = [];
  List<ProductVariant>? decodedProductVariantList = [];
  List<BranchLinkDining>? decodedBranchLinkDiningList = [];
  List<User>? decodedUserList = [];
  AppSetting? decodedAppSetting;

  DecodeAction({
    this.decodedProductList,
    this.decodedCategoryList,
    this.decodedBranchLinkProductList,
    this.decodedBranchLinkModifierList,
    this.decodedUserList,
  });

  decodeAllFunction(){
    var json = jsonDecode(clientAction.response!);
    Iterable value1 = json['data']['tb_categories'];
    decodedCategoryList = List<Categories>.from(value1.map((json) => Categories.fromJson(json)));
    Iterable value2 = json['data']['tb_product'];
    decodedProductList = List<Product>.from(value2.map((json) => Product.fromJson(json)));
    Iterable value3 = json['data']['tb_user'];
    decodedUserList = List<User>.from(value3.map((json) => User.fromJson(json)));
    Iterable value4 = json['data']['tb_branch_link_product'];
    decodedBranchLinkProductList = List<BranchLinkProduct>.from(value4.map((json) => BranchLinkProduct.fromJson(json)));
    Iterable value5 = json['data']['tb_branch_link_modifier'];
    decodedBranchLinkModifierList = List<BranchLinkModifier>.from(value5.map((json) => BranchLinkModifier.fromJson(json)));
    Iterable value6 = json['data']['tb_product_variant'];
    decodedProductVariantList = List<ProductVariant>.from(value6.map((json) => ProductVariant.fromJson(json)));
    //Iterable value7 = json['data']['tb_app_setting'];
    decodedAppSetting = AppSetting.fromJson(json['data']['tb_app_setting']);
    Iterable value8 = json['data']['tb_branch_link_dining_option'];
    decodedBranchLinkDiningList = List<BranchLinkDining>.from(value8.map((json) => BranchLinkDining.fromJson(json)));

    ///image part
    // Iterable value7 = json['data']['image_list'];
    // decodedBase64ImageList = List.from(value7);
  }

  checkAction() {
    var json = jsonDecode(clientAction.response!);
    if(json['action'] != null){
      String action = json['action'];
      switch(action){
        // case'17': {
        //   Map<String, dynamic>? objectData;
        //   Map<String, dynamic>? result;
        //   var json = jsonDecode(clientAction.response!);
        //   Iterable value1 = json['data']['orderCacheList'];
        //   List<OrderCache> orderCacheList = value1.map((tagJson) => OrderCache.fromJson(tagJson)).toList();
        //   List<String> list = List.from(json['data']['diningList']);
        //   objectData = {
        //     "diningList": list,
        //     "orderCacheList": orderCacheList
        //   };
        //   result = {'data': objectData};
        //   otherOrderController.sink.add(jsonEncode(result));
        // }
        // break;
        case'19': {
          Iterable value1 = json['data']['qrOrderCacheList'];
          List<OrderCache> qrOrderCacheList = value1.map((tagJson) => OrderCache.fromJson(tagJson)).toList();
          print("qr order cache: ${qrOrderCacheList.length}");
          qrOrderController.sink.add(qrOrderCacheList);
        }
        break;
      }
    }
  }
}