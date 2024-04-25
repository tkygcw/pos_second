import 'dart:convert';

import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:optimy_second_device/fragment/cart/reprint_kitchen_list_function.dart';
import 'package:optimy_second_device/fragment/custom_flushbar.dart';
import 'package:optimy_second_device/notifier/theme_color.dart';
import 'package:optimy_second_device/object/order.dart';
import 'package:optimy_second_device/object/order_detail.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../notifier/fail_print_notifier.dart';
import '../../translation/AppLocalizations.dart';
import '../../utils/Utils.dart';

class ReprintKitchenListDialog extends StatefulWidget {
  const ReprintKitchenListDialog({Key? key}) : super(key: key);

  @override
  State<ReprintKitchenListDialog> createState() => _ReprintKitchenListDialogState();
}

class _ReprintKitchenListDialogState extends State<ReprintKitchenListDialog> {
  ReprintKitchenListFunction reprintFunc = ReprintKitchenListFunction();
  late FailPrintModel model;
  late ThemeColor color;
  //List<OrderDetail> orderDetail = [];
  bool isButtonDisable = false, closeButtonDisable = false;
  // Set<String> selectedOrder = {};

  @override
  void initState() {
    super.initState();
    // orderDetail.addAll(FailPrintModel.instance.failedPrintOrderDetail);
  }


  @override
  Widget build(BuildContext context) {
    print("Upper rebuild called!!!");
    model = context.watch<FailPrintModel>();
    color = context.watch<ThemeColor>();
    return AlertDialog(
      title: buildTitle(context),
      content: buildContent(context),
      actions: buildAction(context),
    );
  }

  Widget buildTitle(BuildContext context){
    return Row(
      children: [
        Text(AppLocalizations.of(context)!.translate('fail_print_order_detail')),
        Spacer(),
        Visibility(
          visible: model.failPrintOrderDetails.isEmpty ? false : true,
          child: Row(
            children: [
              Checkbox(
                  value: model.isSelectAll,
                  onChanged: (value){
                    reprintFunc.checkChange(value: value);
                  }),
              Container(
                height: 30,
                child: VerticalDivider(color: Colors.grey, thickness: 1),
              ),
              IconButton(
                  onPressed: () async {
                    if (await confirm(
                      context,
                      title: Text("${AppLocalizations.of(context)!.translate('confirm_remove_all_order_detail')}"),
                      content: Text('${AppLocalizations.of(context)!.translate('confirm_remove_all_order_detail_desc')}'),
                      textOK: Text('${AppLocalizations.of(context)!.translate('yes')}'),
                      textCancel: Text('${AppLocalizations.of(context)!.translate('no')}'),
                    )) {
                      model.removeAllFailedOrderDetail();
                    }
                  },
                  icon: Icon(Icons.delete_forever, color: Colors.red))
            ],
          ),
        )
      ],
    );
  }

