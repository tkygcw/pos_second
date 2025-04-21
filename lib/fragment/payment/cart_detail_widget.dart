import 'package:flutter/material.dart';
import 'package:optimy_second_device/notifier/cart_notifier.dart';
import 'package:optimy_second_device/notifier/theme_color.dart';
import 'package:optimy_second_device/object/cart_payment.dart';
import 'package:optimy_second_device/object/cart_product.dart';
import 'package:optimy_second_device/object/promotion.dart';
import 'package:provider/provider.dart';

import '../../translation/AppLocalizations.dart';

class CartDetail extends StatelessWidget {
  const CartDetail({super.key});

  @override
  Widget build(BuildContext context) {
    var cart = context.read<CartModel>();
    var color = context.read<ThemeColor>();
    var orientation = MediaQuery.of(context).orientation;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(15.0),
        decoration: const BoxDecoration(
          border: Border(
            right: BorderSide(
                color: Colors.blueGrey,
                width: 0.5
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${AppLocalizations.of(context)!.translate('table_no')}: ${getSelectedTable(cart)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
            Divider(
              color: Colors.grey,
              height: 1,
              thickness: 1,
              indent: 20,
              endIndent: 20,
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: cart.cartNotifierItem.length,
                  itemBuilder: (BuildContext context, int index) {
                    return _CartItem(color: color, cartItem: cart.cartNotifierItem[index]);
                  },
                ),
              ),
            ),
            Divider(
              color: Colors.grey,
              height: 1,
              thickness: 1,
              indent: 20,
              endIndent: 20,
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: _CartPayment(cartPayment: cart.cartNotifierPayment!, selectedPromotion: cart.selectedPromotion),
              ),
            ),
            orientation == Orientation.landscape ?
            SizedBox(
              width: double.maxFinite,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color.backgroundColor,
                  padding: const EdgeInsets.all(20),
                ),
                onPressed: (){
                  Navigator.of(context).pop();
                },
                child: Text("Cancel payment"),
              ),
            ) : SizedBox(
              width: double.maxFinite,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color.backgroundColor,
                  padding: const EdgeInsets.all(20),
                ),
                onPressed: (){
                  Navigator.of(context).pop();
                },
                child: Text("Close"),
              ),
            )
          ],
        ),
      )
    );
  }

/*
  get selected table
*/
  getSelectedTable(CartModel cart) {
    List<String> result = [];
    if (cart.selectedTable.isEmpty) {
      return "N/A";
    } else {
      return cart.selectedTable.map((e) => e.number).toList().toString().replaceAll('[', '').replaceAll(']', '');
    }
  }
}

