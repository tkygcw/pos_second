import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:optimy_second_device/fragment/cart/cancel_item/quantity_input_widget.dart';
import 'package:optimy_second_device/fragment/cart/cancel_item/reason_input_widget.dart';
import 'package:optimy_second_device/fragment/custom_pin_dialog.dart';
import 'package:optimy_second_device/fragment/table/table_view_function.dart';
import 'package:optimy_second_device/notifier/app_setting_notifier.dart';
import 'package:optimy_second_device/object/cancel_item_data.dart';
import 'package:provider/provider.dart';
import 'package:quantity_input/quantity_input.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../main.dart';
import '../../../notifier/cart_notifier.dart';
import '../../../notifier/table_notifier.dart';
import '../../../notifier/theme_color.dart';
import '../../../object/cart_product.dart';
import '../../../object/user.dart';
import '../../../translation/AppLocalizations.dart';
import '../../toast/custom_toastification.dart';

class AdjustQuantityDialog extends StatefulWidget {
  final cartProductItem cartItem;
  final String currentPage;
  const AdjustQuantityDialog({Key? key, required this.cartItem, required this.currentPage}) : super(key: key);

  @override
  State<AdjustQuantityDialog> createState() => _AdjustQuantityDialogState();
}

class _AdjustQuantityDialogState extends State<AdjustQuantityDialog> {
  final appSettingModel = AppSettingModel.instance;
  final adminPosPinController = TextEditingController();
  num simpleIntInput = 1, status = 0;
  bool _submitted = false;
  bool willPop = true;
  bool isButtonDisabled = false;
  bool restock = false;
  String reason = '';
  late TableModel tableModel;


  String? get errorPassword {
    final text = adminPosPinController.value.text;
    //readAdminData(text);
    if (text.isEmpty) {
      return 'password_required';
    }
    return null;
  }

  void _submit(BuildContext context, CartModel cart) async {
    setState(() => _submitted = true);
    if (errorPassword == null) {
      await readAdminData(adminPosPinController.text, cart: cart);
      cart.removeAllTable();
      cart.removeAllCartItem();
      cart.removePromotion();
      tableModel.changeContent(true);
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    } else {
      setState(() {
        isButtonDisabled = false;
      });
    }
  }


