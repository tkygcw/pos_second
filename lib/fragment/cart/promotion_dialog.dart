import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:optimy_second_device/fragment/toast/custom_toastification.dart';
import 'package:optimy_second_device/notifier/cart_notifier.dart';
import 'package:optimy_second_device/object/promotion.dart';
import 'package:provider/provider.dart';

import '../../page/progress_bar.dart';
import '../../translation/AppLocalizations.dart';
import 'function/promotion_function.dart';

final _promoFunc = PromotionFunction();

class PromotionDialog extends StatelessWidget {
  const PromotionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.translate('select_promotion')),
      content: SizedBox(
        height: 350,
        width: 350,
        child: _PromotionView(),
      ),
      actions: [
        TextButton(
            onPressed: (){
              Navigator.of(context).pop();
            },
            child: Text("Close"),
        )
      ],
    );
  }
}

class _PromotionView extends StatefulWidget {
  const _PromotionView({super.key});

  @override
  State<_PromotionView> createState() => _PromotionViewState();
}

class _PromotionViewState extends State<_PromotionView> {
  late Future<List<Promotion>> promotionData;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    promotionData = _promoFunc.getServerPromotion();
  }
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Promotion>>(
        future: promotionData,
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
                List<Promotion> data = snapshot.data!;
                return ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: data.length,
                    itemBuilder: (BuildContext context, int index) {
                      return _PromotionCard(promotion: data[index]);
                    });
              }
          }
        },
    );
  }
}

class _PromotionCard extends StatelessWidget {
  final Promotion promotion;
  const _PromotionCard({super.key, required this.promotion});

  @override
  Widget build(BuildContext context) {
    var cart = context.read<CartModel>();
    return Card(
      elevation: 5,
      child: ListTile(
        enabled: _promoFunc.isPromotionAvailable(promotion, cart),
        leading: CircleAvatar(
            backgroundColor: Colors.grey.shade200,
            child: Icon(
              Icons.discount,
              color: Colors.grey,
            )),
        trailing: promotion.type == 0 ? Text('-${promotion.amount}%') :
        promotion.type == 1 ? Text('-${double.parse(promotion.amount!).toStringAsFixed(2)}')
            : Text(''),
        title: Text('${promotion.name}'),
        onTap: () {
          if(cart.cartNotifierItem.isEmpty){
            Navigator.of(context).pop();
            CustomFailedToast(title: AppLocalizations.of(context)!.translate('outstanding_promotion')).showToast();
          } else {
            //check is flexible promotion or not
            if(promotion.type == 2){
              Navigator.of(context).pop();
              // open flexible promotion dialog
              showDialog(
                context: context,
                builder: (context) => _AdjustPromotionDialog(promotion: promotion, cartModel: cart),
              );

            } else {
              //check is outstanding or not
              if(_promoFunc.checkOfferAmount(promotion, cart.subtotal.toStringAsFixed(2)) == false){
                cart.addPromotion(promotion);
              } else {
                CustomFailedToast(title: AppLocalizations.of(context)!.translate('outstanding_promotion')).showToast();
              }
              Navigator.of(context).pop();
            }
          }
        },
      ),
    );
  }
}

class _AdjustPromotionDialog extends StatefulWidget {
  final Promotion promotion;
  final CartModel cartModel;
  const _AdjustPromotionDialog({super.key, required this.promotion, required this.cartModel});

  @override
  State<_AdjustPromotionDialog> createState() => _AdjustPromotionDialogState();
}

class _AdjustPromotionDialogState extends State<_AdjustPromotionDialog> {
  final TextEditingController _textFieldController = TextEditingController();
  bool isButtonDisabled = false, willPop = true;
  late Promotion promotion;
  late CartModel cart;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    promotion = widget.promotion;
    cart = widget.cartModel;
    print("cart subtotal: ${cart.subtotal}");
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.translate('adjust_promotion')),
      content: SizedBox(
        height: 100.0,
        width: 350.0,
        child: ValueListenableBuilder(
            valueListenable: _textFieldController,
            builder: (context, TextEditingValue value, __) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  autofocus: true,
                  onSubmitted: (input) {
                    if(_textFieldController.text != '' && double.parse(_textFieldController.text).toStringAsFixed(2) != 0.00) {
                      setState(() {
                        isButtonDisabled = true;
                        willPop = false;
                      });
                      promotion.amount = _textFieldController.text;
                      bool outstanding = _promoFunc.checkOfferAmount(promotion, cart.subtotal.toStringAsFixed(2));
                      if(outstanding){
                        Fluttertoast.showToast(
                            backgroundColor: Color(0xFFFF0000),
                            msg: AppLocalizations.of(context)!.translate('outstanding_promotion'));
                        setState(() {
                          isButtonDisabled = false;
                        });
                      } else {
                        promotion.amount = _textFieldController.text;
                        cart.addPromotion(promotion);
                        Navigator.of(context).pop();
                      }
                    } else {
                      Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('discount_invalid'));
                    }
                  },
                  obscureText: false,
                  controller: _textFieldController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                  decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(),
                      labelText: "Discount",
                      prefixText: 'RM '
                  ),
                ),
              );
            }),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: isButtonDisabled
              ? null
              : () {
            setState(() {
              isButtonDisabled = true;
            });
            Navigator.of(context).pop();
            setState(() {
              isButtonDisabled = false;
            });
          },
          child: Text('${AppLocalizations.of(context)?.translate('close')}'),
        ),
        TextButton(
          onPressed: isButtonDisabled
              ? null
              : () async {
            if(_textFieldController.text != '' && double.parse(_textFieldController.text).toStringAsFixed(2) != '0.00') {
              setState(() {
                isButtonDisabled = true;
                willPop = false;
              });
              promotion.amount = _textFieldController.text;
              bool outstanding = _promoFunc.checkOfferAmount(promotion, cart.subtotal.toStringAsFixed(2));
              if(outstanding){
                Fluttertoast.showToast(
                    backgroundColor: Color(0xFFFF0000),
                    msg: AppLocalizations.of(context)!.translate('outstanding_promotion'));
                setState(() {
                  isButtonDisabled = false;
                });
              } else {
                promotion.amount = _textFieldController.text;
                cart.addPromotion(promotion);
                Navigator.of(context).pop();
              }
            } else {
              Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('discount_invalid'));
            }
          },
          child: Text('${AppLocalizations.of(context)?.translate('yes')}'),
        ),
      ],
    );
  }
}





