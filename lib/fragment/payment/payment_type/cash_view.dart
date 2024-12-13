import 'package:flutter/material.dart';
import 'package:optimy_second_device/fragment/payment/function/payment_function.dart';
import 'package:optimy_second_device/fragment/payment/payment_method_widget.dart';
import 'package:optimy_second_device/fragment/payment/payment_type/shared_widget/button_widget.dart';
import 'package:optimy_second_device/fragment/payment/payment_type/shared_widget/final_amount_widget.dart';
import 'package:provider/provider.dart';

import '../../../notifier/cart_notifier.dart';

class CashView extends StatefulWidget {
  final PaymentFunction paymentFunction;
  const CashView({super.key, required this.paymentFunction});

  @override
  State<CashView> createState() => _CashViewState();
}

class _CashViewState extends State<CashView> {
  String finalAmount = '0.00';

  @override
  void initState() {
    var cart = context.read<CartModel>();
    finalAmount = cart.cartNotifierPayment!.finalAmount;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FinalAmountWidget(finalAmount: finalAmount),
        SizedBox(height: 10),
        _AmountField(paymentFunction: widget.paymentFunction, finalAmount: finalAmount,)
      ],
    );
  }
}

class _AmountField extends StatefulWidget {
  final String finalAmount;
  final PaymentFunction paymentFunction;
  const _AmountField({super.key, required this.paymentFunction, required this.finalAmount});

  @override
  State<_AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<_AmountField> {
  final TextEditingController _controller = TextEditingController();
  String change = '0.00', finalAmount = '0.00';
  bool chipSelected = false;

  calcChange(){
    change = widget.paymentFunction.calcChange(_controller.text, finalAmount);
  }

  @override
  void initState() {
    finalAmount = widget.finalAmount;
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _controller.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext currentContext) {
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
              change = '0.00';
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
            label: Text('RM $finalAmount'),
            selected: chipSelected,
            elevation: 5,
            onSelected: (chipSelected) {
              _controller.text = finalAmount;
              calcChange();
            },
          ),
          ChoiceChip(
            label: Text('RM 10.00'),
            selected: chipSelected,
            elevation: 5,
            onSelected: (chipSelected) {
              _controller.text = '10.00';
              calcChange();
            },
          ),
          ChoiceChip(
            label: Text('RM 20.00'),
            selected: chipSelected,
            elevation: 5,
            onSelected: (chipSelected) {
              _controller.text = '20.00';
              calcChange();
            },
          ),
          ChoiceChip(
            label: Text('RM 50.00'),
            selected: chipSelected,
            elevation: 5,
            onSelected: (chipSelected) {
              _controller.text = '50.00';
              calcChange();
            },
          ),
          ChoiceChip(
            label: Text('RM 100.00'),
            selected: chipSelected,
            elevation: 5,
            onSelected: (chipSelected) {
              _controller.text = '100.00';
              calcChange();
            },
          ),
        ]);
  }
}





