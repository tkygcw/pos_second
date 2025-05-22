import 'package:flutter/material.dart';
import 'package:optimy_second_device/fragment/table/table_view_function.dart';
import 'package:optimy_second_device/fragment/toast/custom_toastification.dart';
import 'package:optimy_second_device/main.dart';
import 'package:optimy_second_device/notifier/table_notifier.dart';
import 'package:optimy_second_device/notifier/theme_color.dart';
import 'package:optimy_second_device/object/cart_product.dart';
import 'package:optimy_second_device/object/order_cache.dart';
import 'package:optimy_second_device/object/order_detail.dart';
import 'package:optimy_second_device/object/table.dart';
import 'package:optimy_second_device/page/progress_bar.dart';
import 'package:provider/provider.dart';

import '../../notifier/cart_notifier.dart';
import '../../page/loading_dialog.dart';
import '../../translation/AppLocalizations.dart';

final tableViewFunc = TableViewFunction();

class TableView extends StatefulWidget {
  final ThemeColor themeColor;
  final bool? changeTable;
  final PosTable? changeTableFrom;
  const TableView({super.key, required this.themeColor, this.changeTable, this.changeTableFrom});

  @override
  State<TableView> createState() => _TableViewState();
}

class _TableViewState extends State<TableView> {
  late Future<void> _readTableFromServer;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _readTableFromServer = Provider.of<TableModel>(context, listen: false).getTableFromServer(resetMainPosOrderCache: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CartModel>(context, listen: false).initialLoad();
    });
  }

  @override
  Widget build(BuildContext context) {
    var color = widget.themeColor;
    return FutureBuilder(
      future: _readTableFromServer,
      builder: (context, snapshot) {
        switch(snapshot.connectionState){
          case ConnectionState.waiting:
            return CustomProgressBar();
          default :
            if(snapshot.hasError){
              return Center(
                child: Text("Check main pos version"),
              );
            } else {
              return Consumer<TableModel>(
                  builder: (context, tableModel, child) {
                    return GridView.count(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      crossAxisCount: widget.changeTable != true ? crossAxisCount : changeTableCrossAxisCount,
                      children: List.generate(
                          tableModel.notifierTableList.length, (index) {
                        return _TableCard(
                          posTable: tableModel.notifierTableList[index],
                          color: color,
                          changeTable: widget.changeTable,
                          changeTableFrom: widget.changeTableFrom,
                        );
                      }),
                    );
                  });
            }
        }
      }
    );
  }

  int get changeTableCrossAxisCount {
    var orientation = MediaQuery.of(context).orientation;
    if(orientation == Orientation.landscape){
      return 4;
    } else {
      return 2;
    }
  }

  int get crossAxisCount {
    var screenSize = MediaQuery.of(context).size;
    if(MediaQuery.of(context).orientation == Orientation.landscape){
      if(screenSize.width > 900 && screenSize.height > 500){
        return 5;
      } else {
        return 3;
      }
    } else {
      if(screenSize.width > 500 && screenSize.height > 500){
        return 4;
      } else {
        return 3;
      }
    }
  }
}

class _TableCard extends StatelessWidget {
  final ThemeColor color;
  final PosTable posTable;
  final bool? changeTable;
  final PosTable? changeTableFrom;
  const _TableCard({super.key, required this.posTable, required this.color, this.changeTable, this.changeTableFrom});

