import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
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

class TableMenu extends StatefulWidget {
  final CartModel cartModel;
  final Function() callBack;
  const TableMenu({Key? key, required this.cartModel, required this.callBack}) : super(key: key);

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
    readAllTable();
    //readAllPrinters();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.cartModel.initialLoad();
    });
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
      Iterable value1 = json['data']['table_list'];
      tableList = List<PosTable>.from(value1.map((json) => PosTable.fromJson(json)));
      if (mounted) {
        setState(() {
          isLoaded = true;
        });
      }
    }catch(e){
      print('init table error: $e');
      //readAllTable();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<CartModel>(builder: (context, CartModel cart, child) {
        return Consumer<TableModel>(builder: (context, TableModel tableModel, child) {
          if (tableModel.isChange) {
            readAllTable(model: tableModel);
          }
          if (notificationModel.contentLoad == true) {
            isLoaded = false;
          }
          if (notificationModel.contentLoad == true && notificationModel.contentLoaded == true) {
            notificationModel.resetContentLoaded();
            notificationModel.resetContentLoad();
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                setState(() {
                  readAllTable(notification: true);
                });
              }
            });
          }
          return Scaffold(
              body: isLoaded
                  ?
              Container(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(11, 15, 11, 4),
                      child: Row(
                        children: [
                          Text(
                            "Table",
                            style: TextStyle(fontSize: 25),
                          ),
                          SizedBox(
                              width: MediaQuery
                                  .of(context)
                                  .size
                                  .height > 500
                                  ? 500
                                  : 50),
                          // Expanded(
                          //   child: TextField(
                          //     onChanged: (value) {
                          //       searchTable(value);
                          //     },
                          //     decoration: InputDecoration(
                          //       isDense: true,
                          //       border: InputBorder.none,
                          //       labelText: 'Search',
                          //       focusedBorder: OutlineInputBorder(
                          //         borderSide: const BorderSide(color: Colors.grey, width: 2.0),
                          //         borderRadius: BorderRadius.circular(25.0),
                          //       ),
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    Expanded(
                      child: GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: MediaQuery
                            .of(context)
                            .size
                            .height > 500 ? 5 : 3,
                        children: List.generate(
                          //this is the total number of cards
                            tableList.length, (index) {
                          // tableList[index].seats == 2;
                          return Card(
                            color: tableList[index].status != 0 && MediaQuery
                                .of(context)
                                .size
                                .height < 500
                                ? toColor(tableList[index].card_color!)
                                : Colors.white,
                            shape: tableList[index].isSelected
                                ? new RoundedRectangleBorder(
                                side: new BorderSide(
                                    color: color.backgroundColor, width: 3.0),
                                borderRadius:
                                BorderRadius.circular(4.0))
                                : new RoundedRectangleBorder(
                                side: new BorderSide(
                                    color: Colors.white, width: 3.0),
                                borderRadius:
                                BorderRadius.circular(4.0)),
                            elevation: 5,
                            child: InkWell(
                              splashColor: Colors.blue.withAlpha(30),
                              onDoubleTap: () {
                                if (tableList[index].status != 1) {
                                  //openAddTableDialog(tableList[index]);
                                } else {
                                  //openChangeTableDialog(tableList[index], cart);
                                }
                              },
                              onTap: () async {
                                await readSpecificTableDetail(tableList[index]);
                                if (productDetailLoaded) {
                                  if (tableList[index].status == 1) {
                                    // table in use (colored)
                                    for (int i = 0; i < tableList.length; i++) {
                                      if (tableList[index].group == tableList[i].group) {
                                        if (tableList[i].isSelected == false) {
                                          tableList[i].isSelected = true;
                                        } else if (tableList[i].isSelected == true) {
                                          if (tableList[index].group == tableList[i].group) {
                                            setState(() {
                                              //removeFromCart(cart, tableList[index]);
                                              tableList[i].isSelected = false;
                                              //print('table list: ${tableList[i].number}');
                                              //cart.removeSpecificTable(tableList[i]);
                                            });
                                          } else {
                                            setState(() {
                                              //removeFromCart(cart, tableList[index]);
                                              tableList[i].isSelected = false;
                                              //cart.removeSpecificTable(tableList[index]);
                                            });
                                          }
                                        }
                                      }
                                    }
                                  } else {
                                    for (int j = 0; j < tableList.length; j++) {
                                      //reset all using table to un-select (table status == 1)
                                      if (tableList[j].status == 1) {
                                        tableList[j].isSelected = false;
                                        cart.removeAllCartItem();
                                        cart.removePromotion();
                                        cart.removeSpecificTable(tableList[j]);
                                      }
                                    }
                                    Fluttertoast.showToast(backgroundColor: Color(0xFF07F107),
                                        msg: "Table not in use");
                                  }
                                  if (tableList[index].status == 1 &&
                                      tableList[index].isSelected == true) {
                                    //await readSpecificTableDetail(tableList[index]);
                                    addToCart(cart);
                                  } else {
                                    removeFromCart(cart);
                                  }
                                }
                              },
                              child: Container(
                                margin: MediaQuery
                                    .of(context)
                                    .size
                                    .height > 500 ? EdgeInsets.all(2) : EdgeInsets.all(0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // tableList[index].group != null && MediaQuery.of(context).size.height > 500
                                    //     ? Expanded(
                                    //         child: Text(
                                    //         "Group: ${tableList[index].group}",
                                    //         style:
                                    //             TextStyle(fontSize: 18),
                                    //       ))
                                    //     : MediaQuery.of(context).size.height > 500
                                    //         ? Expanded(child: Text(''))
                                    //         : Container(height: 10),
                                    Container(
                                      margin: MediaQuery.of(context).size.height > 500 ? EdgeInsets.fromLTRB(0, 5, 0, 5) : null,
                                      height: MediaQuery.of(context).size.height < 500 ? 100
                                          : MediaQuery.of(context).size.height < 700 ?
                                      MediaQuery.of(context).size.height / 6.5 : MediaQuery.of(context).size.height / 5.5,
                                      child: Stack(
                                        children: [
                                          Visibility(
                                            visible: tableList[index].group != null && MediaQuery
                                                .of(context)
                                                .size
                                                .height > 500 ? true : false,
                                            child: Container(
                                                alignment: Alignment.topCenter,
                                                child: Container(
                                                  padding: EdgeInsets.only(right: 5.0, left: 5.0),
                                                  decoration: BoxDecoration(
                                                      color: tableList[index].group != null &&
                                                          MediaQuery
                                                              .of(context)
                                                              .size
                                                              .height > 500
                                                          ?
                                                      toColor(tableList[index].card_color!)
                                                          :
                                                      Colors.white,
                                                      borderRadius: BorderRadius.circular(5.0)
                                                  ),
                                                  child: Text(
                                                    "Group: ${tableList[index].group}",
                                                    style:
                                                    TextStyle(fontSize: 18,
                                                        color: fontColor(
                                                            posTable: tableList[index])),
                                                  ),
                                                )),
                                          ),
                                          tableList[index].seats == '2'
                                              ?
                                          Container(
                                              alignment: Alignment.center,

                                              child: Image.asset("drawable/two-seat.jpg")
                                          )
                                              :
                                          tableList[index].seats == '4'
                                              ?
                                          Container(
                                              alignment: Alignment.center,
                                              child: Image.asset("drawable/four-seat.jpg")
                                          )
                                              :
                                          tableList[index].seats == '6'
                                              ?
                                          Container(
                                              alignment: Alignment.center,
                                              child: Image.asset("drawable/six-seat.jpg")
                                          )
                                              :
                                          Container(),
                                          // Ink.image(
                                          //   image: tableList[index].seats == '2'
                                          //       ? FileImage(File('data/user/0/com.example.pos_system/files/assets/img/two-seat.jpg'))
                                          //   // NetworkImage(
                                          //   //         "https://www.hometown.in/media/cms/icon/Two-Seater-Dining-Sets.png")
                                          //       : tableList[index].seats == '4'
                                          //           ? FileImage(File('data/user/0/com.example.pos_system/files/assets/img/four-seat.jpg'))
                                          //   // NetworkImage(
                                          //   //             "https://www.hometown.in/media/cms/icon/Four-Seater-Dining-Sets.png")
                                          //           : tableList[index].seats == '6'
                                          //               ? FileImage(File('data/user/0/com.example.pos_system/files/assets/img/six-seat.jpg'))
                                          //   // NetworkImage(
                                          //   //                 "https://www.hometown.in/media/cms/icon/Six-Seater-Dining-Sets.png")
                                          //               : FileImage(File('data/user/0/com.example.pos_system/files/assets/img/duitNow.jpg')),
                                          //   // NetworkImage(
                                          //   //                 "https://png.pngtree.com/png-vector/20190820/ourmid/pngtree-no-image-vector-illustration-isolated-png-image_1694547.jpg"),
                                          //   fit: BoxFit.cover,
                                          // ),
                                          Container(
                                              alignment: Alignment.center,
                                              child: Text(tableList[index].number!)),
                                          Visibility(
                                            visible: MediaQuery
                                                .of(context)
                                                .size
                                                .height > 500 ? true : false,
                                            child: Container(
                                                alignment: Alignment.bottomCenter,
                                                child: Text(
                                                    "RM ${tableList[index].total_amount ?? '0.00'}",
                                                    style: TextStyle(fontSize: 18))),
                                          ),

                                        ],
                                      ),
                                    ),
                                    MediaQuery
                                        .of(context)
                                        .size
                                        .height > 500 ? Container(height: 10) : Container(),
                                    // tableList[index].status == 1 ?
                                    // Expanded(
                                    //     child: Text(
                                    //       "RM ${tableList[index].total_Amount.toStringAsFixed(2)}",
                                    //       style: TextStyle(fontSize: 18)),
                                    // ) :
                                    //     Expanded
                                    //       (child: Text(''))
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    )
                  ],
                ),
              )
                  : CustomProgressBar());
        });
      });
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
    await clientAction.connectRequestPort(action: '14', param: jsonEncode(posTable));
    decodeData2();
    setState(() {
      productDetailLoaded = true;
    });
  }

  decodeData2(){
    var json = jsonDecode(clientAction.response!);
    Iterable value1 = json['data']['order_detail'];
    Iterable value2 = json['data']['order_cache'];
    Iterable value3 = json['data']['pos_table'];
    orderDetailList = value1.map((tagJson) => OrderDetail.fromJson(tagJson)).toList();
    orderCacheList = value2.map((tagJson) => OrderCache.fromJson(tagJson)).toList();
    cartSelectedTableList =value3.map((tagJson) => PosTable.fromJson(tagJson)).toList();
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
    cart.selectedTable.addAll(cartSelectedTableList);
    // for (int j = 0; j < orderCacheList.length; j++) {
    //   //Get specific table use detail
    //   List<TableUseDetail> tableUseDetailData = await PosDatabase.instance.readAllTableUseDetail(orderCacheList[j].table_use_sqlite_id!);
    //   tableUseDetailList = List.from(tableUseDetailData);
    // }
    //
    // for (int k = 0; k < tableUseDetailList.length; k++) {
    //   List<PosTable> tableData = await PosDatabase.instance.readSpecificTable(tableUseDetailList[k].table_sqlite_id!);
    //   cart.addTable(tableData[0]);
    // }
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
        cart.removeSpecificItem(orderCacheLocalId: orderDetailList[i].order_cache_sqlite_id);
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
