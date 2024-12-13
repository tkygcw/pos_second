import 'package:flutter/material.dart';
import 'package:optimy_second_device/notifier/theme_color.dart';
import 'package:provider/provider.dart';

import '../../../../translation/AppLocalizations.dart';
import '../../payment_method_widget.dart';

class ButtonWidget extends StatefulWidget {
  final PaymentTypeEnum paymentTypeEnum;
  final Function? clearField;
  final Function? scanQR;
  const ButtonWidget({super.key, required this.paymentTypeEnum, this.clearField, this.scanQR});

  @override
  State<ButtonWidget> createState() => _ButtonWidgetState();
}

class _ButtonWidgetState extends State<ButtonWidget> {
  bool isButtonDisable = false, split_payment = false, scanning = false;
  late ThemeColor color;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    color = context.read<ThemeColor>();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 15.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _generateButton(),
      ),
    );
  }

  List<Widget> _generateButton(){
    List<Widget> _widget = [];
    if(widget.paymentTypeEnum == PaymentTypeEnum.ipay){
      _widget = [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: color.backgroundColor,
            padding: const EdgeInsets.all(20),
          ),
          onPressed: isButtonDisable ? null : () {
            setState(() {
              scanning = widget.scanQR!();
            });
          },
          icon: !scanning ? Icon(Icons.qr_code_scanner) : Icon(Icons.cancel),
          label: Text(
              scanning == false ?
              AppLocalizations.of(context)!.translate('scan_qr') :
              AppLocalizations.of(context)!.translate('cancel'),
              style: TextStyle(fontSize: 20)),
        ),
        SizedBox(width: 10,),
        //split payment part
        ElevatedButton.icon(
          style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.blue),
              padding: WidgetStateProperty.all(EdgeInsets.all(20))),
          onPressed: () async {},
          icon: Icon(Icons.payments_outlined),
          label: Text(!split_payment ? AppLocalizations.of(context)!.translate('split_payment')
              : AppLocalizations.of(context)!.translate('split_payment_cancel'),
              style: TextStyle(fontSize: 20)
          ),
        ),
      ];
    } else {
      _widget = [
        SizedBox(
          height: 70,
          width: 150,
          child: ElevatedButton.icon(
            onPressed: isButtonDisable ? null : () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: color.backgroundColor,
              elevation: 5,
            ),
            icon: Icon(Icons.payments, size: 24),
            label: Text(
              AppLocalizations.of(context)!.translate('make_payment'),
              style: TextStyle(fontSize: 20),
            ),
          ),
        ),
        SizedBox(
          width: 5,
        ),
        Visibility(
          visible: widget.paymentTypeEnum == PaymentTypeEnum.cash ? true : false,
          child: SizedBox(
            height: 70,
            width: 150,
            child: ElevatedButton.icon(
              onPressed: () async {
                widget.clearField!();
              },
              style: ElevatedButton.styleFrom(
                elevation: 5,
                backgroundColor: color.buttonColor,
              ),
              icon: Icon(Icons.backspace),
              label: Text(AppLocalizations.of(context)!.translate('clear'),
                  style: TextStyle(fontSize: 20)),
            ),
          ),
        ),
        SizedBox(
          width: 5,
        ),
        //split payment button
        SizedBox(
          height: 70,
          width: 150,
          child:
          ElevatedButton.icon(
              onPressed: (){},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                elevation: 5,
              ),
              icon: Icon(Icons.payments_outlined, size: 24),
              label: Text(!split_payment ? AppLocalizations.of(context)!.translate('split_payment')
                  : AppLocalizations.of(context)!.translate('split_payment_cancel'),
                style: TextStyle(fontSize: 20),
              )),
        )
      ];
    }
    return _widget;
  }
}
