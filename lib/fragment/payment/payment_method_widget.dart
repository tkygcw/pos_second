import 'package:flutter/material.dart';
import 'package:optimy_second_device/fragment/payment/function/payment_function.dart';
import 'package:optimy_second_device/fragment/payment/payment_type/cash_view.dart';
import 'package:optimy_second_device/fragment/payment/payment_type/fixed_amount_view.dart';
import 'package:optimy_second_device/fragment/payment/payment_type/shared_widget/ipay_view.dart';
import 'package:optimy_second_device/object/payment_link_company.dart';

import '../../page/progress_bar.dart';

var paymentFunc = PaymentFunction();

enum PaymentTypeEnum {
  cash,
  fixedAmount,
  ipay
}

class PaymentMethod extends StatelessWidget {
  const PaymentMethod({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: FutureBuilder<List<PaymentLinkCompany>>(
          future: paymentFunc.getPaymentMethod(),
          builder: (context, snapshot) {
            print("connection state in payment method: ${snapshot.connectionState}");
            switch(snapshot.connectionState){
              case ConnectionState.waiting:
                return CustomProgressBar();
              default :
                if(snapshot.hasError){
                  return Center(
                    child: Text("Check main pos version"),
                  );
                } else {
                  List<PaymentLinkCompany> data = snapshot.data!;
                  return _PaymentSelect(paymentLinkCompanyList: data);
                }
            }
          },
      ),
    );
  }
}

class _PaymentTypeView extends StatelessWidget {
  final PaymentTypeEnum paymentType;
  const _PaymentTypeView({super.key, required this.paymentType});

  @override
  Widget build(BuildContext context) {
    switch (paymentType){
      case PaymentTypeEnum.fixedAmount:
        return FixedAmountView();
      case PaymentTypeEnum.ipay:
        return IpayView();
      default:
        return CashView(paymentFunction: paymentFunc);
    }
  }
}

class _PaymentSelect extends StatefulWidget {
  final List<PaymentLinkCompany> paymentLinkCompanyList;
  const _PaymentSelect({super.key, required this.paymentLinkCompanyList});

  @override
  State<_PaymentSelect> createState() => _PaymentSelectState();
}

class _PaymentSelectState extends State<_PaymentSelect> {
  var paymentType = PaymentTypeEnum.cash;
  var paymentName = 'Cash';

  _paymentSelectCallBack(PaymentLinkCompany companyPayment){
    setState(() {
      paymentType = PaymentTypeEnum.values.elementAt(companyPayment.type!);
      paymentName = companyPayment.name!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
     children: [
       Text(paymentName,
         style: TextStyle(
           color: Colors.blueGrey,
           fontSize: 24,
           fontWeight: FontWeight.bold
         ),
       ),
       const SizedBox(height: 20),
       _PaymentTypeView(paymentType: paymentType),
       const SizedBox(height: 20),
       SizedBox(
         height: 100,
         child: ListView(
           padding: EdgeInsets.zero,
           shrinkWrap: true,
           scrollDirection: Axis.horizontal,
           children: List.generate(widget.paymentLinkCompanyList.length, (i) {
             return _PaymentCard(paymentLinkCompany: widget.paymentLinkCompanyList[i], callback: _paymentSelectCallBack);
           })
                ),
       )
     ],
    );
  }
}


class _PaymentCard extends StatelessWidget {
  final PaymentLinkCompany paymentLinkCompany;
  final Function callback;
  const _PaymentCard({super.key, required this.paymentLinkCompany, required this.callback});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: InkWell(
        splashColor: Colors.blue.withAlpha(30),
        borderRadius: BorderRadius.circular(16.0),
        onTap: (){
          callback(paymentLinkCompany);
        },
        child: Center(
          child: SizedBox(
            width: 100,
            child: Text(
              paymentLinkCompany.name!,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}


