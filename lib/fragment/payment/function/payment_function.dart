import 'dart:convert';

import 'package:optimy_second_device/object/payment_link_company.dart';

import '../../../main.dart';

class PaymentFunction {
  List<PaymentLinkCompany> _paymentMethodList = [];

  PaymentFunction();

  String calcChange(String amount, String finalAmount) {
    String change = '0.00';
    try {
      if (amount != '' && double.parse(amount) >= double.parse(finalAmount)) {
        double value = double.parse(amount) - double.parse(finalAmount);
        change = value.toStringAsFixed(2);
      } else {
        change = '0.00';
      }
    } catch (e) {
      print("calc change error: $e");
      change = '0.00';
    }
    print("change in function: $change");
    return change;
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