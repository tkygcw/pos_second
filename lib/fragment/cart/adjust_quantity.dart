import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quantity_input/quantity_input.dart';

import '../../main.dart';
import '../../notifier/cart_notifier.dart';
import '../../notifier/table_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/cart_product.dart';
import '../../translation/AppLocalizations.dart';

class AdjustQuantityDialog extends StatefulWidget {
  final cartProductItem cartItem;
  final String currentPage;
  const AdjustQuantityDialog({Key? key, required this.cartItem, required this.currentPage}) : super(key: key);

  @override
  State<AdjustQuantityDialog> createState() => _AdjustQuantityDialogState();
}

class _AdjustQuantityDialogState extends State<AdjustQuantityDialog> {
  final adminPosPinController = TextEditingController();
  int simpleIntInput = 1, status = 0;
  bool _submitted = false;
  bool willPop = true;
  bool isButtonDisabled = false;
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
      return Consumer<CartModel>(builder: (context, CartModel cart, child) {
        return Consumer<TableModel>(builder: (context, TableModel tableModel, child) {
          this.tableModel = tableModel;
          return AlertDialog(
            title: const Text('Adjust Quantity'),
            content: QuantityInput(
                inputWidth: 273,
                maxValue: widget.cartItem.quantity,
                minValue: 0,
                readOnly: true,
                acceptsNegatives: false,
                decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors.black),
                  ),
                ),
                buttonColor: Colors.black,
                value: simpleIntInput,
                onChanged: (value) => setState(() =>
                simpleIntInput = int.parse(value.replaceAll(',', '')))),
            actions: <Widget>[
              TextButton(
                child: Text('${AppLocalizations.of(context)?.translate('close')}'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('${AppLocalizations.of(context)?.translate('yes')}'),
                onPressed: isButtonDisabled ? null : () async {
                  await showSecondDialog(context, color, cart);
                },
              ),
            ],
          );
        });
      });
    });
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
