import 'package:flutter/material.dart';
import 'package:optimy_second_device/fragment/payment/function/payment_function.dart';
import 'package:optimy_second_device/fragment/payment/payment_method_widget.dart';
import 'package:optimy_second_device/fragment/payment/payment_type/shared_widget/button_widget.dart';
import 'package:optimy_second_device/fragment/payment/payment_type/shared_widget/final_amount_widget.dart';
import 'package:optimy_second_device/main.dart';
import 'package:provider/provider.dart';

import '../../../notifier/cart_notifier.dart';

class CashView extends StatefulWidget {
  const CashView({super.key});

  @override
  State<CashView> createState() => _CashViewState();
}

class _CashViewState extends State<CashView> {
  final TextEditingController _controller = TextEditingController();
  String change = '0.00', finalAmount = '0.00';
  bool chipSelected = false;
  late PaymentFunction paymentFunction;

  setPaymentReceived(double value){
    paymentFunction.setPaymentReceived = value;
  }

  calcChange(){
    paymentFunction.calcChange(_controller.text, finalAmount);
  }

  @override
  void initState() {
    finalAmount = context.read<CartModel>().netTotal.toStringAsFixed(2);
    paymentFunction = context.read<PaymentFunction>();
    setPaymentReceived(0.0);
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _controller.dispose();
    paymentFunction.resetChange();
    setPaymentReceived(double.parse(finalAmount));
    super.dispose();
  }

  @override
  Widget build(BuildContext currentContext) {
    change = context.select((PaymentFunction value) => value.change.toStringAsFixed(2));
    return SizedBox(
      width: 500,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (currentContext, TextEditingValue value, __) {
              return Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(bottom: 10),
                    alignment: Alignment.centerLeft,
                    child: Text('Change: $change'),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      FocusScopeNode currentFocus = FocusScope.of(context);

                      if (!currentFocus.hasPrimaryFocus &&
                          currentFocus.focusedChild != null) {
                        FocusScope.of(context).unfocus();
                      }
                    },
                    child: TextField(
                      onSubmitted: (value) {
                        // makePayment();
                      },
                      onChanged: (value) {
                        if(value != ''){
                          setPaymentReceived(double.parse(value));
                        }
                        calcChange();
                      },
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      controller: _controller,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                      ),
                      style: TextStyle(fontSize: 30),
                    ),
                  ),
                  buildWrap(),
                ],
              );
            },
          ),
          ButtonWidget(
            paymentTypeEnum: PaymentTypeEnum.cash,
            clearField: () {
              _controller.clear();
              setPaymentReceived(0.0);
              calcChange();
            },
          ),
        ],
      ),
    );
  }

  Widget buildWrap() {
    return Wrap(
        runSpacing: 5,
        spacing: 10,
        children: [
          ChoiceChip(
            label: Text('$currency_symbol $finalAmount'),
            selected: chipSelected,
            elevation: 5,
            onSelected: (chipSelected) {
              _controller.text = finalAmount;
              setPaymentReceived(double.parse(finalAmount));
              calcChange();
            },
          ),
          ChoiceChip(
            label: Text('$currency_symbol 10.00'),
            selected: chipSelected,
            elevation: 5,
            onSelected: (chipSelected) {
              _controller.text = '10.00';
              setPaymentReceived(double.parse(_controller.text));
              calcChange();
            },
          ),
          ChoiceChip(
            label: Text('$currency_symbol 20.00'),
            selected: chipSelected,
            elevation: 5,
            onSelected: (chipSelected) {
              _controller.text = '20.00';
              setPaymentReceived(double.parse(_controller.text));
              calcChange();
            },
          ),
          ChoiceChip(
            label: Text('$currency_symbol 50.00'),
            selected: chipSelected,
            elevation: 5,
            onSelected: (chipSelected) {
              _controller.text = '50.00';
              setPaymentReceived(double.parse(_controller.text));
              calcChange();
            },
          ),
          ChoiceChip(
            label: Text('$currency_symbol 100.00'),
            selected: chipSelected,
            elevation: 5,
            onSelected: (chipSelected) {
              _controller.text = '100.00';
              setPaymentReceived(double.parse(_controller.text));
              calcChange();
            },
          ),
        ]);
  }
}





