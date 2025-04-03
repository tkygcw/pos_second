import 'package:optimy_second_device/object/promotion.dart';
import 'package:optimy_second_device/object/tax.dart';
import 'package:optimy_second_device/object/tax_link_dining.dart';

import 'order_promotion_detail.dart';
import 'order_tax_detail.dart';

class CartPaymentDetail {
  String localOrderId = '';
  double subtotal = 0.0;
  double amount = 0.00;
  double rounding = 0.0;
  String finalAmount = '';
  double paymentReceived = 0.0;
  double paymentChange = 0.0;
  List<OrderTaxDetail> orderTaxList = [];
  List<OrderPromotionDetail> orderPromotionDetail = [];
  List<Promotion>? promotionList = [];
  Promotion? manualPromo;
  List<Tax>? taxList = [];
  List<TaxLinkDining>? diningTax = [];
  String? dining_name;

  CartPaymentDetail(
      String localOrderId,
      double subtotal,
      double amount,
      double rounding,
      String finalAmount,
      double paymentReceived,
      double paymentChange,
      List<OrderTaxDetail> orderTaxList,
      List<OrderPromotionDetail> orderPromotionDetail,
      {this.promotionList,
        this.manualPromo,
        this.taxList,
        this.dining_name,
        this.diningTax
      })
  {
    this.localOrderId = localOrderId;
    this.subtotal = subtotal;
    this.amount = amount;
    this.rounding = rounding;
    this.finalAmount = finalAmount;
    this.paymentReceived = paymentReceived;
    this.paymentChange = paymentChange;
    this.orderTaxList = orderTaxList;
    this.orderPromotionDetail = orderPromotionDetail;
  }

  Map<String, dynamic> toJson() {
    return {
      'localOrderId': localOrderId,
      'subtotal': subtotal,
      'amount': amount,
      'rounding': rounding,
      'finalAmount': finalAmount,
      'paymentReceived': paymentReceived,
      'paymentChange': paymentChange,
      'orderTaxList': orderTaxList.map((tax) => tax.toJson()).toList(),
      'orderPromotionDetail': orderPromotionDetail.map((promo) => promo.toJson()).toList(),
      'promotionList': promotionList?.map((promo) => promo.toJson()).toList(),
      'manualPromo': manualPromo?.toJson(),
      'taxList': taxList?.map((tax) => tax.toJson()).toList(),
      'diningTax': diningTax?.map((dining) => dining.toJson()).toList(),
      'dining_name': dining_name,
    };
  }
}