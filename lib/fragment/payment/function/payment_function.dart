import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:optimy_second_device/fragment/payment/payment_method_widget.dart';
import 'package:optimy_second_device/notifier/cart_notifier.dart';
import 'package:optimy_second_device/object/order.dart';
import 'package:optimy_second_device/object/payment_link_company.dart';
import 'package:optimy_second_device/object/promotion.dart';
import 'package:optimy_second_device/object/tax_link_dining.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../main.dart';
import '../../../object/user.dart';

class PaymentFunction extends ChangeNotifier {
  double _paymentReceived = 0.0;
  double _change = 0.0;
  bool _splitPayment = false;
  String _ipayTransId  = '';
  PaymentLinkCompany? _paymentLinkCompany;
  List<PaymentLinkCompany> _paymentMethodList = [];

  double get change => _change;
  double get paymentReceived => _paymentReceived;
  bool get splitPayment => _splitPayment;
  String get ipayTransId => _ipayTransId;
  PaymentLinkCompany? get paymentLinkCompany => _paymentLinkCompany;

  set setPaymentReceived(double value) {
    _paymentReceived = value;
  }

  set setPaymentLinkCompany(PaymentLinkCompany? value) {
    _paymentLinkCompany = value;
  }

  set setSplitPayment(bool value) {
    _splitPayment = value;
  }

  set setIpayTransId(String value) {
    _ipayTransId = value;
  }

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

  Future makePayment(CartModel cart) async {
    print("_paymentLinkCompany: ${_paymentLinkCompany!.payment_link_company_id}");
    print("change: ${change}");
    print("Payment received: ${_paymentReceived}");
    final prefs = await SharedPreferences.getInstance();
    final String? pos_user = prefs.getString('pos_pin_user');
    Map<String, dynamic> userMap = json.decode(pos_user!);
    User userData = User.fromJson(userMap);
    var orderData = Order(
      payment_type_id: _paymentLinkCompany!.payment_type_id!,
      payment_received: _splitPayment ? '' : _paymentReceived.toStringAsFixed(2),
      payment_change: _splitPayment ? '' : _change.toStringAsFixed(2),
      payment_link_company_id: _splitPayment ? '' : _paymentLinkCompany!.payment_link_company_id!.toString(),
      payment_split: _splitPayment ? 1 : 0,
      ipay_trans_id: _splitPayment ? '' : _ipayTransId,
      close_by: userData.name,
      dining_id: cart.selectedOptionId,
      dining_name: cart.selectedOption,
      subtotal: cart.subtotal.toStringAsFixed(2),
      amount: cart.grossTotal.toStringAsFixed(2),
      rounding: cart.rounding.toStringAsFixed(2),
      final_amount: cart.netTotal.toStringAsFixed(2)
    );
    Map<String, dynamic> param = {
      'orderCacheList': cart.currentOrderCache,
      'orderData': orderData,
      'promotion': getTotalDiscountPerPromotion(cart),
      'tax': getTotalAmountPerTax(cart),
      'selectedTable': cart.selectedTable
    };
    await clientAction.connectRequestPort(action: '19', param: jsonEncode(param), callback: _decodePaymentRes);
    // return _paymentMethodList;
  }

  List<TaxLinkDining> getTotalAmountPerTax(CartModel cart) {
    return cart.applicableTax.map((tax) {
      return tax.copy(
          tax_amount: cart.taxAmount(tax).toStringAsFixed(2)
      );
    }).toList();
  }

  List<Promotion> getTotalDiscountPerPromotion(CartModel cart) {
    return cart.applicablePromotions.map((promotion) {
      return promotion.copy(
        promoAmount: cart.discountForPromotion(promotion)
      );
    }).toList();
  }

  void _decodePaymentRes(response){
    try{
      var json = jsonDecode(clientAction.response!);
      String status = json['status'];
      switch(status){
        case '1': {
          print("payment success");
        }break;
        default: {
          clientAction.openReconnectDialog(action: json['action'], callback: _decodeData);
        }
      }
    }catch(e, s){
      print('_decodePaymentRes error: $e, trace: ${s}');
    }
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