  Future showSecondDialog(BuildContext context, ThemeColor color, CartModel cart) {
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, StateSetter setState){
            return WillPopScope(
              onWillPop: () async => willPop,
              child: Center(
                child: SingleChildScrollView(
                  physics: NeverScrollableScrollPhysics(),
                  child: AlertDialog(
                    title: Text('Enter Current User PIN'),
                    content: SizedBox(
                      height: 100.0,
                      width: 350.0,
                      child: ValueListenableBuilder(
                          valueListenable: adminPosPinController,
                          builder: (context, TextEditingValue value, __) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextField(
                                obscureText: true,
                                controller: adminPosPinController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  errorText: _submitted
                                      ? errorPassword == null
                                      ? errorPassword
                                      : AppLocalizations.of(context)
                                      ?.translate(errorPassword!)
                                      : null,
                                  border: OutlineInputBorder(
                                    borderSide:
                                    BorderSide(color: color.backgroundColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide:
                                    BorderSide(color: color.backgroundColor),
                                  ),
                                  labelText: "PIN",
                                ),
                              ),
                            );
                          }),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: Text('${AppLocalizations.of(context)?.translate('close')}'),
                        onPressed: isButtonDisabled ? null :  () {
                          setState(() {
                            isButtonDisabled = true;
                          });
                          Navigator.of(context).pop();
                          setState(() {
                            isButtonDisabled = false;
                          });
                        },
                      ),
                      TextButton(
                        child: Text('${AppLocalizations.of(context)?.translate('yes')}'),
                        onPressed: isButtonDisabled ? null : () {
                          setState(() {
                            isButtonDisabled = true;
                            willPop = false;
                          });
                          _submit(context, cart);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          });
        }
    );
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return AlertDialog(
        title: const Text('Adjust Quantity'),
        content: SizedBox(
          width: 350,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                //reason input
                Visibility(
                  visible: appSettingModel.required_cancel_reason!,
                  child: ReasonInputWidget(reasonCallBack: reasonCallBack),
                ),
                // quantity input
                QuantityInputWidget(
                  cartItemList: [widget.cartItem],
                  callback: qtyInputCallback,
                )
              ],
            ),
          ),
        ),
        actions: <Widget>[
          SizedBox(
            width: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.width / 6 : MediaQuery.of(context).size.width / 4,
            height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500
                ? MediaQuery.of(context).size.height / 12
                : MediaQuery.of(context).orientation == Orientation.landscape ? MediaQuery.of(context).size.height / 10
                : MediaQuery.of(context).size.height / 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color.backgroundColor,
              ),
              child: Text(
                AppLocalizations.of(context)!.translate('close'),
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                setState(() {
                  isButtonDisabled = true;
                });
                Navigator.of(context).pop();
                setState(() {
                  isButtonDisabled = false;
                });
              },
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.width / 6 : MediaQuery.of(context).size.width / 4,
            height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500
                ? MediaQuery.of(context).size.height / 12
                : MediaQuery.of(context).orientation == Orientation.landscape ? MediaQuery.of(context).size.height / 10
                : MediaQuery.of(context).size.height / 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color.buttonColor,
              ),
              onPressed: isButtonDisabled ? null : cancelOnPressed,
              child: Text(
                AppLocalizations.of(context)!.translate('yes'),
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      );
    });
  }

  qtyInputCallback({bool? restock, num? qty}){
    simpleIntInput = qty ?? this.simpleIntInput;
    this.restock = restock ?? this.restock;
  }

  reasonCallBack(String reason){
    this.reason = reason;
  }

  cancelOnPressed() async {
    setState(() {
      isButtonDisabled = true;
    });
    if(appSettingModel.required_cancel_reason! == true && reason == ''){
      CustomFailedToast(title: AppLocalizations.of(context)!.translate('reason_required')).showToast();
      setState(() {
        isButtonDisabled = false;
      });
      return;
    }
    if(simpleIntInput != 0 && simpleIntInput != 0.00){
      final prefs = await SharedPreferences.getInstance();
      final String? pos_user = prefs.getString('pos_pin_user');
      Map<String, dynamic> userMap = json.decode(pos_user!);
      User userData = User.fromJson(userMap);
      if(simpleIntInput > widget.cartItem.quantity!){
        CustomFailedToast(title: AppLocalizations.of(context)!.translate('quantity_invalid')).showToast();
        setState(() {
          isButtonDisabled = false;
        });
      } else {
        if(userData.edit_price_without_pin != 1) {
          Navigator.of(context).pop();
          ShowCustomPinDialog(permission: Permission.cancelItem).showPinDialog(
            context, () async => await callCancelItem(userData.user_id!),
          );
        } else {
          //Send cancel item request to main pos
          await callCancelItem(userData.user_id!);
        }
      }
    } else { //no changes
      Navigator.of(context).pop();
    }
  }

  Future<void> callCancelItem(int userId) async {
    var data = CancelItemData(
      userId: userId,
      orderDetailSqliteId: int.parse(widget.cartItem.order_detail_sqlite_id!),
      restock: restock,
      cancelQty: simpleIntInput,
      reason: reason,
      selectedTable: CartModel.instance.selectedTable
    );
    await clientAction.connectRequestPort(action: '27', param: jsonEncode(data), callback: (response)=> _decodeResponse(response, data));
  }

  void _decodeResponse(response, data){
    try{
      var json = jsonDecode(clientAction.response!);
      String status = json['status'];
      switch(status){
        case '1': {
          CustomSuccessToast(title: "Delete successful").showToast();
          CartModel.instance.initialLoad();
        }break;
        case '2': {
          CustomSuccessToast(title: AppLocalizations.of(context)!.translate('order_is_in_payment')).showToast();
          CartModel.instance.initialLoad();
        }break;
        default: {
          clientAction.openReconnectDialog(action: '27', param: jsonEncode(data), callback: (response) => _decodeResponse(response, data));
        }
      }
    }catch(e){
      print('init table error: $e');
      //readAllTable();
    }
  }

  readAdminData(String pin, {required CartModel cart}) async {
    Map<String, dynamic>? objectData;
    objectData = {
      'quantityInput': simpleIntInput.toString(),
      'current_page': widget.currentPage,
      'cart_item': widget.cartItem,
      'pin': pin,
    };
    //clientAction.sendRequest(action: 'abc', param: '');
    await clientAction.connectRequestPort(action: '16', param: jsonEncode(objectData));
    decodeData();
  }

  decodeData(){
    try{
      var json = jsonDecode(clientAction.response!);
      status = int.parse(json['status']);
      print("return status: $status");
    } catch(e){
      print("decode data error: $e");
      status = 0;
    }
  }
}
