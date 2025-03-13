import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:optimy_second_device/main.dart';
import 'package:optimy_second_device/object/client_action.dart';
import 'package:provider/provider.dart';

import '../../notifier/theme_color.dart';
import '../../object/order_cache.dart';
import '../../object/order_detail.dart';
import '../../object/printer.dart';
import '../../translation/AppLocalizations.dart';
import '../../utils/Utils.dart';

class AdjustStockDialog extends StatefulWidget {
  final int orderCacheLocalId;
  final String tableLocalId;
  final String currentBatch;
  final List<OrderCache> orderCacheList;
  final List<OrderDetail> orderDetailList;
  final Function() callBack;
  const AdjustStockDialog(
      {Key? key,
        required this.orderCacheLocalId,
        required this.tableLocalId,
        required this.currentBatch,
        required this.orderCacheList,
        required this.orderDetailList,
        required this.callBack}) : super(key: key);

  @override
  State<AdjustStockDialog> createState() => _AdjustStockDialogState();
}

class _AdjustStockDialogState extends State<AdjustStockDialog> {
  final ClientAction adjustStockAction = clientAction;
  DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
  List<OrderDetail> orderDetailList = [], noStockOrderDetailList = [], removeDetailList = [];
  List<Printer> printerList = [];
  String localTableUseId = '', tableUseKey = '', tableUseDetailKey = '', batchNo = '';
  String? table_use_value, table_use_detail_value, order_cache_value, order_detail_value,
      delete_order_detail_value, order_modifier_detail_value, table_value, branch_link_product_value;
  double newSubtotal = 0.0;
  bool hasNoStockProduct = false, hasNotAvailableProduct = false, tableInUsed = false;
  bool isButtonDisabled = false, isLogOut = false;
  bool willPop = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return WillPopScope(
          child: AlertDialog(
            title: Row(
              children: [
                Text(
                  "Order detail",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                IconButton(
                    onPressed: (){
                      if(removeDetailList.isNotEmpty){
                        if(mounted){
                          setState(() {
                            widget.orderDetailList.addAll(removeDetailList);
                            removeDetailList.clear();
                          });
                          Fluttertoast.showToast(msg: "${AppLocalizations.of(context)?.translate('content_reset_success')}", backgroundColor: Colors.green);
                        }
                      } else {
                        Fluttertoast.showToast(msg: "${AppLocalizations.of(context)?.translate('content_already_reset')}", backgroundColor: Colors.red);
                      }
                    },
                    icon: Icon(Icons.refresh))
              ],
            ),
            content: Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width / 1.5,
              child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: widget.orderDetailList.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    return Dismissible(
                      background: Container(
                        color: Colors.red,
                        padding: EdgeInsets.only(left: 25.0),
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.white),
                          ],
                        ),
                      ),
                      key: ValueKey(widget.orderDetailList[index].productName),
                      direction: DismissDirection.startToEnd,
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          print('detail remove');
                          if (mounted) {
                            setState(() {
                              widget.orderDetailList[index].isRemove = true;
                              removeDetailList.add(widget.orderDetailList[index]);
                              widget.orderDetailList.removeAt(index);
                            });
                          }
                        }
                        return null;
                      },
                      child: Card(
                        elevation: 5,
                        child: Container(
                          margin: EdgeInsets.all(10),
                          //height: MediaQuery.of(context).size.height / 7,
                          child: Column(children: [
                            ListTile(
                              onTap: null,
                              isThreeLine: true,
                              title: RichText(
                                text: TextSpan(
                                  children: <TextSpan>[
                                    TextSpan(
                                        text: "${widget.orderDetailList[index].productName}" + "\n",
                                        style: TextStyle(fontSize: 14, color: Colors.black)),
                                    TextSpan(
                                        text: "$currency_symbol ${widget.orderDetailList[index].price}", style: TextStyle(fontSize: 13, color: Colors.black)),
                                  ],
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Visibility(
                                    visible: widget.orderDetailList[index].product_variant_name != '' ? true : false,
                                    child: Text("(${Utils.formatProductVariant(widget.orderDetailList[index].product_variant_name!)})"),
                                  ),
                                  Visibility(
                                    visible: getOrderDetailModifier(widget.orderDetailList[index]) != '' ? true : false,
                                    child: Text("${getOrderDetailModifier(widget.orderDetailList[index])}"),
                                  ),
                                  widget.orderDetailList[index].remark != '' ? Text("*${widget.orderDetailList[index].remark}") : Text('')
                                ],
                              ),
                              // Text(
                              //     "Add on: ${reformatModifierDetail(orderDetailList[index].modifier_name) + "\n"} "
                              //     "${orderDetailList[index].variant_name +"\n"} "
                              //     "${orderDetailList[index].remark}"
                              // ),
                              trailing: Container(
                                child: FittedBox(
                                  child: Column(
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          IconButton(
                                              hoverColor: Colors.transparent,
                                              icon: Icon(
                                                Icons.remove,
                                                size: 40,
                                              ),
                                              onPressed: () {
                                                print('qty remove');
                                                int qty = int.parse(widget.orderDetailList[index].quantity!);
                                                int totalQty = qty - 1;
                                                if (totalQty <= 0) {
                                                  setState(() {
                                                    widget.orderDetailList[index].isRemove = true;
                                                    removeDetailList.add(widget.orderDetailList[index]);
                                                    widget.orderDetailList.removeAt(index);
                                                  });
                                                } else {
                                                  setState(() {
                                                    widget.orderDetailList[index].quantity = totalQty.toString();
                                                  });
                                                }
                                              }),
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                                            child: Text(
                                              '${widget.orderDetailList[index].quantity}',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(color: Colors.black, fontSize: 30),
                                            ),
                                          ),
                                          IconButton(
                                              hoverColor: Colors.transparent,
                                              icon: Icon(
                                                Icons.add,
                                                size: 40,
                                              ),
                                              onPressed: () {
                                                if (int.parse(widget.orderDetailList[index].quantity!) <
                                                    int.parse(widget.orderDetailList[index].available_stock!)) {
                                                  setState(() {
                                                    int qty = int.parse(widget.orderDetailList[index].quantity!);
                                                    int totalQty = qty + 1;
                                                    widget.orderDetailList[index].quantity = totalQty.toString();
                                                  });
                                                } else {
                                                  Fluttertoast.showToast(backgroundColor: Colors.red, msg: "Out of stock!");
                                                }
                                              })
                                        ],
                                      ),
                                      Text('Available stock: ${widget.orderDetailList[index].available_stock}')
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    );
                  }),
            ),
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
                  onPressed: isButtonDisabled
                      ? null
                      : () {
                    // Disable the button after it has been pressed
                    setState(() {
                      isButtonDisabled = true;
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width / 4,
                height: MediaQuery.of(context).size.height / 12,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  child: Text(
                    'Reject',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: isButtonDisabled
                      ? null
                      : () async {
                    // Disable the button after it has been pressed
                    setState(() {
                      isButtonDisabled = true;
                      willPop = false;
                    });
                    await callRejectOrder(widget.orderCacheLocalId);
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
                    'Add',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: isButtonDisabled ? null : widget.orderDetailList.isNotEmpty ? () async {
                    setState(() {
                      isButtonDisabled = true;
                      willPop = false;
                    });
                    await callAcceptOrder();
                    int status = await decodeData();
                    print("decode status: $status");
                    switch(status){
                      case 0:{
                        enableOtherOperation();
                        Fluttertoast.showToast(backgroundColor: Colors.orangeAccent, msg: "Contain out of stock product");
                      }
                      break;
                      case 2: {
                        enableOtherOperation();
                        Fluttertoast.showToast(backgroundColor: Colors.red, msg: "Contain not available product");
                      }
                      break;
                      case 4: {
                        enableOtherOperation();
                        Fluttertoast.showToast(backgroundColor: Colors.red, msg: "Server side process error");
                      }
                      break;
                      case 5: {
                        widget.callBack();
                        Fluttertoast.showToast(backgroundColor: Colors.red, msg: "Order already accepted");
                        Navigator.of(context).pop();
                      }
                      break;
                      default: {
                        widget.callBack();
                        Navigator.of(context).pop();
                      }
                    }
                    // if(status == 0){
                    //   enableOtherOperation();
                    //   Fluttertoast.showToast(backgroundColor: Colors.orangeAccent, msg: "Contain out of stock product");
                    // } else if(status == 2) {
                    //   enableOtherOperation();
                    //   Fluttertoast.showToast(backgroundColor: Colors.red, msg: "Contain not available product");
                    // } else if (status == 4) {
                    //   enableOtherOperation();
                    //   Fluttertoast.showToast(backgroundColor: Colors.red, msg: "Server side process error");
                    // } else {
                    //   widget.callBack();
                    //   Navigator.of(context).pop();
                    // }
                  } : null,
                ),
              ),
            ],
          ),
          onWillPop: () async => willPop
      );
    });
  }

  enableOtherOperation(){
    if(mounted){
      setState(() {
        isButtonDisabled = false;
        willPop = true;
      });
    }
  }

  callAcceptOrder() async {
    Map<String, dynamic>? objectData;
    objectData = {
      'orderCacheKey': widget.orderDetailList[0].order_cache_key,
      'orderCacheLocalId': widget.orderCacheLocalId.toString(),
      'tableLocalId': widget.tableLocalId,
      'currentBatch': widget.currentBatch,
      'unusedOrderDetail': removeDetailList,
      'multiDeviceOrderDetail': widget.orderDetailList,
    };
    await adjustStockAction.connectRequestPort(action: '22', param: jsonEncode(objectData));
  }

  decodeData(){
    var json = jsonDecode(adjustStockAction.response!);
    return int.parse(json['status']);
  }

  callRejectOrder(int orderCacheLocalId) async {
    await rejectOrder(orderCacheLocalId);
    widget.callBack();
  }

  rejectOrder(int orderCacheLocalId) async {
    await adjustStockAction.connectRequestPort(action: '21', param: orderCacheLocalId.toString());
  }

  getOrderDetailModifier(OrderDetail orderDetail) {
    List<String> modifier = [];
    String result = '';
    if(orderDetail.orderModifierDetail!.isNotEmpty){
      for (int j = 0; j < orderDetail.orderModifierDetail!.length; j++) {
        modifier.add("${orderDetail.orderModifierDetail![j].mod_name!}\n");
      }
      result = modifier.toString().replaceAll('[', '').replaceAll(']', '').replaceAll(', ', '+').replaceFirst('', '+');
    }

    return result;
  }
}