  Widget buildContent(BuildContext context){
    return Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height / 2),
        width: 500,
        child: model.failPrintOrderDetails.isNotEmpty ?
        ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: reprintFunc.groupOrder().length,
          itemBuilder: (context, groupIndex) {
            String cardID = reprintFunc.groupOrder().keys.elementAt(groupIndex);
            List<OrderDetail> items = reprintFunc.groupOrder()[cardID]!;

            bool isOrderSelected = model.isSelectAll ? true : model.selectedOrder.contains(cardID);
            if(model.isSelectAll) {
              model.selectedOrder.add(cardID);
            }
            return Card(
              elevation: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Row(
                      children: [
                        ///Select-all order checkbox in card
                        Checkbox(
                          value: isOrderSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value != null) {
                                if (!value) {
                                  model.selectedOrder.remove(cardID);
                                  reprintFunc.checkAllOrderItem(value, items);
                                } else {
                                  model.selectedOrder.add(cardID);
                                  reprintFunc.checkAllOrderItem(value, items);
                                }
                              }
                            });
                          },
                        ),
                        Text(items.first.orderQueue != '' ? "${AppLocalizations.of(context)!.translate('order_no')}: $cardID"
                            : items.first.tableNumber.toString() != '[]' ? "${AppLocalizations.of(context)!.translate('table_no')}: $cardID"
                            : "TakeAway/Delivery - ${Utils.formatDate(items.first.created_at!.toString())}"),
                      ],
                    ),
                    subtitle: Container(
                      padding: EdgeInsets.symmetric(horizontal: 15.0),
                      child: Text(
                        "${AppLocalizations.of(context)!.translate('item_count')}: ${items.length}",
                        style: TextStyle(
                          // Add your desired style properties here, for example:
                          color: Colors.grey,
                          fontSize: 14.0,
                        ),
                      ),
                    ),
                    onTap: () {
                      // setState(() {
                      //   print("isOrderSelected: ${isOrderSelected}");
                      //   if (isOrderSelected) {
                      //     selectedOrder.remove(cardID);
                      //     checkAllOrderItem(false, items);
                      //   } else {
                      //     selectedOrder.add(cardID);
                      //     checkAllOrderItem(true, items);
                      //     checkIsLastOrder();
                      //   }
                      // });
                    },
                  ),
                  if (isOrderSelected)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        children: [
                          ...items.asMap().entries.map((entry) {
                            int itemIndex = entry.key;
                            OrderDetail item = entry.value;
                            ///item checkbox
                            return CheckboxListTile(
                              isThreeLine: true,
                              secondary: Text("x${item.quantity}"),
                              title: Text("${item.productName}"),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Visibility(
                                    visible: reprintFunc.getProductVariant(item) != '' ? true : false,
                                    child: Text(reprintFunc.getProductVariant(item)),
                                  ),
                                  Visibility(
                                    visible: reprintFunc.getModifier(item) != '' ? true : false,
                                    child: Text(reprintFunc.getModifier(item)),
                                  ),
                                  Visibility(
                                    visible: reprintFunc.getRemark(item) != '' ? true : false,
                                    child: Text(reprintFunc.getRemark(item)),
                                  ),
                                ],
                              ),
                              value: item.isSelected,
                              onChanged: (value) {
                                setState(() {
                                  item.isSelected = value!;
                                  reprintFunc.checkIsLastOrder();
                                  reprintFunc.checkIsLastItem(items, cardID);
                                });
                              },
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ) :
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.print_disabled),
            Text("${AppLocalizations.of(context)!.translate('no_fail_print_order_detail')}"),
          ],
        )
    );
  }

  List<Widget> buildAction(BuildContext context){
    return [
      SizedBox(
        width: MediaQuery.of(context).size.width / 4,
        height: MediaQuery.of(context).size.height / 12,
        child: ElevatedButton(
            onPressed: isButtonDisable || model.failPrintOrderDetails.isEmpty  ? null : () async {
              //List<String> keyList = reprintFunc.groupOrder().keys.toList();
              // for(int i = 0; i < keyList.length; i++){
              //   List<OrderDetail>? orderDetail = reprintFunc.groupOrder()[keyList[i]];
              //   print("order detail length: ${orderDetail!.length}");
              // }

              //disableButton();
              await callPrinter();
            },
            child: Text(AppLocalizations.of(context)!.translate('reprint'))),
      ),
      SizedBox(
          width: MediaQuery.of(context).size.width / 4,
          height: MediaQuery.of(context).size.height / 12,
          child: ElevatedButton(
              onPressed: closeButtonDisable ? null : (){
                setState(() {
                  closeButtonDisable = true;
                });
                closeDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: color.backgroundColor,
              ),
              child: Text(AppLocalizations.of(context)!.translate('close')))
      ),
    ];
  }

  callPrinter() async {
    //List<OrderDetail> selectedList = model.failPrintOrderDetails.where((e) => e.isSelected == true).toList();
    List<OrderDetail> batchOrderDetailList = [];
    batchOrderDetailList.addAll(model.failPrintOrderDetails);
    model.removeAllFailedOrderDetail();
    Navigator.of(context).pop();
    //print("order detail batch: ${batchOrderDetailList[0].failPrintBatch}");
    await clientAction.connectRequestPort(action: '14', param: jsonEncode(batchOrderDetailList), callback: responseStatusCheck);
  }

  void responseStatusCheck(response){
    var json = jsonDecode(response);
    print("status: ${json['status']}");
    switch(json['status']){
      case '0': {
        if(mounted){
          clientAction.openReconnectDialog(action: json['action'], param: json['param'], callback: responseStatusCheck);
        }
      }break;
      case '2': {
        model.removeAllFailedOrderDetail();
        Navigator.of(context).pop();
      }break;
    }
  }

  closeDialog(){
    reprintFunc.resetOrderDetail();
    Navigator.of(context).pop();
  }
}