class _CartItem extends StatelessWidget {
  final ThemeColor color;
  final cartProductItem cartItem;
  const _CartItem({super.key, required this.color, required this.cartItem});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      hoverColor: Colors.transparent,
      onTap: null,
      isThreeLine: true,
      title: RichText(
        text: TextSpan(
          children: <TextSpan>[
            TextSpan(
              text: '${cartItem.product_name!} (${cartItem.price!}/${cartItem.per_quantity_unit!}${cartItem.unit! == 'each' || cartItem.unit! == 'each_c' ? 'each' : cartItem.unit!})\n',
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.height > 500 ? 20 : 15,
                color: color.backgroundColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
                text: "$currency_symbol${getItemTotalPrice(productItem: cartItem)}",
                style: TextStyle(fontSize: 15, color: color.backgroundColor)),
          ],
        ),
      ),
      subtitle: Text(getVariant(cartItem) +
          getModifier(cartItem) +
          getRemark(cartItem),
          style: TextStyle(fontSize: 12)),
      trailing: FittedBox(
        child: Row(
          children: [
            Text(
              'x${cartItem.quantity.toString()}',
              style: TextStyle(
                  color: color.backgroundColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }

  getItemTotalPrice({required cartProductItem productItem}){
    return (double.parse(productItem.price!) * productItem.quantity!).toStringAsFixed(2);
  }

  String getVariant(cartProductItem object) {
    if(object.productVariantName != null && object.productVariantName != ''){
      return "(${object.productVariantName!})\n";
    } else {
      return '';
    }
  }

  String getModifier(cartProductItem object) {
    if(object.orderModifierDetail != null && object.orderModifierDetail!.isNotEmpty){
      return object.orderModifierDetail!.map((e) => e.mod_name).toList()
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll(',', '\n+')
          .replaceFirst('', '+ ');
    } else {
      return '';
    }
  }

  getRemark(cartProductItem object) {
    String result = '';
    if (object.remark != '') {
      result = '*' + object.remark.toString();
    }
    return result;
  }
}

class _CartPayment extends StatefulWidget {
  final Promotion? selectedPromotion;
  final CartPaymentDetail cartPayment;
  const _CartPayment({super.key, required this.cartPayment, this.selectedPromotion});

  @override
  State<_CartPayment> createState() => _CartPaymentState();
}

class _CartPaymentState extends State<_CartPayment> {
  final ScrollController _controller = ScrollController();
  late final CartModel cart;
  void _scrollDown() {
    _controller.jumpTo(_controller.position.maxScrollExtent);
  }
  @override
  void initState() {
    cart = context.read<CartModel>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _scrollDown();
      });
    });
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: _controller,
      padding: EdgeInsets.only(left: 5, right: 5),
      physics: ClampingScrollPhysics(),
      shrinkWrap: true,
      children: [
        ListTile(
          title: Text('Subtotal', style: TextStyle(fontSize: 14)),
          trailing: Text(cart.subtotal.toStringAsFixed(2), style: TextStyle(fontSize: 14)),
          visualDensity: VisualDensity(vertical: -4),
          dense: true,
        ),
        ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: cart.autoPromotion.length,
          itemBuilder: (context, index) {
            return ListTile(
                title: Text('${cart.autoPromotion[index].name} (${cart.autoPromotion[index].promoRate})',
                    style: TextStyle(fontSize: 14)),
                visualDensity: VisualDensity(vertical: -4),
                dense: true,
                trailing: Text(
                    '-${cart.autoPromotion[index].promoAmount!.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 14)));
          },
        ),
        widget.selectedPromotion != null ?
        ListTile(
          title: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text('${cart.selectedPromotion?.name} (${cart.selectedPromotion?.promoRate})',
                    style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
          trailing: Text('-${cart.selectedPromotion?.promoAmount?.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 14)),
          visualDensity: VisualDensity(vertical: -4),
          dense: true,
        ) : SizedBox.shrink(),
        ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: cart.applicableTax.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text('${cart.applicableTax[index].tax_name}(${cart.applicableTax[index].tax_rate}%)',
                  style: TextStyle(fontSize: 14)),
              trailing: Text(cart.taxAmount(cart.applicableTax[index]).toStringAsFixed(2),
                  style: TextStyle(fontSize: 14)),
              visualDensity: VisualDensity(vertical: -4),
              dense: true,
            );
          },
        ),
        ListTile(
          title: Text('Amount',
              style: TextStyle(fontSize: 14)),
          trailing: Text(cart.grossTotal.toStringAsFixed(2),
              style: TextStyle(fontSize: 14)),
          visualDensity: VisualDensity(vertical: -4),
          dense: true,
        ),
        ListTile(
          title: Text('Rounding', style: TextStyle(fontSize: 14)),
          trailing: Text(cart.rounding.toStringAsFixed(2), style: TextStyle(fontSize: 14)),
          visualDensity: VisualDensity(vertical: -4),
          dense: true,
        ),
        //split payment
        // for (int index = 0; index < paymentSplitList.length; index++)
        //   ListTile(
        //     title: Text('${paymentSplitList[index].payment_name}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        //     visualDensity: VisualDensity(vertical: -4),
        //     dense: true,
        //     trailing: Text('${paymentSplitList[index].payment_received!}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        //   ),
        ListTile(
          visualDensity: VisualDensity(vertical: -4),
          title: Text('Final Amount',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          trailing: Text(
              cart.netTotal.toStringAsFixed(2),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          dense: true,
        ),
      ],
    );
  }
}

