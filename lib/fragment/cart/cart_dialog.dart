import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:optimy_second_device/main.dart';
import 'package:provider/provider.dart';

import '../../notifier/cart_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/cart_product.dart';
import '../../object/modifier_group.dart';
import '../../object/order_cache.dart';
import '../../object/order_detail.dart';
import '../../object/printer.dart';
import '../../object/table.dart';
import '../../object/table_use_detail.dart';
import '../../object/variant_group.dart';
import '../../page/progress_bar.dart';
import '../../translation/AppLocalizations.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

import '../custom_flushbar.dart';

// import '../table/table_change_dialog.dart';

class CartDialog extends StatefulWidget {
  final List<PosTable> selectedTableList;

  const CartDialog({Key? key, required this.selectedTableList}) : super(key: key);

  @override
  State<CartDialog> createState() => _CartDialogState();
}

class _CartDialogState extends State<CartDialog> {
  FlutterUsbPrinter flutterUsbPrinter = FlutterUsbPrinter();
  List<PosTable> tableList = [], cartSelectedTableList = [];
  List<OrderCache> orderCacheList = [];
  List<OrderDetail> orderDetailList = [];
  List<VariantGroup> variantGroup = [];
  List<ModifierGroup> modifierGroup = [];
  List<TableUseDetail> tbUseDetailList = [];
  List<PosTable> sameGroupTbList = [];
  List<Printer> printerList = [];
  late StreamController controller;
  late CartModel cart;
  double priceSST = 0.0;
  double priceServeTax = 0.0;
  bool isLoad = false;
  bool isFinish = false;
  bool isButtonDisabled = false, isMergeButtonDisabled = false, isLogOut = false;
  Color cardColor = Colors.white;
  String? table_use_detail_value, table_value, tableUseDetailKey;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    controller = StreamController();
    readAllTable();
  }

  disableButton(){
    setState(() {
      isButtonDisabled = true;
    });
  }

  showSecondDialog(BuildContext context, ThemeColor color, int dragIndex, int targetIndex, CartModel cart) {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Confirm merge table'),
        content: SizedBox(
            height: 100.0, width: 350.0, child: Text('merge table ${tableList[dragIndex].number} with table ${tableList[targetIndex].number} ?')),
        actions: <Widget>[
          TextButton(
            child: Text('${AppLocalizations.of(context)?.translate('close')}'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('${AppLocalizations.of(context)?.translate('yes')}'),
            onPressed: () async {
              Navigator.of(context).pop();
              if (tableList[dragIndex].table_sqlite_id != tableList[targetIndex].table_sqlite_id) {
                if (tableList[targetIndex].status == 1 && tableList[dragIndex].status == 0) {
                  await mergeTable(dragTableId: tableList[dragIndex].table_sqlite_id!, targetTableId: tableList[targetIndex].table_sqlite_id!);
                  //await _printTableAddList(dragTable: tableList[dragIndex].number, targetTable: tableList[targetIndex].number);
                  cart.removeAllTable();
                  cart.removeAllCartItem();
                } else {
                  Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "${AppLocalizations.of(context)?.translate('merge_error_2')}");
                }
              } else {
                Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "${AppLocalizations.of(context)?.translate('merge_error')}");
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<CartModel>(builder: (context, CartModel cart, child) {
        this.cart = cart;
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Select Table"),
              Visibility(
                visible: checkIsSelected(),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width / 10,
                  height: MediaQuery.of(context).size.height / 20,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: Colors.red,
                    ),
                    child: Text(
                      'Clear All',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () {
                      for (int i = 0; i < tableList.length; i++) {
                        tableList[i].isSelected = false;
                      }
                      cart.initialLoad();
                      //Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
            ],
          ),
          content: isLoad ?
          SizedBox(
              height: 650,
              width: MediaQuery.of(context).size.width / 2,
              child: Column(
                children: [
                  Expanded(
                    child: ReorderableGridView.count(
                      padding: EdgeInsets.zero,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      crossAxisCount: MediaQuery.of(context).size.height > 500 ? 4 : 3,
                      children: tableList.asMap().map((index, posTable) => MapEntry(index, tableItem(cart, color, index))).values.toList(),
                      onReorder: (int oldIndex, int newIndex) {
                        if (oldIndex != newIndex) {
                          showSecondDialog(context, color, oldIndex, newIndex, cart);
                        }
                      },
                    ),
                  ),
                ],
              ))
              : CustomProgressBar(),
          actions: <Widget>[
            SizedBox(
              width: MediaQuery.of(context).size.width / 4,
              height: MediaQuery.of(context).size.height / 12,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color.backgroundColor,
                ),
                child: Text(
                  'Close',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: isButtonDisabled ? null : () {
                  disableButton();
                  Navigator.of(context).pop();
                },
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width / 4,
              height: MediaQuery.of(context).size.height / 12,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color.buttonColor,
                ),
                child: Text(
                  'Select Table',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: !checkIsSelected() || isButtonDisabled ? null : () async {
                  isButtonDisabled = true;
                  cart.selectedTable.clear();
                  cart.cartNotifierItem.clear();
                  for (int index = 0; index < tableList.length; index++) {
                    //if using table is selected
                    if (tableList[index].status == 1 && tableList[index].isSelected == true) {
                      this.isLoad = false;
                      await readSpecificTableDetail(tableList[index]);
                      this.isLoad = true;
                    }
                    //if non-using table is selected
                    else if (tableList[index].status == 0 && tableList[index].isSelected == true) {
                      //merge all table
                      cart.addTable(tableList[index]);
                    } else {
                      cart.removeSpecificTable(tableList[index]);
                    }
                  }
                  print("orderDetailList: ${orderDetailList.length}");
                  if(orderDetailList.isNotEmpty){
                    addToCart();
                  }
                  if(!mounted) return;
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        );
      });
    });
  }

  bool checkIsSelected() {
    bool selected = false;
    for (int i = 0; i < tableList.length; i++) {
      if (tableList[i].isSelected) {
        selected = true;
        break;
      }
    }
    return selected;
  }

  fontColor({required PosTable posTable}){
    if(posTable.status == 1){
      Color fontColor = Colors.black;
      Color backgroundColor = toColor(posTable.card_color!);
      if(backgroundColor.computeLuminance() > 0.5){
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
      hexColor = "FF$hexColor";
    }
    if (hexColor.length == 8) {
      return Color(int.parse("0x$hexColor"));
    }
  }

  Widget tableItem(CartModel cart, ThemeColor color, index) {
    return Container(
      key: Key(index.toString()),
      child: Column(children: [
        Expanded(
          child: Card(
            elevation: 5,
            shape: tableList[index].isSelected
                ? RoundedRectangleBorder(side: BorderSide(color: color.backgroundColor, width: 3.0), borderRadius: BorderRadius.circular(4.0))
                : RoundedRectangleBorder(side: BorderSide(color: Colors.white, width: 3.0), borderRadius: BorderRadius.circular(4.0)),
            color: Colors.white,
            child: InkWell(
              splashColor: Colors.blue.withAlpha(30),
              onDoubleTap: () {
                if (tableList[index].status == 1) {
                  //openChangeTableDialog(tableList[index], printerList: printerList);
                  cart.removeAllTable();
                  cart.removeAllCartItem();
                } else {
                  Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "table not in use");
                }
              },
              onTap: () async {
                //check selected table is in use or not
                if (tableList[index].status == 1) {
                  // table in use (colored)
                  for (int i = 0; i < tableList.length; i++) {
                    //check all group
                    if (tableList[index].group == tableList[i].group) {
                      if (tableList[i].isSelected == false) {
                        setState(() {
                          tableList[i].isSelected = true;
                        });
                      } else {
                        setState(() {
                          tableList[i].isSelected = false;
                        });
                      }
                    } else {
                      setState(() {
                        tableList[i].isSelected = false;
                      });
                    }
                  }
                } else {
                  //table not in use (white)
                  for (int j = 0; j < tableList.length; j++) {
                    //reset all using table to un-select (table status == 1)
                    if (tableList[j].status == 1) {
                      setState(() {
                        tableList[j].isSelected = false;
                      });
                    }
                  }
                  //for table not in use
                  if (tableList[index].isSelected == false) {
                    setState(() {
                      tableList[index].isSelected = true;
                    });
                  } else if (tableList[index].isSelected == true) {
                    setState(() {
                      tableList[index].isSelected = false;
                    });
                  }
                }
              },
              child: Container(
                margin: EdgeInsets.all(10),
                child: SizedBox(
                  //margin: MediaQuery.of(context).size.height > 500 ? EdgeInsets.fromLTRB(0, 2, 0, 2) : null,
                  height: 100,
                  child: Stack(
                    children: [
                      tableList[index].seats == '2'
                          ? Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage("drawable/two-seat.jpg"),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                          : tableList[index].seats == '4'
                          ? Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage("drawable/four-seat.jpg"),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                          : tableList[index].seats == '6'
                          ? Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage("drawable/six-seat.jpg"),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                          : SizedBox.shrink(),
                      Container(alignment: Alignment.center, child: Text(tableList[index].number!)),
                      tableList[index].group != null ? Row(
                          children: [
                            Container(
                              padding: EdgeInsets.only(right: 5.0, left: 5.0),
                              decoration: BoxDecoration(
                                  color: tableList[index].group != null
                                      ?
                                  toColor(tableList[index].card_color!)
                                      :
                                  Colors.white,
                                  borderRadius: BorderRadius.circular(5.0)
                              ),
                              child: MediaQuery.of(context).size.height > 500 ? Text(
                                "Group: ${tableList[index].group}",
                                style: TextStyle(fontSize: 18, color: fontColor(posTable: tableList[index])),
                              ) : Text(
                                "${tableList[index].group}",
                                style: TextStyle(fontSize: 14, color: fontColor(posTable: tableList[index])),
                              ),
                            ),
                            Spacer(),
                            Visibility(
                                visible: tableList[index].isSelected  ? true : false,
                                child: IconButton(
                                  color: Colors.red,
                                  icon: Icon(Icons.close, size: 18),
                                  constraints: BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                  onPressed: () async {
                                    sameGroupTbList = tableList.where((e) => e.group == tableList[index].group).toList();
                                    // for (int i = 0; i < tableList.length; i++) {
                                    //   if (tableList[index].group == tableList[i].group) {
                                    //     sameGroupTbList.add(tableList[i]);
                                    //   }
                                    // }
                                    if (sameGroupTbList.length > 1) {
                                      await removeMergedTable(tableList[index].table_sqlite_id!);
                                      tableList[index].isSelected = false;
                                      tableList[index].group = null;
                                      cart.removeSpecificTable(tableList[index]);
                                      //cart.removeAllCartItem();
                                    } else {
                                      Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('cannot_remove_this_table'));
                                    }
                                  },
                                ))
                          ])
                          :
                      SizedBox.shrink(),
                    ],
                  ),
                ),
              ),
              // Container(
              //   margin: MediaQuery.of(context).size.height > 500 ? EdgeInsets.all(10) : null,
              //   child: Column(
              //     mainAxisAlignment: MainAxisAlignment.center,
              //     children: [
              //       tableList[index].group != null && MediaQuery.of(context).size.height > 500 ? Row(
              //           children: [
              //             Text("Group: ${tableList[index].group}",
              //               style: TextStyle(fontSize: 18),
              //             ),
              //             Spacer(),
              //             Visibility(
              //                 visible: tableList[index].isSelected ? true : false,
              //                 child: IconButton(
              //                   icon: Icon(Icons.close, size: 18),
              //                   constraints: BoxConstraints(),
              //                   padding: EdgeInsets.zero,
              //                   onPressed: () async {
              //                     sameGroupTbList = [];
              //                     for (int i = 0; i < tableList.length; i++) {
              //                       if (tableList[index].group == tableList[i].group) {
              //                         sameGroupTbList.add(tableList[i]);
              //                       }
              //                     }
              //                     if (sameGroupTbList.length > 1) {
              //                       //await callRemoveTableQuery(tableList[index].table_sqlite_id!);
              //                       tableList[index].isSelected = false;
              //                       tableList[index].group = null;
              //                       cart.removeAllTable();
              //                       cart.removeAllCartItem();
              //                     } else {
              //                       Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "Cannot remove this table");
              //                     }
              //                   },
              //                 ))
              //           ])
              //           :
              //       SizedBox.shrink(),
              //       Container(
              //         //margin: MediaQuery.of(context).size.height > 500 ? EdgeInsets.fromLTRB(0, 2, 0, 2) : null,
              //         height: 100,
              //         child: Stack(
              //           children: [
              //             tableList[index].seats == '2'
              //                 ? Container(
              //               decoration: BoxDecoration(
              //                 image: DecorationImage(
              //                   image: AssetImage("drawable/two-seat.jpg"),
              //                   fit: BoxFit.cover,
              //                 ),
              //               ),
              //             )
              //                 : tableList[index].seats == '4'
              //                 ? Container(
              //               decoration: BoxDecoration(
              //                 image: DecorationImage(
              //                   image: AssetImage("drawable/four-seat.jpg"),
              //                   fit: BoxFit.cover,
              //                 ),
              //               ),
              //             )
              //                 : tableList[index].seats == '6'
              //                 ? Container(
              //               decoration: BoxDecoration(
              //                 image: DecorationImage(
              //                   image: AssetImage("drawable/six-seat.jpg"),
              //                   fit: BoxFit.cover,
              //                 ),
              //               ),
              //             )
              //                 : SizedBox.shrink(),
              //             // Ink.image(
              //             //   image: tableList[index].seats == '2'
              //             //       ? FileImage(File('data/user/0/com.example.pos_system/files/assets/img/two-seat.jpg'))
              //             //   // NetworkImage(
              //             //   //         "https://www.hometown.in/media/cms/icon/Two-Seater-Dining-Sets.png")
              //             //       : tableList[index].seats == '4'
              //             //       ? FileImage(File('data/user/0/com.example.pos_system/files/assets/img/four-seat.jpg'))
              //             //   // NetworkImage(
              //             //   //             "https://www.hometown.in/media/cms/icon/Four-Seater-Dining-Sets.png")
              //             //       : tableList[index].seats == '6'
              //             //       ? FileImage(File('data/user/0/com.example.pos_system/files/assets/img/six-seat.jpg'))
              //             //   // NetworkImage(
              //             //   //                 "https://www.hometown.in/media/cms/icon/Six-Seater-Dining-Sets.png")
              //             //       : FileImage(File('data/user/0/com.example.pos_system/files/assets/img/duitNow.jpg')),
              //             //   // NetworkImage(
              //             //   //                 "https://png.pngtree.com/png-vector/20190820/ourmid/pngtree-no-image-vector-illustration-isolated-png-image_1694547.jpg"),
              //             //   fit: BoxFit.cover,
              //             // ),
              //             // Ink.image(
              //             //   image: tableList[index].seats == '2'
              //             //       ? NetworkImage(
              //             //           "https://www.hometown.in/media/cms/icon/Two-Seater-Dining-Sets.png")
              //             //       : tableList[index].seats == '4'
              //             //           ? NetworkImage(
              //             //               "https://www.hometown.in/media/cms/icon/Four-Seater-Dining-Sets.png")
              //             //           : tableList[index].seats == '6'
              //             //               ? NetworkImage(
              //             //                   "https://www.hometown.in/media/cms/icon/Six-Seater-Dining-Sets.png")
              //             //               : NetworkImage(
              //             //                   "https://png.pngtree.com/png-vector/20190820/ourmid/pngtree-no-image-vector-illustration-isolated-png-image_1694547.jpg"),
              //             //   fit: BoxFit.cover,
              //             // ),
              //             Container(alignment: Alignment.center, child: Text(tableList[index].number!)),
              //           ],
              //         ),
              //       ),
              //       // Container(
              //       //   child: Text(''),
              //       // )
              //       // tableList[index].status == 1
              //       //     ? Expanded(
              //       //       child: Container(
              //       //           alignment: Alignment.topCenter,
              //       //           child: Text(
              //       //             "RM ${tableList[index].total_Amount.toStringAsFixed(2)}",
              //       //             style: TextStyle(fontSize: 18),
              //       //           ),
              //       //         ),
              //       //     )
              //       //     : Expanded(child: Container(child: Text('')))
              //     ],
              //   ),
              // ),
            ),
          ),
        )
      ]),
    );
  }

  // _printTableAddList({dragTable, targetTable}) async {
  //   try {
  //     for (int i = 0; i < widget.printerList.length; i++) {
  //       var printerDetail = jsonDecode(widget.printerList[i].value!);
  //       if (widget.printerList[i].type == 0) {
  //         //print USB 80mm
  //         if (widget.printerList[i].paper_size == 0) {
  //           var data = Uint8List.fromList(await ReceiptLayout().printAddTableList80mm(true, dragTable: dragTable, targetTable: targetTable));
  //           bool? isConnected = await flutterUsbPrinter.connect(int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
  //           if (isConnected == true) {
  //             await flutterUsbPrinter.write(data);
  //           } else {
  //             Fluttertoast.showToast(
  //                 backgroundColor: Colors.red,
  //                 msg: "${AppLocalizations.of(context)?.translate('usb_printer_not_connect')}");
  //           }
  //         } else {
  //           // var data = Uint8List.fromList(await ReceiptLayout().printCheckList58mm(true));
  //           // bool? isConnected = await flutterUsbPrinter.connect(
  //           //     int.parse(printerDetail['vendorId']), int.parse(printerDetail['productId']));
  //           // if (isConnected == true) {
  //           //   await flutterUsbPrinter.write(data);
  //           // } else {
  //           //   Fluttertoast.showToast(
  //           //       backgroundColor: Colors.red,
  //           //       msg: "${AppLocalizations.of(context)?.translate('usb_printer_not_connect')}");
  //           // }
  //         }
  //       } else {
  //         if (widget.printerList[i].paper_size == 0) {
  //           //print LAN 80mm paper
  //           final profile = await CapabilityProfile.load();
  //           final printer = NetworkPrinter(PaperSize.mm80, profile);
  //           final PosPrintResult res = await printer.connect(printerDetail, port: 9100);
  //           if (res == PosPrintResult.success) {
  //             await ReceiptLayout().printCheckList80mm(false, value: printer);
  //             //await ReceiptLayout().printAddTableList80mm(false, value: printer, dragTable: dragTable, targetTable: targetTable);
  //             printer.disconnect();
  //           } else {
  //             Fluttertoast.showToast(
  //                 backgroundColor: Colors.red,
  //                 msg: "${AppLocalizations.of(context)?.translate('lan_printer_not_connect')}");
  //           }
  //         } else {
  //           //print LAN 58mm paper
  //           final profile = await CapabilityProfile.load();
  //           final printer = NetworkPrinter(PaperSize.mm58, profile);
  //           final PosPrintResult res = await printer.connect(printerDetail, port: 9100);
  //           if (res == PosPrintResult.success) {
  //             await ReceiptLayout().printCheckList58mm(false, value: printer);
  //             printer.disconnect();
  //           } else {
  //             Fluttertoast.showToast(
  //                 backgroundColor: Colors.red,
  //                 msg: "${AppLocalizations.of(context)?.translate('lan_printer_not_connect')}");
  //           }
  //         }
  //       }
  //     }
  //   } catch (e) {
  //     print('Printer Connection Error: ${e}');
  //     Fluttertoast.showToast(
  //         backgroundColor: Colors.red,
  //         msg: "${AppLocalizations.of(context)?.translate('printing_error')}");
  //   }
  // }

  // Future<Future<Object?>> openChangeTableDialog(PosTable posTable, {printerList}) async {
  //   return showGeneralDialog(
  //       barrierColor: Colors.black.withOpacity(0.5),
  //       transitionBuilder: (context, a1, a2, widget) {
  //         final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
  //         return Transform(
  //           transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
  //           child: Opacity(
  //               opacity: a1.value,
  //               child: TableChangeDialog(
  //                 object: posTable,
  //                 callBack: () => readAllTable(),
  //               )),
  //         );
  //       },
  //       transitionDuration: Duration(milliseconds: 200),
  //       barrierDismissible: false,
  //       context: context,
  //       pageBuilder: (context, animation1, animation2) {
  //         // ignore: null_check_always_fails
  //         return null!;
  //       });
  // }

  readAllTable({isReset}) async {
    isLoad = false;
    await clientAction.connectRequestPort(action: '7', callback: decodeData);
  }

  decodeData(response){
    try{
      var json = jsonDecode(response);
      Iterable value1 = json['data']['table_list'];
      tableList = List<PosTable>.from(value1.map((json) => PosTable.fromJson(json)));
      if (widget.selectedTableList.isNotEmpty) {
        for (int i = 0; i < widget.selectedTableList.length; i++) {
          for (int j = 0; j < tableList.length; j++) {
            if (tableList[j].table_sqlite_id == widget.selectedTableList[i].table_sqlite_id) {
              tableList[j].isSelected = true;
            }
          }
        }
      }
      if (mounted) {
        setState(() {
          isLoad = true;
        });
      }
    }catch(e){
      print('inti table error: $e');
      tableList = [];
    }
  }

  // resetAllTable() async {
  //   List<PosTable> data = await PosDatabase.instance.readAllTable();
  //   for (int j = 0; j < tableList.length; j++) {
  //     tableList[j].isSelected = false;
  //   }
  // }

  // readAllPrinters() async {
  //   printerList = await PrintReceipt().readAllPrinters();
  // }

  // readAllTableAmount() async {
  //   for (int i = 0; i < tableList.length; i++) {
  //     if(tableList[i].status == 1){
  //       List<TableUseDetail> tableUseDetailData = await PosDatabase.instance.readSpecificTableUseDetail(tableList[i].table_sqlite_id!);
  //
  //       if (tableUseDetailData.isNotEmpty) {
  //         List<OrderCache> data = await PosDatabase.instance.readTableOrderCache(tableUseDetailData[0].table_use_key!);
  //
  //         tableList[i].group = data[0].table_use_sqlite_id;
  //         tableList[i].card_color = data[0].card_color;
  //
  //         // for (int j = 0; j < data.length; j++) {
  //         //   tableList[i].total_Amount += double.parse(data[j].total_amount!);
  //         // }
  //       }
  //     }
  //
  //   }
  //   controller.add('refresh');
  // }

  readSpecificTableDetail(PosTable posTable) async {
    try{
      await clientAction.connectRequestPort(action: '10', param: jsonEncode(posTable), callback: decodeData2);
      //addToCart(cart);
    } catch(e){
      print("response error: $e");
    }
  }

  decodeData2(response) {
    var json = jsonDecode(response);
    Iterable value1 = json['data']['order_detail'];
    Iterable value2 = json['data']['order_cache'];
    //Iterable value3 = json['data']['pos_table'];
    orderDetailList = value1.map((tagJson) => OrderDetail.fromJson(tagJson)).toList();
    orderCacheList = value2.map((tagJson) => OrderCache.fromJson(tagJson)).toList();
    //cartSelectedTableList = value3.map((tagJson) => PosTable.fromJson(tagJson)).toList();
    print("order detail list: ${orderDetailList}");
    print("order cache list: ${orderCacheList}");
  }

  addToCart() {
    getSelectedTable();
    for (int i = 0; i < orderDetailList.length; i++) {
      cartProductItem value = cartProductItem(
        branch_link_product_sqlite_id: orderDetailList[i].branch_link_product_sqlite_id!,
        product_name: orderDetailList[i].productName!,
        category_id: orderDetailList[i].product_category_id!,
        price: orderDetailList[i].price!,
        quantity: int.tryParse(orderDetailList[i].quantity!) != null ? int.parse(orderDetailList[i].quantity!) : double.parse(orderDetailList[i].quantity!),
        orderModifierDetail: orderDetailList[i].orderModifierDetail,
        //modifier: getModifierGroupItem(orderDetailList[i]),
        //variant: getVariantGroupItem(orderDetailList[i]),
        productVariantName: orderDetailList[i].product_variant_name,
        remark: orderDetailList[i].remark!,
        unit: orderDetailList[i].unit,
        per_quantity_unit: orderDetailList[i].per_quantity_unit,
        status: 1,
        category_sqlite_id: orderDetailList[i].category_sqlite_id,
        first_cache_created_date_time: orderCacheList.last.created_at,  //orderCacheList[0].created_at,
        first_cache_batch: orderCacheList.last.batch_id,
        first_cache_order_by: orderCacheList.last.order_by,
      );
      cart.addItem(value);
    }
  }

  void getSelectedTable(){
    if(tableList.isNotEmpty){
      List<PosTable> selectedTableList = tableList.where((e) => e.isSelected == true).toList();
      cart.addAllTable(selectedTableList);
    }
  }

  Future<void> removeMergedTable(int table_sqlite_id) async {
    await clientAction.connectRequestPort(action: '11', param: jsonEncode(table_sqlite_id), callback: decodeData3);
  }

  decodeData3(response) async {
    var json = jsonDecode(response);
    if(json['status'] == '1'){
      await readAllTable();
    } else {
      Navigator.of(context).pop();
      CustomFlushbar.instance.showFlushbar("Remove merged table error", json['exception'], Colors.red, duration: Duration(seconds: 3), (flushbar) async {
        flushbar.dismiss(true);
      });
    }
    print("status: ${json['status']}");
  }

  Future<void> mergeTable({required int dragTableId, required int targetTableId}) async {
    Map<String, int> param = {
      "dragTableId": dragTableId,
      "targetTableId": targetTableId
    };
    await clientAction.connectRequestPort(action: '12', param: jsonEncode(param), callback: decodeData4);
  }

  decodeData4(response) async {
    var json = jsonDecode(response);
    if(json['status'] == '1'){
      await readAllTable();
    } else {
      Navigator.of(context).pop();
      CustomFlushbar.instance.showFlushbar("Merged table error", json['exception'], Colors.red, duration: Duration(seconds: 3), (flushbar) async {
        flushbar.dismiss(true);
      });
    }
  }




  // deleteCurrentTableUseDetail(int currentTableId) async {
  //   print('current delete table local id: ${currentTableId}');
  //   DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
  //   String dateTime = dateFormat.format(DateTime.now());
  //   List<String> _value = [];
  //   try {
  //     List<TableUseDetail> checkData = await PosDatabase.instance.readSpecificTableUseDetail(currentTableId);
  //     print('check data length: ${checkData.length}');
  //     TableUseDetail tableUseDetailObject = TableUseDetail(
  //         sync_status: checkData[0].sync_status == 0 ? 0 : 2,
  //         status: 1,
  //         table_sqlite_id: currentTableId.toString(),
  //         table_use_detail_key: checkData[0].table_use_detail_key,
  //         table_use_detail_sqlite_id: checkData[0].table_use_detail_sqlite_id);
  //     int updatedData = await PosDatabase.instance.deleteTableUseDetailByKey(tableUseDetailObject);
  //     print('update status: ${updatedData}');
  //     if (updatedData == 1) {
  //       TableUseDetail detailData = await PosDatabase.instance.readSpecificTableUseDetailByLocalId(tableUseDetailObject.table_use_detail_sqlite_id!);
  //       _value.add(jsonEncode(detailData));
  //     }
  //     print('tb use detail value: ${_value}');
  //     //sync to cloud
  //     this.table_use_detail_value = _value.toString();
  //     //syncDeletedTableUseDetailToCloud(_value.toString());
  //     // Map data = await Domain().SyncTableUseDetailToCloud(_value.toString());
  //     // if(data['status'] == 1){
  //     //   List responseJson = data['data'];
  //     //   int tablaUseDetailData = await PosDatabase.instance.updateTableUseDetailSyncStatusFromCloud(responseJson[0]['table_use_detail_key']);
  //     // }
  //   } catch (e) {
  //     Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "Delete current table use detail error: ${e}");
  //   }
  // }

  // syncDeletedTableUseDetailToCloud(String value) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     Map data = await Domain().SyncTableUseDetailToCloud(value);
  //     if (data['status'] == '1') {
  //       List responseJson = data['data'];
  //       int tablaUseDetailData = await PosDatabase.instance.updateTableUseDetailSyncStatusFromCloud(responseJson[0]['table_use_detail_key']);
  //     }
  //   }
  // }

  // updatePosTableStatus(int dragTableId, int status, String tableUseDetailKey) async {
  //   List<String> _value = [];
  //   DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
  //   String dateTime = dateFormat.format(DateTime.now());
  //   /*get target table use key here*/
  //   PosTable posTableData = PosTable(table_use_detail_key: tableUseDetailKey, table_sqlite_id: dragTableId, status: status, updated_at: dateTime);
  //   int updatedTable = await PosDatabase.instance.updatePosTableStatus(posTableData);
  //   int updatedKey = await PosDatabase.instance.removePosTableTableUseDetailKey(posTableData);
  //   if (updatedTable == 1 && updatedKey == 1) {
  //     List<PosTable> posTable = await PosDatabase.instance.readSpecificTable(posTableData.table_sqlite_id.toString());
  //     _value.add(jsonEncode(posTable[0]));
  //   }
  //   print('table value: ${_value}');
  //   //sync to cloud
  //   this.table_value = _value.toString();
  //   //syncUpdatedTableToCloud(_value.toString());
  //   // Map response = await Domain().SyncUpdatedPosTableToCloud(_value.toString());
  //   // if (response['status'] == '1') {
  //   //   List responseJson = response['data'];
  //   //   int syncData = await PosDatabase.instance.updatePosTableSyncStatusFromCloud(responseJson[0]['table_id']);
  //   // }
  // }

  // syncUpdatedTableToCloud(String value) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     Map response = await Domain().SyncUpdatedPosTableToCloud(value);
  //     if (response['status'] == '1') {
  //       List responseJson = response['data'];
  //       int syncData = await PosDatabase.instance.updatePosTableSyncStatusFromCloud(responseJson[0]['table_id']);
  //     }
  //   }
  // }

  // callAddNewTableQuery(int dragTableId, int targetTableId) async {
  //   //List<TableUseDetail> checkData = await PosDatabase.instance.readSpecificTableUseDetail(targetTableId);
  //   await createTableUseDetail(dragTableId, targetTableId);
  //   await updatePosTableStatus(dragTableId, 1, this.tableUseDetailKey!);
  //   await syncAllToCloud();
  //   if (this.isLogOut == true) {
  //     openLogOutDialog();
  //     return;
  //   }
  //   await readAllTable(isReset: true);
  // }

  // generateTableUseDetailKey(TableUseDetail tableUseDetail) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final int? device_id = prefs.getInt('device_id');
  //   var bytes = tableUseDetail.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') +
  //       tableUseDetail.table_use_detail_sqlite_id.toString() +
  //       device_id.toString();
  //   return md5.convert(utf8.encode(bytes)).toString();
  // }

  // insertTableUseDetailKey(TableUseDetail tableUseDetail, String dateTime) async {
  //   String? tableUseDetailKey;
  //   TableUseDetail? _tableUseDetailData;
  //   tableUseDetailKey = await generateTableUseDetailKey(tableUseDetail);
  //   if (tableUseDetailKey != null) {
  //     TableUseDetail tableUseDetailObject = TableUseDetail(
  //         table_use_detail_key: tableUseDetailKey,
  //         sync_status: 0,
  //         updated_at: dateTime,
  //         table_use_detail_sqlite_id: tableUseDetail.table_use_detail_sqlite_id);
  //     int data = await PosDatabase.instance.updateTableUseDetailUniqueKey(tableUseDetailObject);
  //     if (data == 1) {
  //       TableUseDetail detailData = await PosDatabase.instance.readSpecificTableUseDetailByLocalId(tableUseDetailObject.table_use_detail_sqlite_id!);
  //       _tableUseDetailData = detailData;
  //     }
  //   }
  //   return _tableUseDetailData;
  // }

  // createTableUseDetail(int newTableId, int oldTableId) async {
  //   DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
  //   String dateTime = dateFormat.format(DateTime.now());
  //   List<String> _value = [];
  //   try {
  //     //read table use detail data based on target table id
  //     List<TableUseDetail> tableUseDetailData = await PosDatabase.instance.readSpecificTableUseDetail(oldTableId);
  //     List<PosTable> tableData = await PosDatabase.instance.readSpecificTable(newTableId.toString());
  //
  //     //create table use detail
  //     TableUseDetail insertData = await PosDatabase.instance.insertSqliteTableUseDetail(TableUseDetail(
  //         table_use_detail_id: 0,
  //         table_use_detail_key: '',
  //         table_use_sqlite_id: tableUseDetailData[0].table_use_sqlite_id,
  //         table_use_key: tableUseDetailData[0].table_use_key,
  //         table_sqlite_id: newTableId.toString(),
  //         table_id: tableData[0].table_id.toString(),
  //         created_at: dateTime,
  //         status: 0,
  //         sync_status: 0,
  //         updated_at: '',
  //         soft_delete: ''));
  //     TableUseDetail updatedDetail = await insertTableUseDetailKey(insertData, dateTime);
  //     this.tableUseDetailKey = updatedDetail.table_use_detail_key;
  //     _value.add(jsonEncode(updatedDetail));
  //     //sync to cloud
  //     this.table_use_detail_value = _value.toString();
  //     //syncTableUseDetailToCloud(_value.toString());
  //   } catch (e) {
  //     print('create table use detail error: $e');
  //     Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "Create table detail error: ${e}");
  //   }
  // }

  // syncTableUseDetailToCloud(String value) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     Map data = await Domain().SyncTableUseDetailToCloud(value);
  //     if (data['status'] == '1') {
  //       List responseJson = data['data'];
  //       int syncData = await PosDatabase.instance.updateTableUseDetailSyncStatusFromCloud(responseJson[0]['table_use_detail_key']);
  //     }
  //   }
  // }

  // syncAllToCloud() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final int? device_id = prefs.getInt('device_id');
  //   final String? login_value = prefs.getString('login_value');
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     Map data = await Domain().syncLocalUpdateToCloud(
  //         device_id: device_id.toString(), value: login_value, table_use_detail_value: this.table_use_detail_value, table_value: this.table_value);
  //     if (data['status'] == '1') {
  //       List responseJson = data['data'];
  //       for (int i = 0; i < responseJson.length; i++) {
  //         switch (responseJson[i]['table_name']) {
  //           case 'tb_table_use_detail':
  //             {
  //               await PosDatabase.instance.updateTableUseDetailSyncStatusFromCloud(responseJson[i]['table_use_detail_key']);
  //             }
  //             break;
  //           case 'tb_table':
  //             {
  //               await PosDatabase.instance.updatePosTableSyncStatusFromCloud(responseJson[i]['table_id']);
  //             }
  //             break;
  //           default:
  //             {
  //               return;
  //             }
  //         }
  //       }
  //     } else if (data['status'] == '7') {
  //       this.isLogOut = true;
  //     }
  //   }
  // }
}
