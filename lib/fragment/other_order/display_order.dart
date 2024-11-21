import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:optimy_second_device/main.dart';
import 'package:provider/provider.dart';

import '../../notifier/cart_notifier.dart';
import '../../notifier/table_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/cart_product.dart';
import '../../object/modifier_group.dart';
import '../../object/modifier_item.dart';
import '../../object/order_cache.dart';
import '../../object/order_detail.dart';
import '../../object/order_modifier_detail.dart';
import '../../object/product_variant.dart';
import '../../object/variant_group.dart';
import '../../page/progress_bar.dart';
import '../../utils/Utils.dart';

class DisplayOrderPage extends StatefulWidget {
  final CartModel cartModel;
  const DisplayOrderPage({Key? key, required this.cartModel}) : super(key: key);

  @override
  State<DisplayOrderPage> createState() => _DisplayOrderPageState();
}

class _DisplayOrderPageState extends State<DisplayOrderPage> {
  List<String> list = [];
  String? selectDiningOption = 'All';
  List<OrderCache> orderCacheList = [];
  List<OrderDetail> orderDetailList = [];
  List<OrderModifierDetail> orderModifierDetail = [];
  List<ProductVariant> orderProductVariant = [];
  List<VariantGroup> variantGroup = [];
  List<ModifierGroup> modifierGroup = [];


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //getDiningList();
    getOrderList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.cartModel.notDineInInitLoad();
    });
  }

  getOrderList({model}) async {
    print('refresh UI!');
    Map<String, dynamic>? objectData;
    if (model != null) {
      model.changeContent2(false);
    }
    objectData = {
      'dining_option': selectDiningOption,
    };
    await clientAction.connectRequestPort(action: '17', param: jsonEncode(objectData));
    decodeData();
  }

  listenData({data}){
    //print("call: ${data}");
    // var json = jsonDecode(data);
    // Iterable value1 = json['data']['orderCacheList'];
    // orderCacheList = value1.map((tagJson) => OrderCache.fromJson(tagJson)).toList();
    // list = List.from(json['data']['diningList']);
  }

  decodeData(){
    try{
      print("decode data called");
      var json = jsonDecode(clientAction.response!);
      Iterable value1 = json['data']['orderCacheList'];
      orderCacheList = value1.map((tagJson) => OrderCache.fromJson(tagJson)).toList();
      list = List.from(json['data']['diningList']);
      decodeAction.otherOrderController.sink.add("refresh");
    } catch(e){
      print("decode data error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return  Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<CartModel>(builder: (context, CartModel cart, child) {
        return Consumer<TableModel>(builder: (context, TableModel tableModel, child) {
          if (tableModel.isChange) {
            getOrderList(model: tableModel);
          }
          return StreamBuilder(
              stream: decodeAction.otherOrderStream,
              builder: (context, snapShot) {
                if(snapShot.hasData){
                  print("rebuild");
                  return  Scaffold(
                      appBar: AppBar(
                        automaticallyImplyLeading: false,
                        elevation: 0,
                        title: const Text("Other Order", style: TextStyle(fontSize: 25)),
                        actions: [
                          Container(
                            width: MediaQuery.of(context).size.height / 3,
                            padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                            child: DropdownButton<String>(
                              onChanged: (String? value) {
                                setState(() {
                                  selectDiningOption = value!;
                                });
                                getOrderList();
                              },
                              menuMaxHeight: 300,
                              value: selectDiningOption,
                              // Hide the default underline
                              underline: Container(),
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: color.backgroundColor,
                              ),
                              isExpanded: true,
                              // The list of options
                              items: list
                                  .map((e) => DropdownMenuItem(
                                value: e,
                                child: Container(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    e,
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ),
                              ))
                                  .toList(),
                              // Customize the selected item
                              selectedItemBuilder: (BuildContext context) => list.map((e) => Center(
                                child: Text(e),
                              ))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                      body: Container(
                        padding: EdgeInsets.all(10),
                        child: orderCacheList.isNotEmpty ?
                        ListView.builder(
                            shrinkWrap: true,
                            itemCount: orderCacheList.length,
                            itemBuilder: (BuildContext context, int index) {
                              return Card(
                                elevation: 5,
                                shape: orderCacheList[index].is_selected
                                    ? new RoundedRectangleBorder(
                                    side: new BorderSide(
                                        color: color.backgroundColor, width: 3.0),
                                    borderRadius: BorderRadius.circular(4.0))
                                    : new RoundedRectangleBorder(
                                    side: new BorderSide(
                                        color: Colors.white, width: 3.0),
                                    borderRadius: BorderRadius.circular(4.0)),
                                child: InkWell(
                                  onTap: () async {
                                    if(orderCacheList[index].is_selected == false){
                                      //reset other selected order
                                      for(int i = 0; i < orderCacheList.length; i++){
                                        orderCacheList[i].is_selected = false;
                                        cart.notDineInInitLoad();
                                      }
                                      orderCacheList[index].is_selected = true;
                                      await getOrderDetail(orderCacheList[index]);
                                      addToCart(cart, orderCacheList[index]);


                                    } else if(orderCacheList[index].is_selected == true) {
                                      orderCacheList[index].is_selected = false;
                                      cart.notDineInInitLoad();
                                    }
                                    //openViewOrderDialog(orderCacheList[index]);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: ListTile(
                                        leading:
                                        orderCacheList[index].dining_name == 'Take Away'
                                            ? Icon(
                                          Icons.fastfood_sharp,
                                          color: color.backgroundColor,
                                          size: 30.0,
                                        )
                                            : Icon(
                                          Icons.delivery_dining,
                                          color: color.backgroundColor,
                                          size: 30.0,
                                        ),
                                        trailing: Text(
                                          '#'+orderCacheList[index].batch_id.toString(),
                                          style: TextStyle(fontSize: 20),
                                        ),
                                        subtitle: Text('Order by: ' +
                                            orderCacheList[index].order_by!,
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        title: Text(
                                          "${Utils.convertTo2Dec(orderCacheList[index].total_amount!,)}",
                                          style: TextStyle(fontSize: 20),
                                        )),
                                  ),
                                ),
                              );
                            })
                            :
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.list,
                                color: Colors.grey,
                                size: 36.0,
                              ),
                              Text("No Order", style: TextStyle(fontSize: 24),),
                            ],
                          ),
                        ),
                      )
                  );
                } else {
                  return CustomProgressBar();
                }
              }
          );
        });
      });
    });
  }

  getOrderDetail(OrderCache orderCache) async {
    await clientAction.connectRequestPort(action: '18', param: jsonEncode(orderCache));
    decodeData2();
  }

  decodeData2(){
    var json = jsonDecode(clientAction.response!);
    Iterable value1 = json['data']['orderDetailList'];
    orderDetailList = value1.map((tagJson) => OrderDetail.fromJson(tagJson)).toList();
  }

  getVariantGroupItem(OrderDetail orderDetail) {
    variantGroup = [];
    //loop all order detail variant
    for (int i = 0; i < orderDetail.variantItem!.length; i++) {
      variantGroup.add(VariantGroup(
          child: orderDetail.variantItem,
          variant_group_id:
          int.parse(orderDetail.variantItem![i].variant_group_id!)));
    }
    //print('variant group length: ${variantGroup.length}');
    return variantGroup;
  }

  getModifierGroupItem(OrderDetail orderDetail) {
    modifierGroup = [];
    List<ModifierItem> temp = List.from(orderDetail.modifierItem!);

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
            modifierChild: [],
            mod_group_id: int.parse(orderDetail.mod_group_id![j])));
        position = modifierGroup.length - 1;
      }

      for (int k = 0; k < temp.length; k++) {
        if (modifierGroup[position].mod_group_id.toString() == temp[k].mod_group_id) {
          modItemChild.add(ModifierItem(
              mod_group_id: orderDetail.mod_group_id![position],
              mod_item_id: temp[k].mod_item_id,
              name: temp[k].name,
              isChecked: true));
          temp.removeAt(k);
        }
      }
      modifierGroup[position].modifierChild = modItemChild;
    }
    return modifierGroup;
  }

  addToCart(CartModel cart, OrderCache orderCache) {
    var value;
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
        order_cache_sqlite_id: orderCache.order_cache_sqlite_id.toString(),
        order_cache_key: orderCache.order_cache_key,
        category_sqlite_id: orderDetailList[i].category_sqlite_id,
        order_detail_sqlite_id: orderDetailList[i].order_detail_sqlite_id.toString(),
        refColor: Colors.black,
      );
      cart.addItem(value);
      if(orderCache.dining_name == 'Take Away'){
        cart.selectedOption = 'Take Away';
      } else {
        cart.selectedOption = 'Delivery';
      }
    }
  }
}
