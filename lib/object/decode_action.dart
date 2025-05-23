import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:optimy_second_device/fragment/other_order/other_order_function.dart';
import 'package:optimy_second_device/notifier/fail_print_notifier.dart';
import 'package:optimy_second_device/notifier/table_notifier.dart';
import 'package:optimy_second_device/object/branch_link_dining_option.dart';
import 'package:optimy_second_device/object/order_cache.dart';
import 'package:optimy_second_device/object/order_detail.dart';
import 'package:optimy_second_device/object/product.dart';
import 'package:optimy_second_device/object/product_variant.dart';
import 'package:optimy_second_device/object/promotion.dart';
import 'package:optimy_second_device/object/subscription.dart';
import 'package:optimy_second_device/object/tax_link_dining.dart';
import 'package:optimy_second_device/object/user.dart';

import '../fragment/toast/custom_toastification.dart';
import '../main.dart';
import '../notifier/notification_notifier.dart';
import '../translation/AppLocalizations.dart';
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
  List<TaxLinkDining> decodedTaxLinkDiningList = [];
  List<Subscription> decodedSubscription = [];
  List<User>? decodedUserList = [];
  List<Promotion>? decodedBranchPromotionList = [];
  AppSetting? decodedAppSetting;
  final BuildContext _context = MyApp.navigatorKey.currentContext!;
  String flushbarStatus = '', appLanguageCode = '';

  DecodeAction({
    this.decodedProductList,
    this.decodedCategoryList,
    this.decodedBranchLinkProductList,
    this.decodedBranchLinkModifierList,
    this.decodedUserList,
    this.decodedBranchLinkDiningList
  });

  decodeAllFunction(response){
    print("decode all action called!!!");
    var json = jsonDecode(response);
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
    Iterable value9 = json['data']['taxLinkDiningList'];
    decodedTaxLinkDiningList = List<TaxLinkDining>.from(value9.map((json) => TaxLinkDining.fromJson(json)));
    print("decodedTaxLinkDiningList length: ${decodedTaxLinkDiningList.length}");
    Iterable value10 = json['data']['branchPromotionList'];
    decodedBranchPromotionList =  List<Promotion>.from(value10.map((json) => Promotion.fromJson(json)));
    appLanguageCode = json['data']['app_language_code'];
    if(json['data']['subscription_data'] != null){
      var value12 = json['data']['subscription_data'];
      decodedSubscription = [Subscription.fromJson(value12)];
    }
    if(json['data']['currency'] != null){
      var value13 = json['data']['currency'];
      currency_code = value13[0];
      currency_symbol = value13[1];
    } else {
      currency_code = 'MYR';
      currency_symbol = 'RM';
    }

    ///image part
    // Iterable value7 = json['data']['image_list'];
    // decodedBase64ImageList = List.from(value7);
  }

  checkAction() {
    var json = jsonDecode(clientAction.serverResponse!);
    if(json['action'] != null){
      String action = json['action'];
      switch(action){
        case '0': {
          Iterable value1 = json['failedPrintOrderDetail'];
          List<OrderDetail> failOrderDetail = value1.map((tagJson) => OrderDetail.fromJson(tagJson)).toList();
          if(FailPrintModel.instance.failPrintOrderDetails.isEmpty){
            FailPrintModel.instance.addAllFailedOrderDetail(failOrderDetail);
            showFlushBarAndPlaySound();
          } else {
            checkFailOrderDetailListBatch(failOrderDetail);
          }

        }
        break;
        case '1': {
          decodeAllFunction(clientAction.serverResponse);
          NotificationModel.instance.setNotification(true);
        }
        break;
        case '2': {
          TableModel.instance.getTableFromServer();
        }
        break;
        case '3': {
          OtherOrderFunction.instance.readAllOrderCache();
        }
        break;
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

  Map<String, List<OrderDetail>> groupOrder(List<OrderDetail> returnData) {
    Map<String, List<OrderDetail>> groupedOrderDetails = {};
    for (OrderDetail orderItem in returnData) {
      String cardID = '';
      // if(getOrderNumber(orderItem) != '') {
      //   cardID = getOrderNumber(orderItem);
      // } else
      // if(getTableNumber(orderItem) != '') {
      //   cardID = getTableNumber(orderItem);
      // }
      // else {
      //   cardID = orderItem.order_cache_key.toString().replaceAll("[", "").replaceAll("]", "");
      // }
      cardID = orderItem.failPrintBatch!;
      if (groupedOrderDetails.containsKey(cardID)) {
        groupedOrderDetails[cardID]!.add(orderItem);
      } else {
        groupedOrderDetails[cardID] = [orderItem];
      }
    }
    return groupedOrderDetails;
  }

  void checkFailOrderDetailListBatch(List<OrderDetail> orderDetail){
    Map<String, List<OrderDetail>> requestOrder = groupOrder(orderDetail);
    List<String> localOrderKey = groupOrder(FailPrintModel.instance.failPrintOrderDetails).keys.toList();
    print("local order length: ${localOrderKey.length}");
    print("request order length: ${requestOrder.length}");
    for(int i = 0 ; i < localOrderKey.length; i++){
      if(requestOrder.containsKey(localOrderKey[i]) == true){
        requestOrder.remove(localOrderKey[i]);
      }
    }
    if(requestOrder.isNotEmpty){
      for(int i = 0; i < requestOrder.values.length; i++){
        FailPrintModel.instance.addAllFailedOrderDetail(requestOrder.values.elementAt(i));
      }
      showFlushBarAndPlaySound();
    }
  }

  showFlushBarAndPlaySound(){
    return CustomFailedToast(
        title: "${AppLocalizations.of(MyApp.navigatorKey.currentContext!)?.translate('error')}"
            "${AppLocalizations.of(MyApp.navigatorKey.currentContext!)?.translate('kitchen_printer_timeout')}").showToast();
  }

}