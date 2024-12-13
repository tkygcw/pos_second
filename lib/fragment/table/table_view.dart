import 'package:flutter/material.dart';
import 'package:optimy_second_device/fragment/table/table_view_function.dart';
import 'package:optimy_second_device/fragment/toast/custom_toastification.dart';
import 'package:optimy_second_device/notifier/theme_color.dart';
import 'package:optimy_second_device/object/cart_product.dart';
import 'package:optimy_second_device/object/order_cache.dart';
import 'package:optimy_second_device/object/order_detail.dart';
import 'package:optimy_second_device/object/table.dart';
import 'package:optimy_second_device/page/progress_bar.dart';
import 'package:provider/provider.dart';

import '../../notifier/cart_notifier.dart';
import '../../page/loading_dialog.dart';

var tableViewFunc = TableViewFunction();

class TableView extends StatefulWidget {
  final ThemeColor themeColor;
  const TableView({super.key, required this.themeColor});

  @override
  State<TableView> createState() => _TableViewState();
}

class _TableViewState extends State<TableView> {
  late Future<List<PosTable>> _readTableFromServer;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _readTableFromServer = tableViewFunc.readAllTable();
  }
  @override
  Widget build(BuildContext context) {
    var color = widget.themeColor;
    return FutureBuilder<List<PosTable>>(
      future: _readTableFromServer,
      builder: (context, snapshot) {
        print("connection state: ${snapshot.connectionState}");
        switch(snapshot.connectionState){
          case ConnectionState.waiting:
            return CustomProgressBar();
          default :
            if(snapshot.hasError){
              return Center(
                child: Text("Check main pos version"),
              );
            } else {
              List<PosTable> tableList = snapshot.data!;
              return GridView.count(
                shrinkWrap: true,
                crossAxisCount: MediaQuery.of(context).size.height > 500 ? 5 : 3,
                children: List.generate(
                    tableList.length, (index) {
                  return _TableCard(posTable: tableList[index], color: color);
                }),
              );
            }
        }
      }
    );
  }
}

class _TableCard extends StatelessWidget {
  final ThemeColor color;
  final PosTable posTable;
  const _TableCard({super.key, required this.posTable, required this.color});

  @override
  Widget build(BuildContext context) {
    var isInCart = context.select<CartModel, bool>(
      // Here, we are only interested whether [item] is inside the cart.
          (cart) {
            List<String> tableGroup = cart.selectedTable.map((e) => e.group!).toList();
            if(tableGroup.contains(posTable.group) && !cart.selectedTable.any((e) => e.number == posTable.number)){
              cart.addTable(posTable);
            }
            return tableGroup.contains(posTable.group);
          },
    );
    return Card(
      color: posTable.status != 0 && MediaQuery.of(context).size.height < 500 ?
      toColor(posTable.card_color!) : Colors.white,
      shape: isInCart? RoundedRectangleBorder(
          side: BorderSide(color: color.backgroundColor, width: 3.0),
          borderRadius: BorderRadius.circular(4.0)) : RoundedRectangleBorder(
          side: BorderSide(
              color: Colors.white, width: 3.0),
          borderRadius:
          BorderRadius.circular(4.0)),
      elevation: 5,
      child: InkWell(
        splashColor: Colors.blue.withAlpha(30),
        onDoubleTap: () {
          if (posTable.status != 1) {
            //openAddTableDialog(tableList[index]);
          } else {
            //openChangeTableDialog(tableList[index], cart);
          }
        },
        onTap: () async {
          openLoadingDialogBox(context);
          Future.delayed(Duration(milliseconds: 500), () async {
            var cart = context.read<CartModel>();
            if(isInCart){
              cart.removeGroupedTable(posTable);
              cart.removeSpecificItem(posTable.table_use_key);
            } else {
              if(posTable.status == 1){
                await tableViewFunc.readSpecificTableDetail(posTable);
                List<OrderDetail> orderDetail = tableViewFunc.orderDetailList;
                List<OrderCache> orderCache = tableViewFunc.orderCacheList;
                List<cartProductItem> itemList = [];
                for(var order in orderDetail){
                  var item = cartProductItem(
                    product_sku: order.product_sku,
                    product_name: order.productName,
                    price: order.price,
                    base_price: order.original_price,
                    orderModifierDetail: order.orderModifierDetail,
                    productVariantName: order.product_variant_name,
                    unit: order.unit,
                    quantity: num.parse(order.quantity!),
                    remark: order.remark,
                    refColor: Colors.black,
                    first_cache_created_date_time: orderCache.last.created_at,  //orderCacheList[0].created_at,
                    first_cache_batch: orderCache.last.batch_id,
                    table_use_key: orderCache.last.table_use_key,
                    per_quantity_unit: order.per_quantity_unit,
                    status: 0
                  );
                  itemList.add(item);
                }
                cart.addAllItem(itemList, notifyListener: false);
                cart.addTable(posTable);
              } else {
                CustomFailedToast(title: 'Table not in used').showToast();
              }
            }
            Navigator.of(context).pop();
          });
        },
        child: Container(
          margin: EdgeInsets.all(5),
          height: MediaQuery.of(context).size.height < 500 ? 100 :
          MediaQuery.of(context).size.height < 700 ?
          MediaQuery.of(context).size.height / 6.5 : MediaQuery.of(context).size.height / 5.5,
          child: Stack(
            children: [
              Visibility(
                visible: posTable.group != null && MediaQuery.of(context).size.height > 500 ? true : false,
                child: Container(
                  alignment: Alignment.topCenter,
                  child: Container(
                    padding: EdgeInsets.only(right: 5.0, left: 5.0),
                    decoration: BoxDecoration(
                        color: posTable.group != null && MediaQuery.of(context).size.height > 500 ?
                        toColor(posTable.card_color!) : Colors.white,
                        borderRadius: BorderRadius.circular(5.0)
                    ),
                    child: Text(
                      "Group: ${posTable.group}",
                      style:
                      TextStyle(fontSize: 18,
                        color: fontColor(
                            posTable: posTable),
                      ),
                    ),
                  ),
                ),
              ),
              posTable.seats == '2'
                  ?
              Container(
                alignment: Alignment.center,
                child: Image.asset("drawable/two-seat.jpg"),
              )
                  :
              posTable.seats == '4'
                  ?
              Container(
                  alignment: Alignment.center,
                  child: Image.asset("drawable/four-seat.jpg")
              )
                  :
              posTable.seats == '6'
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
                  child: Text(posTable.number!)),
              Visibility(
                visible: MediaQuery.of(context).size.height > 500 ? true : false,
                child: Container(
                    alignment: Alignment.bottomCenter,
                    child: Text(
                        "RM ${posTable.total_amount ?? '0.00'}",
                        style: TextStyle(fontSize: 18))),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Future<Future<Object?>> openLoadingDialogBox(BuildContext context) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
                opacity: a1.value,
                child: WillPopScope(child: LoadingDialog(isTableMenu: true), onWillPop: () async => false)),
          );
        },
        transitionDuration: Duration(milliseconds: 200),
        barrierDismissible: false,
        context: context,
        pageBuilder: (context, animation1, animation2) {
          // ignore: null_check_always_fails
          return null!;
        });
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
}

