import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:optimy_second_device/fragment/toast/custom_toastification.dart';
import 'package:optimy_second_device/main.dart';
import 'package:optimy_second_device/object/cart_product.dart';
import 'package:provider/provider.dart';

import '../notifier/theme_color.dart';
import '../object/user.dart';
import '../translation/AppLocalizations.dart';

enum Permission {
  adminOnly,
  cancelItem
}


class ShowCustomPinDialog {
  Permission _permission = Permission.adminOnly;

  ShowCustomPinDialog({Permission? permission}) {
    _permission = permission ?? _permission;
  }

  Permission get permission => _permission;

  Future<void> showPinDialog(BuildContext context, Function() callback, {bool? barrierDismissible}){
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible ?? false,
      builder: (context) => CustomPinDialog(
        permission: _permission,
        callback: callback,
      ),
    );
  }
}

class CustomPinDialog extends StatefulWidget {
  final Permission permission;
  final Function() callback;
  const CustomPinDialog({super.key, required this.permission, required this.callback});

  @override
  State<CustomPinDialog> createState() => _CustomPinDialogState();
}

class _CustomPinDialogState extends State<CustomPinDialog> {
  final adminPosPinController = TextEditingController();
  bool isButtonDisabled = false;
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    var color = context.watch<ThemeColor>();
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.translate('enter_pin')),
      content: ValueListenableBuilder(
          valueListenable: adminPosPinController,
          builder: (context, TextEditingValue value, __) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                autofocus: true,
                onSubmitted: (input) {
                  setState(() {
                    isButtonDisabled = true;
                  });
                  _submit(context);
                },
                obscureText: true,
                controller: adminPosPinController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  errorText: _submitted
                      ? errorPassword == null
                      ? errorPassword
                      : AppLocalizations.of(context)?.translate(errorPassword!)
                      : null,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: color.backgroundColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: color.backgroundColor),
                  ),
                  labelText: "PIN",
                ),
              ),
            );
          }),
      actions: <Widget>[
        Row(
          children: [
            Expanded(
              flex: 1,
              child: SizedBox(
                height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500
                    ? MediaQuery.of(context).size.height / 12
                    : MediaQuery.of(context).orientation == Orientation.landscape ? MediaQuery.of(context).size.height / 10
                    : MediaQuery.of(context).size.height / 20,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color.backgroundColor,
                  ),
                  onPressed: isButtonDisabled ? null : () {
                    setState(() {
                      isButtonDisabled = true;
                    });
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    AppLocalizations.of(context)!.translate('close'),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: SizedBox(
                height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500
                    ? MediaQuery.of(context).size.height / 12
                    : MediaQuery.of(context).orientation == Orientation.landscape ? MediaQuery.of(context).size.height / 10
                    : MediaQuery.of(context).size.height / 20,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color.buttonColor,
                  ),
                  onPressed: isButtonDisabled ? null : () async {
                    setState(() {
                      isButtonDisabled = true;
                    });
                    _submit(context);
                  },
                  child: Text(
                    AppLocalizations.of(context)!.translate('yes'),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String? get errorPassword {
    final text = adminPosPinController.value.text;
    if (text.isEmpty) {
      return 'password_required';
    }
    return null;
  }

  void _submit(BuildContext context) async {
    setState(() => _submitted = true);
    if (errorPassword == null) {
      await readAdminData(adminPosPinController.text);
    } else {
      setState(() {
        isButtonDisabled = false;
      });
    }
  }

  void showToastResetTextFieldButton(String title){
    CustomFailedToast(title: AppLocalizations.of(context)!.translate(title)).showToast();
    adminPosPinController.clear();
    setState(() {
      isButtonDisabled = false;
    });
  }

  readAdminData(String pin) async {
    try {
      User? userData = decodeAction.decodedUserList!.firstWhereOrNull((e) => e.pos_pin == pin);
      if (userData != null) {
        switch(widget.permission) {
          case Permission.cancelItem: {
            if(userData.edit_price_without_pin == 1){
              Navigator.of(context).pop();
              widget.callback();
            } else {
              showToastResetTextFieldButton('no_permission');
            }
          }break;
          default: {
            //admin only
            if(userData.role == 0){
              Navigator.of(context).pop();
              widget.callback();
            } else {
              showToastResetTextFieldButton('no_permission');
            }
          }break;
        }
      } else {
        showToastResetTextFieldButton('user_not_found');
      }
    } catch(e, stackTrace){
      Navigator.of(context).pop();
      rethrow;
    }
  }
}