  @override
  Widget build(BuildContext context) {
    var cart = context.read<CartModel>();
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
      shape: isInCart ? RoundedRectangleBorder(
          side: BorderSide(color: color.backgroundColor, width: 3.0),
          borderRadius: BorderRadius.circular(4.0)) : RoundedRectangleBorder(
          side: BorderSide(
              color: Colors.white, width: 3.0),
          borderRadius:
          BorderRadius.circular(4.0)),
      elevation: 5,
      child: InkWell(
        splashColor: Colors.blue.withAlpha(30),
        onDoubleTap: changeTable == true ? null : () {
          if (posTable.status != 1) {
            //openAddTableDialog(tableList[index]);
          } else {
            openChangeTableDialog(context, color, posTable);
          }
        },
        onTap: () async {
          await cardOnTap(context, isInCart, cart);
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
                      groupText(context),
                      style:
                      TextStyle(fontSize: 18,
                        color: fontColor(
                            posTable: posTable),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                  alignment: Alignment.center,
                  child: Image.asset("drawable/four-seat.jpg")
              ),
              Container(
                  alignment: Alignment.center,
                  child: Text(posTable.number!)),
              Visibility(
                visible: MediaQuery.of(context).size.height > 500 && changeTable != true ? true : false,
                child: Container(
                    alignment: Alignment.bottomCenter,
                    child: Text(
                        "$currency_symbol ${posTable.total_amount ?? '0.00'}",
                        style: TextStyle(fontSize: 18))),
              ),

            ],
          ),
        ),
      ),
    );
  }

  String groupText(BuildContext context) {
    var orientation = MediaQuery.of(context).orientation;
    if(changeTable == true && orientation == Orientation.portrait){
      return posTable.group ?? '';
    } else {
      return "Group: ${posTable.group}";
    }
  }

  cardOnTap(BuildContext context, bool isInCart, CartModel cart) async {
    if(changeTable == true){
      Navigator.of(context).pop();
      //change table func
      var startTableNumber = changeTableFrom!.number!;
      var destinationTableNumber = posTable.number!;
      if(startTableNumber != destinationTableNumber){
        int status = await tableViewFunc.changeTable(startTableNum: startTableNumber, destinationTableNum: destinationTableNumber);
        if(status == 2){
          CustomFailedToast(title: AppLocalizations.of(context)!.translate('order_is_in_payment')).showToast();
        }
      } else {
        CustomFailedToast(title: "Cannot change to same table").showToast();
      }
    } else {
      openLoadingDialogBox(context);
      Future.delayed(Duration(milliseconds: 500), () async {
        if(isInCart){
          tableViewFunc.unselectSpecificSubPosOrderCache(posTable.table_use_key!);
          cart.removeGroupedTable(posTable);
          cart.removeSpecificItem(posTable.table_use_key);
        } else {
          if(posTable.status == 1){
            int status = await tableViewFunc.readSpecificTableDetail(posTable);
            if(status == 1){
              List<OrderDetail> orderDetail = tableViewFunc.orderDetailList;
              List<OrderCache> orderCache = tableViewFunc.orderCacheList;
              List<cartProductItem> itemList = [];
              for(var order in orderDetail){
                var item = cartProductItem(
                  order_detail_sqlite_id: order.order_detail_sqlite_id.toString(),
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
                  first_cache_created_date_time: orderCache.last.created_at,
                  first_cache_batch: orderCache.last.batch_id,
                  table_use_key: orderCache.last.table_use_key,
                  per_quantity_unit: order.per_quantity_unit,
                  status: 0,
                  category_id: order.product_category_id,
                );
                itemList.add(item);
              }
              cart.addAllItem(itemList, notifyListener: false);
              cart.addTable(posTable);
              cart.setCurrentOrderCache = orderCache;
            } else {
              CustomFailedToast(title: AppLocalizations.of(context)!.translate('order_is_in_payment')).showToast();
            }
          } else {
            CustomFailedToast(title: AppLocalizations.of(context)!.translate('table_not_in_used')).showToast();
          }
        }
        Navigator.of(context).pop();
      });
    }
  }

  Future<Future<Object?>> openChangeTableDialog(BuildContext context, ThemeColor color, PosTable selectedTable) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
                opacity: a1.value,
                child: AlertDialog(
                  title: Text("Change table to"),
                  content: SizedBox(
                    height: MediaQuery.of(context).size.height / 2,
                    width: MediaQuery.of(context).size.width / 2,
                    child: TableView(themeColor: color, changeTable: true, changeTableFrom: selectedTable,),
                  ),
                  actions: [
                    ElevatedButton.icon(
                      onPressed: ()=> Navigator.of(context).pop(),
                      label: Text("Close"),
                      icon: Icon(Icons.close),
                    )
                  ],
                )
            ),
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

