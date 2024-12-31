import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:optimy_second_device/object/payment_link_company.dart';

import '../../../main.dart';

class PaymentFunction extends ChangeNotifier {
  double _paymentReceived = 0.0;

  double get paymentReceived => _paymentReceived;

  set setPaymentReceived(double value) {
    _paymentReceived = value;
  }

  double _change = 0.0;

  double get change => _change;

  PaymentLinkCompany? _paymentLinkCompany;

  PaymentLinkCompany? get paymentLinkCompany => _paymentLinkCompany;

  set setPaymentLinkCompany(PaymentLinkCompany? value) {
    _paymentLinkCompany = value;
  }

  List<PaymentLinkCompany> _paymentMethodList = [];

  PaymentFunction();

  resetChange(){
    _change = 0.0;
  }

  calcChange(String amount, String finalAmount) {
    try {
      if (amount != '' && double.parse(amount) >= double.parse(finalAmount)) {
        double value = double.parse(amount) - double.parse(finalAmount);
        _change = double.parse(value.toStringAsFixed(2));
      } else {
        _change = 0.0;
      }
    } catch (e) {
      print("calc change error: $e");
      _change = 0.0;
    }
    print("change in function: $change");
    notifyListeners();
  }

  Future makePayment() async {
    print("_paymentLinkCompany: ${_paymentLinkCompany!.payment_link_company_id}");
    print("change: ${change}");
    print("Payment received: ${_paymentReceived}");
    // await clientAction.connectRequestPort(action: '17', param: '', callback: _decodeData);
    // return _paymentMethodList;
  }

  Future<List<PaymentLinkCompany>> getPaymentMethod() async {
    await clientAction.connectRequestPort(action: '17', param: '', callback: _decodeData);
    return _paymentMethodList;
  }

  void _decodeData(response){
    try{
      var json = jsonDecode(clientAction.response!);
      String status = json['status'];
      switch(status){
        case '1': {
          Iterable value1 = json['data']['paymentMethod'];
          _paymentMethodList = List<PaymentLinkCompany>.from(value1.map((json) => PaymentLinkCompany.fromJson(json)));
          _paymentLinkCompany = _paymentMethodList.firstWhere((e) => e.type == 0 && e.name == 'Cash');
        }break;
        default: {
          clientAction.openReconnectDialog(action: json['action'], callback: _decodeData);
        }
      }
    }catch(e, s){
      print('get payment link company error: $e, trace: ${s}');
      //readAllTable();
    }
  }
}