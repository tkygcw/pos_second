import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:optimy_second_device/fragment/table/table_view.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../notifier/cart_notifier.dart';
import '../../notifier/table_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/cart_product.dart';
import '../../object/modifier_group.dart';
import '../../object/modifier_item.dart';
import '../../object/order_cache.dart';
import '../../object/order_detail.dart';
import '../../object/printer.dart';
import '../../object/table.dart';
import '../../object/variant_group.dart';
import '../../page/progress_bar.dart';
import '../../translation/AppLocalizations.dart';

class TableMenu extends StatefulWidget {
  const TableMenu({Key? key}) : super(key: key);

  @override
  State<TableMenu> createState() => _TableMenuState();
}

class _TableMenuState extends State<TableMenu> {
  List<Printer> printerList = [];
  List<PosTable> tableList = [], cartSelectedTableList = [];
  List<OrderCache> orderCacheList = [];
  List<OrderDetail> orderDetailList = [];
  List<VariantGroup> variantGroup = [];
  List<ModifierGroup> modifierGroup = [];
  List<PosTable> sameGroupTbList = [];
  double priceSST = 0.0;
  double priceServeTax = 0.0;
  bool isLoaded = false;
  bool productDetailLoaded = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // readAllTable();
    //readAllPrinters();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   widget.cartModel.initialLoad();
    // });
  }

  fontColor({required PosTable posTable}) {
    if (posTable.status == 1) {
      Color fontColor = Colors.black;
      Color backgroundColor = toColor(posTable.card_color!);
      if (backgroundColor.computeLuminance() > 0.5) {
        fontColor = Colors.black;
      } else {
        fontColor = Colors.white;
      }
      return fontColor;
    }
  }

  toColor(String hex) {
    var hexColor = hex.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    if (hexColor.length == 8) {
      return Color(int.parse("0x$hexColor"));
    }
  }


  readAllTable({model, notification}) async {
    if (notification == null) {
      isLoaded = false;
    }
    if (model != null) {
      model.changeContent2(false);
    }

    await clientAction.connectRequestPort(action: '13', param: '', callback: decodeData);

    // List<PosTable> data = await PosDatabase.instance.readAllTable();
    //
    // tableList = data;
    // await readAllTableGroup();
  }

  decodeData(response){
    try{
      var json = jsonDecode(clientAction.response!);
      String status = json['status'];
      switch(status){
        case '1': {
          Iterable value1 = json['data']['table_list'];
          tableList = List<PosTable>.from(value1.map((json) => PosTable.fromJson(json)));
          if (mounted) {
            setState(() {
              isLoaded = true;
            });
          }
        }break;
        default: {
          
        }
      }
    }catch(e){
      print('init table error: $e');
      //readAllTable();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      // if (tableModel.isChange) {
      //   readAllTable(model: tableModel);
      // }
      // if (notificationModel.contentLoad == true) {
      //   isLoaded = false;
      // }
      // if (notificationModel.contentLoad == true && notificationModel.contentLoaded == true) {
      //   notificationModel.resetContentLoaded();
      //   notificationModel.resetContentLoad();
      //   Future.delayed(const Duration(seconds: 1), () {
      //     if (mounted) {
      //       setState(() {
      //         readAllTable(notification: true);
      //       });
      //     }
      //   });
      // }
      return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          primary: false,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            "Table",
            style: TextStyle(fontSize: 25),
          ),
        ),
        body: TableView(themeColor: color),
      );
    });
  }

  getModifierGroupItem(OrderDetail orderDetail) {
    modifierGroup = [];
    List<ModifierItem> temp = orderDetail.modifierItem!;
    if (orderDetail.mod_group_id!.isNotEmpty) {
      for (int j = 0; j < orderDetail.mod_group_id!.length; j++) {
        List<ModifierItem> modItemChild = [];
        //check modifier group is existed or not
        bool isModifierExisted = false;
        int position = 0;
        for (int g = 0; g < modifierGroup.length; g++) {
          if (modifierGroup[g].mod_group_id == orderDetail.mod_group_id![j]) {
            isModifierExisted = true;
            position = g;
            break;
          }
        }
        //if new category
        if (!isModifierExisted) {
          modifierGroup.add(ModifierGroup(
              modifierChild: [], mod_group_id: int.parse(orderDetail.mod_group_id![j])));
          position = modifierGroup.length - 1;
        }

        for (int k = 0; k < temp.length; k++) {
          if (modifierGroup[position].mod_group_id.toString() == temp[k].mod_group_id) {
            modItemChild.add(
                ModifierItem(mod_group_id: orderDetail.mod_group_id![position],
                    mod_item_id: temp[k].mod_item_id,
                    name: temp[k].name,
                    isChecked: true));
            temp.removeAt(k);
          }
        }
        modifierGroup[position].modifierChild = modItemChild;
      }
    }
    return modifierGroup;
  }

  //
  getVariantGroupItem(OrderDetail orderDetail) {
    variantGroup = [];
    //loop all order detail variant
    if (orderDetail.variantItem!.isNotEmpty) {
      for (int i = 0; i < orderDetail.variantItem!.length; i++) {
        variantGroup.add(VariantGroup(child: orderDetail.variantItem,
            variant_group_id: int.parse(orderDetail.variantItem![i].variant_group_id!)));
      }
    }
    //print('variant group length: ${variantGroup.length}');
    return variantGroup;
  }

  readSpecificTableDetail(PosTable posTable) async {
    await clientAction.connectRequestPort(action: '10', param: jsonEncode(posTable), callback: decodeData2);
    setState(() {
      productDetailLoaded = true;
    });
  }

  decodeData2(response){
    var json = jsonDecode(response);
    Iterable value1 = json['data']['order_detail'];
    Iterable value2 = json['data']['order_cache'];
    // Iterable value3 = json['data']['pos_table'];
    orderDetailList = value1.map((tagJson) => OrderDetail.fromJson(tagJson)).toList();
    orderCacheList = value2.map((tagJson) => OrderCache.fromJson(tagJson)).toList();
    // cartSelectedTableList =value3.map((tagJson) => PosTable.fromJson(tagJson)).toList();
  }

  addToCart(CartModel cart) {
    print("add to cart called");
    cartProductItem value;
    print('order detail length: ${orderDetailList.length}');
    for (int i = 0; i < orderDetailList.length; i++) {
      value = cartProductItem(
        branch_link_product_sqlite_id: orderDetailList[i].branch_link_product_sqlite_id!,
        product_name: orderDetailList[i].productName!,
        category_id: orderDetailList[i].product_category_id!,
        price: orderDetailList[i].price!,
        quantity: int.parse(orderDetailList[i].quantity!),
        checkedModifierItem: [],
        modifier: getModifierGroupItem(orderDetailList[i]),
        variant: getVariantGroupItem(orderDetailList[i]),
        remark: orderDetailList[i].remark!,
        status: 0,
        order_cache_sqlite_id: orderDetailList[i].order_cache_sqlite_id,
        order_cache_key: orderDetailList[i].order_cache_key,
        category_sqlite_id: orderDetailList[i].category_sqlite_id,
        order_detail_sqlite_id: orderDetailList[i].order_detail_sqlite_id.toString(),
        base_price: orderDetailList[i].original_price,
        refColor: Colors.black,
      );
      //print("order cache batch: ${value.first_cache_batch}");
      cart.addItem(value);
    }
    cart.addAllTable(tableList.where((element) => element.isSelected == true).toList());
  }

  removeFromCart(CartModel cart) async {
    //List<TableUseDetail> tableUseDetailList = [];
    //await readSpecificTableDetail(posTable);
    if (productDetailLoaded) {
      var detailLength = orderDetailList.length;
      for (int i = 0; i < detailLength; i++) {
        // value = cartProductItem(
        //   order_cache_sqlite_id: orderDetailList[i].order_cache_sqlite_id,
        // );
        // print("order cache sqlite id: ${value.order_cache_sqlite_id}");
        // cart.removeSpecificItem(orderCacheLocalId: orderDetailList[i].order_cache_sqlite_id);
        cart.removePromotion();
      }
      List<PosTable> unSelectedTableList = tableList.where((element) => element.isSelected == false).toList();
      for(int i = 0; i < unSelectedTableList.length; i++){
        cart.selectedTable.removeWhere((item) => item.table_sqlite_id == unSelectedTableList[i].table_sqlite_id);
      }
      // var cacheLength = orderCacheList.length;
      // for (int j = 0; j < cacheLength; j++) {
      //   //Get specific table use detail
      //   List<TableUseDetail> tableUseDetailData = await PosDatabase.instance.readAllTableUseDetail(orderCacheList[j].table_use_sqlite_id!);
      //   tableUseDetailList = tableUseDetailData;
      // }
      // var length = tableUseDetailList.length;
      // for (int k = 0; k < length; k++) {
      //   List<PosTable> tableData = await PosDatabase.instance.readSpecificTable(tableUseDetailList[k].table_sqlite_id!);
      //   cart.removeSpecificTable(tableData[0]);
      //   //cart.addTable(tableData[0]);
      // }
    }
  }
}
