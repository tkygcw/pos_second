import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:optimy_second_device/object/branch_link_tax.dart';
import 'package:optimy_second_device/object/client_action.dart';
import 'package:optimy_second_device/object/tax_link_dining.dart';
import 'package:optimy_second_device/page/progress_bar.dart';
import 'package:provider/provider.dart';


import '../../main.dart';
import '../../notifier/cart_notifier.dart';
import '../../notifier/connectivity_change_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/branch_link_dining_option.dart';
import '../../object/branch_link_promotion.dart';
import '../../object/cart_payment.dart';
import '../../object/cart_product.dart';
import '../../object/cash_record.dart';
import '../../object/dining_option.dart';
import '../../object/modifier_group.dart';
import '../../object/order_modifier_detail.dart';
import '../../object/order_promotion_detail.dart';
import '../../object/order_tax_detail.dart';
import '../../object/print_receipt.dart';
import '../../object/printer.dart';
import '../../object/promotion.dart';
import '../../object/table.dart';
import '../../object/table_use.dart';
import '../../object/tax.dart';
import '../../object/variant_group.dart';
import '../../page/loading_dialog.dart';
import '../../translation/AppLocalizations.dart';
import '../../utils/Utils.dart';
import 'cart_dialog.dart';
import 'cart_remove_dialog.dart';
// import '../settlement/cash_dialog.dart';
// import '../payment/payment_select_dialog.dart';

class CartPage extends StatefulWidget {
  final String currentPage;

  const CartPage({required this.currentPage, Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  StreamController cartController = StreamController();
  late Stream cartStream;
  final ClientAction cartClientAction = ClientAction(serverIp: clientAction.serverIp);
  final ScrollController _scrollController = ScrollController();
  FlutterUsbPrinter flutterUsbPrinter = FlutterUsbPrinter();
  List<Printer> printerList = [];
  List<Promotion> promotionList = [], autoApplyPromotionList = [];
  List<BranchLinkDining> diningList = [];
  List<TaxLinkDining> taxLinkDiningList = [], currentDiningTax = [];
  List<String> branchLinkDiningIdList = [];
  List<cartProductItem> sameCategoryItemList = [];
  List<TableUse> tableUseList = [];
  List<Tax> taxRateList = [];
  List<OrderTaxDetail> orderTaxList = [];
  List<OrderPromotionDetail> orderPromotionList = [];
  int diningOptionID = 0,
      simpleIntInput = 0;
  double total = 0.0,
      newOrderSubtotal = 0.0,
      promo = 0.0,
      selectedPromo = 0.0,
      selectedPromoAmount = 0.0,
      taxAmount = 0.0,
      priceIncAllTaxes = 0.0,
      priceIncTaxes = 0.0,
      discountPrice = 0.0,
      promoAmount = 0.0,
      totalAmount = 0.0,
      tableOrderPrice = 0.0,
      rounding = 0.0,
      paymentReceived = 0.0,
      paymentChange = 0.0;
  String selectedPromoRate = '',
      promoName = '',
      promoRate = '',
      localTableUseId = '',
      orderCacheId = '',
      allPromo = '',
      finalAmount = '',
      localOrderId = '';
  String? table_use_value,
      table_use_detail_value,
      order_cache_value,
      order_detail_value,
      order_modifier_detail_value,
      table_value,
      branch_link_product_value;
  String? orderCacheKey;
  String? orderDetailKey;
  String? tableUseKey;
  String? orderModifierDetailKey;
  String? tableUseDetailKey;
  bool hasPromo = false,
      hasSelectedPromo = false,
      hasNewItem = false,
      timeOutDetected = false,
      isLogOut = false;
  Color font = Colors.black45;
  int myCount = 0;
  bool placingOrder = false, isFirstLoad = false, isButtonDisabled = false;

  void _scrollDown() {
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  @override
  void initState() {
    //controller = StreamController();
    cartStream = cartController.stream;
    //preload();
    //calculateSubtotal();
    // readAllBranchLinkDiningOption();
    // getPromotionData();
    // readAllPrinters();
    super.initState();
  }

  @override
  void deactivate() {
    //controller.sink.close();
    super.deactivate();
  }

  preload() async {
    print("cart preload called");
    await cartClientAction.connectRequestPort(action: '6', callback: decodeData);
    //decodeData();
    // clientAction.sendRequest(action: '6', param: '');
    // await Future.delayed(const Duration(milliseconds: 3000), () {
    //   decodeData();
    // });
  }

  decodeData(response) {
    try {
      var json = jsonDecode(response);
      // Iterable value1 = json['data']['dining_list'];
      // diningList = List<BranchLinkDining>.from(value1.map((json) => BranchLinkDining.fromJson(json)));
      diningList = decodeAction.decodedBranchLinkDiningList!;
      Iterable value2 = json['data']['branch_link_dining_id_list'];
      branchLinkDiningIdList = List.from(value2);
      Iterable value3 = json['data']['promotion_list'];
      promotionList = List<Promotion>.from(value3.map((json) => Promotion.fromJson(json)));
      print("promotion list: ${promotionList.length}");
      Iterable value4 = json['data']['taxLinkDiningList'];
      taxLinkDiningList =
      List<TaxLinkDining>.from(value4.map((json) => TaxLinkDining.fromJson(json)));
      // decodeAction.cartController.sink.add("refresh");
    } catch (e) {
      print("cart decode data error: $e");
    }
  }

  // calculateSubtotal(){
  //   decodeAction.cartStream.listen((cart) async {
  //     await getSubTotal(cart);
  //   });
  // }

  Future showSecondDialog(BuildContext context, ThemeColor color, CartModel cart,
      BranchLinkDining branchLinkDining) {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) =>
          Center(
            child: SingleChildScrollView(
              physics: NeverScrollableScrollPhysics(),
              child: AlertDialog(
                title: Text('Confirm change dining option'),
                content: SizedBox(
                    child: Text('All your cart item will remove, confirm change dining option?')
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text('${AppLocalizations.of(context)?.translate('close')}'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: Text('${AppLocalizations.of(context)?.translate('yes')}'),
                    onPressed: () {
                      cart.removeAllCartItem();
                      cart.removeAllTable();
                      cart.selectedOption = branchLinkDining.name!;
                      cart.selectedOptionId = branchLinkDining.dining_id!;
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> connectToServer({action}) async {
    Socket? socket;
    try {
      socket = await Socket.connect('192.168.0.223', 8888, timeout: const Duration(seconds: 3));
      print('Connected to server.');
      Map result = {'action': action, 'param': ''};
      socket.write('${jsonEncode(result)}\n');

      // Start listening for data from the server
      socket.listen(_handleData);
      socket.close();
    } catch (e) {
      print('Error: $e');
    }
  }

  // Method to handle data received from the server
  void _handleData(Uint8List data) {
    String message = utf8.decode(data);
    print('Received: $message');
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Consumer<CartModel>(builder: (context, CartModel cart, child) {
          // if(notificationModel.cartContentLoaded == true){
          //   print('cart refresh!');
          //   notificationModel.resetCartContentLoaded();
          //   Future.delayed(const Duration(seconds: 1), () {
          //     print('cart delay refresh!');
          //     if(mounted){
          //       setState(() {
          //         readAllBranchLinkDiningOption();
          //         getPromotionData();
          //         getSubTotal(cart);
          //         getReceiptPaymentDetail(cart);
          //       });
          //     }
          //   });
          // }
          //print("method in here will keep calling");
          // widget.currentPage == 'menu' || widget.currentPage == 'table' || widget.currentPage == 'qr_order' || widget.currentPage == 'other_order'
          //     ? getSubTotal(cart)
          //     : getReceiptPaymentDetail(cart);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            getSubTotal(cart);
          });
          return Scaffold(
              resizeToAvoidBottomInset: false,
              appBar: AppBar(
                automaticallyImplyLeading: false,
                title: Row(
                  children: [
                    Visibility(
                      visible: widget.currentPage == 'table' ? true : false,
                      child: Text('${getSelectedTable(cart)}'),
                    ),
                  ],
                ),
                backgroundColor: Colors.white,
                actions: [
                  Visibility(
                    visible: cart.selectedOption == 'Dine in' && widget.currentPage == 'menu'
                        ? true
                        : false,
                    child: Expanded(
                      child: IconButton(
                        tooltip: 'table',
                        icon: Badge(
                          isLabelVisible: cart.selectedTable.isEmpty ? false : true,
                          label: Text("${cart.selectedTable.length}"),
                          child: const Icon(
                            Icons.table_restaurant,
                          ),
                        ),
                        color: color.backgroundColor,
                        onPressed: () {
                          //tableDialog(context);
                          openChooseTableDialog(cart);
                        },
                      ),
                    ),
                  ),
                  // Visibility(
                  //   visible: widget.currentPage == 'menu' ||
                  //           widget.currentPage == 'qr_order' ||
                  //           widget.currentPage == 'bill'
                  //       ? false
                  //       : true,
                  //   child: IconButton(
                  //     tooltip: 'promotion',
                  //     icon: Icon(Icons.discount),
                  //     color: color.backgroundColor,
                  //     onPressed: () {
                  //       print('choose promotion');
                  //       //openPromotionDialog();
                  //     },
                  //   ),
                  // ),
                  Visibility(
                    visible: widget.currentPage == 'menu' ? true : false,
                    child: Expanded(
                      child: IconButton(
                        tooltip: 'clear cart',
                        icon: const Icon(
                          Icons.delete,
                        ),
                        color: color.backgroundColor,
                        onPressed: () {
                          cart.removePartialCartItem();
                          //cart.removeAllTable();
                        },
                      ),
                    ),
                  ),
                  // PopupMenuButton<Text>(
                  //     icon: Icon(Icons.more_vert, color: color.backgroundColor),
                  //     itemBuilder: (context) {
                  //       return [
                  //         PopupMenuItem(
                  //           child: Text(
                  //             'test',
                  //           ),
                  //         ),
                  //       ];
                  //     })
                ],
              ),
              body: StreamBuilder(
                  stream: cartStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      print("cart rebuild call");
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade100, width: 3.0),
                        ),
                        child: Column(
                          children: [
                            Container(
                              margin: MediaQuery
                                  .of(context)
                                  .size
                                  .height > 500 ? EdgeInsets.only(bottom: 10) : EdgeInsets.zero,
                              child: GridView(
                                  physics: NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    childAspectRatio: 1.8,
                                  ),
                                  children: List.generate(diningList.length, (index) {
                                    return InkWell(
                                      onTap: () {
                                        widget.currentPage == 'menu'
                                            ? cart.cartNotifierItem.isEmpty
                                            ? setState(() {
                                          cart.removeAllTable();
                                          cart.selectedOption = diningList[index].name!;
                                          cart.selectedOptionId = diningList[index].dining_id!;
                                          print("cart selected option: ${cart.selectedOption}");
                                          print(
                                              "cart selected option id: ${cart.selectedOptionId}");
                                        })
                                            : cart.cartNotifierItem.isNotEmpty &&
                                            cart.cartNotifierItem[0].status != 1 &&
                                            cart.selectedOption != diningList[index].name!
                                            ? setState(() {
                                          showSecondDialog(context, color, cart, diningList[index]);
                                        })
                                            : null
                                            : null;
                                      },
                                      child: Container(
                                          color: cart.selectedOption == diningList[index].name!
                                              ? color.buttonColor
                                              : color.backgroundColor,
                                          alignment: Alignment.center,
                                          child: Text(
                                            diningList[index].name!,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: cart.selectedOption ==
                                                    diningList[index].name!
                                                    ? color.iconColor
                                                    : Colors.white,
                                                fontSize: 16),
                                          )),
                                    );
                                  })),
                            ),
                            Expanded(
                              child: SizedBox(
                                height: MediaQuery.of(context).size.height > 500 ? 350 : 250,
                                child: ListView.builder(
                                    controller: _scrollController,
                                    shrinkWrap: true,
                                    itemCount: cart.cartNotifierItem.length,
                                    itemBuilder: (context, index) {
                                      return Dismissible(
                                        background: Container(
                                          color: Colors.red,
                                          padding: EdgeInsets.only(left: 25.0),
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete, color: Colors.white),
                                            ],
                                          ),
                                        ),
                                        key: ValueKey(cart.cartNotifierItem[index].product_name),
                                        direction: widget.currentPage == 'menu' &&
                                            cart.cartNotifierItem[index].status == 0 ||
                                            widget.currentPage == 'table' ||
                                            widget.currentPage == 'other_order'
                                            ? DismissDirection.startToEnd
                                            : DismissDirection.none,
                                        confirmDismiss: (direction) async {
                                          if (direction == DismissDirection.startToEnd) {
                                            await openRemoveCartItemDialog(
                                                cart.cartNotifierItem[index], widget.currentPage);
                                          }
                                          return null;
                                        },
                                        child: ListTile(
                                          hoverColor: Colors.transparent,
                                          onTap: () {},
                                          isThreeLine: true,
                                          title: RichText(
                                            text: TextSpan(
                                              children: <TextSpan>[
                                                TextSpan(
                                                  text: '${cart.cartNotifierItem[index].product_name!}\n',
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color: cart.cartNotifierItem[index].status ==
                                                          1 ? font : cart.cartNotifierItem[index]
                                                          .refColor,
                                                      fontWeight: FontWeight.bold),
                                                ),
                                                TextSpan(
                                                    text: "RM${cart.cartNotifierItem[index].price!}",
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: cart.cartNotifierItem[index].status ==
                                                          1 ? font : cart.cartNotifierItem[index]
                                                          .refColor,
                                                    )),
                                              ],
                                            ),
                                          ),
                                          subtitle: Text(getVariant(cart.cartNotifierItem[index]) +
                                              getModifier(cart.cartNotifierItem[index]) +
                                              getRemark(cart.cartNotifierItem[index]),
                                              style: TextStyle(fontSize: 10)),
                                          trailing: FittedBox(
                                            child: Row(
                                              children: [
                                                Visibility(
                                                  visible: widget.currentPage == 'menu'
                                                      ? true
                                                      : false,
                                                  child: IconButton(
                                                      hoverColor: Colors.transparent,
                                                      icon: Icon(Icons.remove),
                                                      onPressed: () {
                                                        cart.cartNotifierItem[index].quantity !=
                                                            1 &&
                                                            cart.cartNotifierItem[index].status ==
                                                                0
                                                            ? setState(() =>
                                                        cart.cartNotifierItem[index].quantity =
                                                            cart.cartNotifierItem[index]
                                                                .quantity! - 1)
                                                            : cart.cartNotifierItem[index]
                                                            .status != 0
                                                            ? Fluttertoast.showToast(
                                                            backgroundColor: Colors.red,
                                                            msg: "order already placed!")
                                                            : cart.removeItem(
                                                            cart.cartNotifierItem[index]);
                                                      }),
                                                ),
                                                Text(
                                                  cart.cartNotifierItem[index].quantity
                                                      .toString(),
                                                  style: TextStyle(color: cart
                                                      .cartNotifierItem[index].refColor),
                                                ),
                                                widget.currentPage == 'menu'
                                                    ? IconButton(
                                                    hoverColor: Colors.transparent,
                                                    icon: Icon(Icons.add),
                                                    onPressed: () {
                                                      if (cart.cartNotifierItem[index].status ==
                                                          0) {
                                                        setState(() {
                                                          cart.cartNotifierItem[index].quantity =
                                                              cart.cartNotifierItem[index]
                                                                  .quantity! + 1;
                                                        });
                                                      } else {
                                                        Fluttertoast.showToast(
                                                            backgroundColor: Colors.red,
                                                            msg: "order already placed!");
                                                      }
                                                      //controller.add('refresh');
                                                    })
                                                    : Container()
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                              ),
                            ),
                            SizedBox(height: MediaQuery.of(context).size.height > 500 ? 20 : 5),
                            Divider(
                              color: Colors.grey,
                              height: 1,
                              thickness: 1,
                              indent: 20,
                              endIndent: 20,
                            ),
                            SizedBox(height: MediaQuery.of(context).size.height > 500 ? 10 : 5),
                            SizedBox(
                              height: MediaQuery.of(context).size.height > 500 ?
                              widget.currentPage == 'menu' || widget.currentPage == 'table' ? 130 :
                              null : 25,
                              // widget.currentPage == 'menu' || widget.currentPage == 'table' && MediaQuery.of(context).size.height > 500
                              //     ? 130
                              //     : MediaQuery.of(context).size.height > 500
                              //         ? null
                              //         : 25,
                              child: ListView(
                                physics: ClampingScrollPhysics(),
                                shrinkWrap: true,
                                children: [
                                  ListTile(
                                    title: Text("Subtotal", style: TextStyle(fontSize: 14)),
                                    trailing: Text(total.toStringAsFixed(2),
                                        style: TextStyle(fontSize: 14)),
                                    visualDensity: VisualDensity(vertical: -4),
                                    dense: true,
                                  ),
                                  Visibility(
                                    visible: cart.selectedPromotion != null ? true : false,
                                    child: ListTile(
                                      title: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: [
                                            Text('$allPromo ($selectedPromoRate)',
                                                style: TextStyle(fontSize: 14)),
                                            IconButton(
                                              padding: EdgeInsets.only(left: 10),
                                              constraints: BoxConstraints(),
                                              icon: Icon(Icons.close),
                                              iconSize: 20.0,
                                              color: Colors.red,
                                              onPressed: () {
                                                cart.removePromotion();
                                                selectedPromo = 0.0;
                                                hasSelectedPromo = false;
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      trailing: Text('-${selectedPromo.toStringAsFixed(2)}',
                                          style: TextStyle(fontSize: 14)),
                                      visualDensity: VisualDensity(vertical: -4),
                                      dense: true,
                                    ),
                                  ),
                                  Visibility(
                                      visible: hasPromo == true ? true : false,
                                      child: ListView.builder(
                                          shrinkWrap: true,
                                          physics: NeverScrollableScrollPhysics(),
                                          itemCount: autoApplyPromotionList.length,
                                          itemBuilder: (context, index) {
                                            return ListTile(
                                                title: Text('${autoApplyPromotionList[index]
                                                    .name} (${autoApplyPromotionList[index]
                                                    .promoRate})',
                                                    style: TextStyle(fontSize: 14)),
                                                visualDensity: VisualDensity(vertical: -4),
                                                dense: true,
                                                trailing: Text(
                                                    '-${autoApplyPromotionList[index].promoAmount!
                                                        .toStringAsFixed(2)}',
                                                    style: TextStyle(fontSize: 14)));
                                          })),
                                  Visibility(
                                    visible: widget.currentPage == 'bill' ? true : false,
                                    child: ListView.builder(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount: orderPromotionList.length,
                                        itemBuilder: (context, index) {
                                          return ListTile(
                                              title: Text('${orderPromotionList[index]
                                                  .promotion_name} (${orderPromotionList[index]
                                                  .rate})',
                                                  style: TextStyle(fontSize: 14)),
                                              visualDensity: VisualDensity(vertical: -4),
                                              dense: true,
                                              trailing: Text(
                                                  '-${orderPromotionList[index].promotion_amount}',
                                                  style: TextStyle(fontSize: 14)));
                                        }),
                                  ),
                                  Visibility(
                                    visible: widget.currentPage == 'menu' ||
                                        widget.currentPage == 'table' ||
                                        widget.currentPage == 'qr_order' ||
                                        widget.currentPage == 'other_order'
                                        ? true
                                        : false,
                                    child: ListView.builder(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount: currentDiningTax.length,
                                        itemBuilder: (context, index) {
                                          return ListTile(
                                            title: Text('${currentDiningTax[index]
                                                .tax_name}(${currentDiningTax[index].tax_rate}%)',
                                                style: TextStyle(fontSize: 14)),
                                            trailing: Text('${currentDiningTax[index].tax_amount
                                                ?.toStringAsFixed(2)}',
                                                style: TextStyle(fontSize: 14)),
                                            //Text(''),
                                            visualDensity: VisualDensity(vertical: -4),
                                            dense: true,
                                          );
                                        }),
                                  ),
                                  Visibility(
                                    visible: widget.currentPage == 'bill' ? true : false,
                                    child: ListView.builder(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount: orderTaxList.length,
                                        itemBuilder: (context, index) {
                                          return ListTile(
                                            title: Text('${orderTaxList[index]
                                                .tax_name}(${orderTaxList[index].rate}%)',
                                                style: TextStyle(fontSize: 14)),
                                            trailing: Text('${orderTaxList[index].tax_amount}',
                                                style: TextStyle(fontSize: 14)),
                                            //Text(''),
                                            visualDensity: VisualDensity(vertical: -4),
                                            dense: true,
                                          );
                                        }),
                                  ),
                                  ListTile(
                                    title: Text("Amount", style: TextStyle(fontSize: 14)),
                                    trailing: Text(totalAmount.toStringAsFixed(2),
                                        style: TextStyle(fontSize: 14)),
                                    visualDensity: VisualDensity(vertical: -4),
                                    dense: true,
                                  ),
                                  ListTile(
                                    title: Text("Rounding", style: TextStyle(fontSize: 14)),
                                    trailing: Text(rounding.toStringAsFixed(2),
                                        style: TextStyle(fontSize: 14)),
                                    visualDensity: VisualDensity(vertical: -4),
                                    dense: true,
                                  ),
                                  ListTile(
                                    visualDensity: VisualDensity(vertical: -4),
                                    title: Text("Final Amount", style: TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.bold)),
                                    trailing: Text(finalAmount, style: TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.bold)),
                                    dense: true,
                                  ),
                                  Visibility(
                                      visible: widget.currentPage == 'bill' ? true : false,
                                      child: Column(
                                        children: [
                                          ListTile(
                                            visualDensity: VisualDensity(vertical: -4),
                                            title: Text("Payment received",
                                                style: TextStyle(fontSize: 14)),
                                            trailing: Text(
                                                paymentReceived.toStringAsFixed(2),
                                                style: TextStyle(fontSize: 14)),
                                            dense: true,
                                          ),
                                          ListTile(
                                            visualDensity: VisualDensity(vertical: -4),
                                            title: Text("Change", style: TextStyle(fontSize: 14)),
                                            trailing: Text(paymentChange.toStringAsFixed(2),
                                                style: TextStyle(fontSize: 14)),
                                            dense: true,
                                          )
                                        ],
                                      ))
                                ],
                              ),
                            ),
                            SizedBox(height: 10),
                            Divider(
                              color: Colors.grey,
                              height: 1,
                              thickness: 1,
                              indent: 20,
                              endIndent: 20,
                            ),
                            SizedBox(height: 10),
                            //cart place order button
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                      child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: color.backgroundColor,
                                            minimumSize: const Size.fromHeight(50), // NEW
                                          ),
                                        onPressed: isButtonDisabled ? null : () async {
                                          setState(() {
                                            isButtonDisabled = false;
                                            placingOrder = true;
                                          });
                                          // await checkCashRecord();
                                          if (widget.currentPage == 'menu') {
                                            //disableButton();
                                            if(cart.cartNotifierItem.isNotEmpty){
                                              openLoadingDialogBox();
                                              if (cart.selectedOption == 'Dine in') {
                                                if (cart.selectedTable.isNotEmpty) {
                                                  print('has new item ${hasNewItem}');
                                                  if (cart.cartNotifierItem[0].status == 1 && hasNewItem == true) {
                                                    await callPlaceOrder(cart, '9');
                                                  } else {
                                                    if (cart.cartNotifierItem[0].status == 0) {
                                                      await callPlaceOrder(cart, '8');
                                                    } else {
                                                      Fluttertoast.showToast(
                                                          backgroundColor: Colors.red,
                                                          msg: AppLocalizations.of(context)!.translate('cannot_replace_same_order'));
                                                      Navigator.of(context).pop();
                                                    }
                                                  }
                                                  // cart.removeAllCartItem();
                                                  // cart.removeAllTable();
                                                } else {
                                                  if(mounted){
                                                    Fluttertoast.showToast(
                                                        backgroundColor: Colors.red,
                                                        msg: AppLocalizations.of(context)!
                                                            .translate(
                                                            'make_sure_cart_is_not_empty_and_table_is_selected'));
                                                  }
                                                }
                                              } else {
                                                // not dine in call
                                                print("Not dine in called");
                                                cart.removeAllTable();
                                                if (cart.cartNotifierItem.isNotEmpty) {
                                                  await callPlaceOrder(cart, '8');
                                                } else {
                                                  Fluttertoast.showToast(
                                                      backgroundColor: Colors.red,
                                                      msg: "${AppLocalizations.of(context)?.translate('empty_cart')}");
                                                }
                                              }
                                              cart.initialLoad();
                                            }
                                            // if (_isSettlement == true) {
                                            //   //open cash in dialog
                                            //   showDialog(
                                            //       barrierDismissible: false,
                                            //       context: context,
                                            //       builder: (BuildContext context) {
                                            //         return WillPopScope(
                                            //             child: CashDialog(isCashIn: true, callBack: () {}, isCashOut: false, isNewDay: true), onWillPop: () async => false);
                                            //       });
                                            //   _isSettlement = false;
                                            // } else {
                                            // }
                                          }
                                          // else if (widget.currentPage == 'table') {
                                          //   if (cart.selectedTable.isNotEmpty && cart.cartNotifierItem.isNotEmpty) {
                                          //     if (total == 0.0 && double.parse(finalAmount) == 0.0 || total != 0.0 && double.parse(finalAmount) != 0.0) {
                                          //       if (cart.selectedTable.length > 1 && mounted) {
                                          //         if (await confirm(
                                          //           context,
                                          //           title: Text('${AppLocalizations.of(context)
                                          //               ?.translate('confirm_merge_bill')}'),
                                          //           content: Text('${AppLocalizations.of(context)
                                          //               ?.translate('to_merge_bill')}'),
                                          //           textOK: Text('${AppLocalizations.of(context)
                                          //               ?.translate('yes')}'),
                                          //           textCancel: Text('${AppLocalizations.of(
                                          //               context)?.translate('no')}'),
                                          //         )) {
                                          //           paymentAddToCart(cart);
                                          //           return openPaymentSelect(cart);
                                          //         }
                                          //       } else {
                                          //         paymentAddToCart(cart);
                                          //         openPaymentSelect(cart);
                                          //       }
                                          //     } else {
                                          //       Fluttertoast.showToast(
                                          //           backgroundColor: Colors.red,
                                          //           msg: "Payment not match");
                                          //     }
                                          //   } else {
                                          //     Fluttertoast.showToast(backgroundColor: Colors.red,
                                          //         msg: "${AppLocalizations.of(context)?.translate(
                                          //             'empty_cart')}");
                                          //   }
                                          // }
                                          // else {
                                          //   if (cart.cartNotifierItem.isNotEmpty) {
                                          //     if (total == 0.0 && double.parse(finalAmount) == 0.0 || total != 0.0 && double.parse(finalAmount) != 0.0) {
                                          //       paymentAddToCart(cart);
                                          //       //openPaymentSelect(cart);
                                          //     } else {
                                          //       Fluttertoast.showToast(
                                          //           backgroundColor: Colors.red,
                                          //           msg: "Payment not match");
                                          //     }
                                          //   } else {
                                          //     Fluttertoast.showToast(backgroundColor: Colors.red,
                                          //         msg: "${AppLocalizations.of(context)?.translate(
                                          //             'empty_cart')}");
                                          //   }
                                          // }
                                          // else {
                                          //   if (cart.cartNotifierItem.isNotEmpty) {
                                          //     int printStatus = await printReceipt.printCartReceiptList(printerList, cart, localOrderId);
                                          //     checkPrinterStatus(printStatus);
                                          //     cart.initialLoad();
                                          //     cart.changInit(true);
                                          //   } else {
                                          //     Fluttertoast.showToast(backgroundColor: Colors.red,
                                          //         msg: "${AppLocalizations.of(context)?.translate(
                                          //             'empty_cart')}");
                                          //   }
                                          // }
                                          //enableButton();
                                        },
                                        child: MediaQuery.of(context).size.height > 500 && MediaQuery.of(context).size.width > 900 ?
                                        Text('${AppLocalizations.of(context)!.translate('place_order')}\n (RM $finalAmount)') :
                                        Text(AppLocalizations.of(context)!.translate('place_order')),
                                      ),
                                  ),
                                  //some spacing for second button
                                  // Visibility(
                                  //     child: SizedBox(
                                  //       width: 10,
                                  //     ),
                                  //     visible: widget.currentPage == "table" ||
                                  //         widget.currentPage == "other_order"
                                  //         ? true
                                  //         : widget.currentPage == "menu"
                                  //         ? cart.cartNotifierItem.any((item) => item.status == 1)
                                  //         ? true
                                  //         : false
                                  //         : false),
                                  //reprint check list
                                  // Visibility(
                                  //   visible: widget.currentPage == "menu" &&
                                  //       cart.cartNotifierItem.isNotEmpty &&
                                  //       cart.cartNotifierItem[0].status == 1 ? true : false,
                                  //   child: Expanded(
                                  //     child: ElevatedButton(
                                  //       style: ElevatedButton.styleFrom(
                                  //         backgroundColor: color.backgroundColor,
                                  //         minimumSize: const Size.fromHeight(50),
                                  //       ),
                                  //       onPressed: () {
                                  //         bool hasNotPlacedOrder = cart.cartNotifierItem.any((
                                  //             item) => item.status == 0);
                                  //         if (hasNotPlacedOrder) {
                                  //           Fluttertoast.showToast(
                                  //               backgroundColor: Colors.red,
                                  //               msg: AppLocalizations.of(context)!.translate(
                                  //                   'make_sure_all_product_is_placed_order'));
                                  //         } else {
                                  //           openReprintDialog(printerList, cart);
                                  //         }
                                  //       },
                                  //       child: Text(AppLocalizations.of(context)!.translate(
                                  //           'print_check_list')),
                                  //     ),
                                  //   ),
                                  // ),
                                  //print review receipt
                                  // Visibility(
                                  //   visible: widget.currentPage == "table" || widget.currentPage == "other_order" ? true : false,
                                  //   child: Expanded(
                                  //       child: ElevatedButton(
                                  //           style: ElevatedButton.styleFrom(
                                  //             backgroundColor: color.backgroundColor,
                                  //             minimumSize: const Size.fromHeight(50),
                                  //           ),
                                  //           onPressed: cart.cartNotifierItem.isEmpty || isLoading
                                  //               ? null
                                  //               : () async {
                                  //             setState(() {
                                  //               isLoading = true;
                                  //             });
                                  //             paymentAddToCart(cart);
                                  //             int printStatus = await printReceipt
                                  //                 .printReviewReceipt(
                                  //                 printerList, cart.selectedTable, cart, context);
                                  //             checkPrinterStatus(printStatus);
                                  //             setState(() {
                                  //               isLoading = false;
                                  //             });
                                  //           },
                                  //           child: isLoading ?
                                  //           CircularProgressIndicator(
                                  //             color: Colors.white,
                                  //             strokeWidth: 3,
                                  //           )
                                  //               : Text(AppLocalizations.of(context)!.translate(
                                  //               'print_receipt')))),
                                  // )
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return CustomProgressBar();
                    }
                  })
          );
        }),
      );
    });
  }

  paymentAddToCart(CartModel cart) {
    var value = cartPaymentDetail('', total, totalAmount, rounding, finalAmount, 0.0, 0.0, [], [],
        promotionList: autoApplyPromotionList, manualPromo: cart.selectedPromotion, taxList: taxRateList, dining_name: cart.selectedOption);
    if(cart.cartNotifierPayment.isNotEmpty){
      cart.cartNotifierPayment.clear();
      cart.addPaymentDetail(value);
    } else {
      cart.addPaymentDetail(value);
    }
  }

  checkCartItem(CartModel cart) {
    for (int i = 0; i < cart.cartNotifierItem.length; i++) {
      if (cart.cartNotifierItem[i].status == 0) {
        hasNewItem = true;
      } else {
        hasNewItem = false;
      }
    }
  }

  readAllPrinters() async {
    //printerList = await printReceipt.readAllPrinters();
  }

/*
  -----------------------Cart-item-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

/*
  Get Cart product modifier
*/
  getModifier(cartProductItem object) {
    List<String?> modifier = [];
    String result = '';
    if (object.modifier != null) {
      var length = object.modifier!.length;
      for (int i = 0; i < length; i++) {
        ModifierGroup group = object.modifier![i];
        var length = group.modifierChild!.length;
        for (int j = 0; j < length; j++) {
          if (group.modifierChild![j].isChecked!) {
            modifier.add(group.modifierChild![j].name! + '\n');
            result = modifier.toString().replaceAll('[', '').replaceAll(']', '').replaceAll(',', '+').replaceFirst('', '+ ');
          }
        }
      }
    } else {
      if (object.orderModifierDetail != null && object.orderModifierDetail!.isNotEmpty) {
        for (int i = 0; i < object.orderModifierDetail!.length; i++) {
          modifier.add(object.orderModifierDetail![i].mod_name! + '\n');
          result = modifier.toString().replaceAll('[', '').replaceAll(']', '').replaceAll(',', '+').replaceFirst('', '+ ');
        }
      }
    }
    return result;
  }

/*
  Get Cart product variant
*/
  getVariant(cartProductItem object) {
    List<String?> variant = [];
    String result = '';
    if (object.variant != null) {
      var length = object.variant!.length;
      for (int i = 0; i < length; i++) {
        VariantGroup group = object.variant![i];
        for (int j = 0; j < group.child!.length; j++) {
          if (group.child![j].isSelected!) {
            variant.add('${group.child![j].name!}\n');
            result = variant.toString().replaceAll('[', '').replaceAll(']', '').replaceAll(',', '+').replaceAll('|', '\n+').replaceFirst('', '+ ');
          }
        }
      }
    } else {
      if (object.productVariantName != null && object.productVariantName != '') {
        result = "${object.productVariantName!.replaceAll('|', '\n+').replaceFirst('', '+ ')}\n";
      }
    }
    return result;
  }
  getVariant2(cartProductItem object) {
    List<String?> variant = [];
    String result = '';
    var length = object.variant!.length;
    for (int i = 0; i < length ; i++) {
      VariantGroup group = object.variant![i];
      for (int j = 0; j < group.child!.length; j++) {
        if (group.child![j].isSelected!) {
          variant.add(group.child![j].name!);
          result = variant.toString().replaceAll('[', '').replaceAll(']', '').replaceAll(",", " |");
        }
      }
    }
    return result;
  }

/*
  Get Remark
*/
  getRemark(cartProductItem object) {
    String result = '';
    if (object.remark != '') {
      result = '*${object.remark}';
    }
    return result;
  }

/*
  Get Selected table
*/
  getSelectedTable(CartModel cart) {
    List<String> result = [];
    if (cart.selectedTable.isEmpty && cart.selectedOption == 'Dine in') {
      result.add('-');
    } else if (cart.selectedOption != 'Dine in') {
      result.add('N/A');
    } else {
      if (cart.selectedTable.length > 1) {
        for (int i = 0; i < cart.selectedTable.length; i++) {
          result.add('${cart.selectedTable[i].number}');
        }
      } else {
        result.add('${cart.selectedTable[0].number}');
      }
    }

    return result.toString().replaceAll('[', '').replaceAll(']', '');
  }

/*
  -----------------Calculation-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/
  calPromotion(CartModel cart) {
    promoAmount = 0.0;
    getAutoApplyPromotion(cart);
    getManualApplyPromotion(cart);
    // if (!controller.isClosed) {
    //   controller.sink.add('refresh');
    // }
  }

  getManualApplyPromotion(CartModel cart) {
    List<cartProductItem> sameCategoryList = [];
    allPromo = '';
    selectedPromoRate = '';
    try {
      if (cart.selectedPromotion != null) {
        allPromo = cart.selectedPromotion!.name!;
        if (cart.selectedPromotion!.type == 0) {
          selectedPromoRate = '${cart.selectedPromotion!.amount}%';
          cart.selectedPromotion!.promoRate = selectedPromoRate;
        } else {
          selectedPromoRate = '${cart.selectedPromotion!.amount!}.00';
          cart.selectedPromotion!.promoRate = selectedPromoRate;
        }

        if (cart.selectedPromotion!.specific_category == '1') {
          for (int i = 0; i < cart.cartNotifierItem.length; i++) {
            if (cart.cartNotifierItem[i].category_id == cart.selectedPromotion!.category_id) {
              sameCategoryList.add(cart.cartNotifierItem[i]);
            }
          }
          specificCategoryAmount(cart.selectedPromotion!, sameCategoryList, cart);
        } else {
          nonSpecificCategoryAmount(cart);
        }
      }
    } catch (error) {
      print('Get manual promotion error: $error');
    }
    // if (!controller.isClosed) {
    //   controller.sink.add('refresh');
    // }
  }

  specificCategoryAmount(Promotion promotion, List<cartProductItem> cartItem, CartModel cart) {
    try {
      selectedPromo = 0.0;
      hasSelectedPromo = false;

      for (int j = 0; j < cartItem.length; j++) {
        if (promotion.type == 0) {
          hasSelectedPromo = true;
          selectedPromo += (double.parse(cartItem[j].price!) * cartItem[j].quantity!) * (double.parse(promotion.amount!) / 100);
          cart.selectedPromotion!.promoAmount = selectedPromo;
        } else {
          hasSelectedPromo = true;
          selectedPromo += (double.parse(promotion.amount!) * cartItem[j].quantity!);
          cart.selectedPromotion!.promoAmount = selectedPromo;
        }
      }
      promoAmount += selectedPromo;
    } catch (e) {
      print('Specific category offer amount error: $e');
      selectedPromo = 0.0;
    }
    //controller.add('refresh');
  }

  nonSpecificCategoryAmount(CartModel cart) {
    try {
      selectedPromo = 0.0;
      hasSelectedPromo = false;

      if (cart.selectedPromotion!.type == 0) {
        hasSelectedPromo = true;
        selectedPromo = total * 0.10;
      } else {
        if (cart.cartNotifierItem.isNotEmpty) {
          for (int i = 0; i < cart.cartNotifierItem.length; i++) {
            hasSelectedPromo = true;
            selectedPromo += double.parse(cart.selectedPromotion!.amount!) * cart.cartNotifierItem[i].quantity!;
            cart.selectedPromotion!.promoAmount = selectedPromo;
          }
        }
      }
      promoAmount += selectedPromo;
      cart.selectedPromotion!.promoAmount = selectedPromo;
    } catch (error) {
      print('check promotion type error: $error');
      selectedPromo = 0.0;
    }
    //controller.add('refresh');
  }

  promotionDateTimeChecking({
    cache_created_at,
    sDate,
    eDate,
    sTime,
    eTime,
  }) {
    // String stime = "20:00";
    // String etime = '22:19';
    DateTime currentDateTime = DateTime.now();
    bool inTime = false;

    try {
      if (cache_created_at == null) {
        if (sDate != null && eDate != null && sTime != null && eTime != null) {
          //parse date
          DateTime parsedStartDate = DateTime.parse(sDate);
          DateTime parsedEndDate = DateTime.parse(eDate);
          //parse time
          DateTime startTime = DateFormat("HH:mm").parse(sTime);
          DateTime endTime = DateFormat("HH:mm").parse(eTime);
          TimeOfDay parsedStartTime = TimeOfDay.fromDateTime(startTime);
          TimeOfDay parsedEndTime = TimeOfDay.fromDateTime(endTime);

          //compare date
          int startDateComparison = currentDateTime.compareTo(parsedStartDate);
          int endDateComparison = currentDateTime.compareTo(parsedEndDate);

          //compare start time
          int startTimeComparison = currentDateTime.hour.compareTo(parsedStartTime.hour);
          if (startTimeComparison == 0) {
            startTimeComparison = currentDateTime.minute.compareTo(parsedStartTime.minute);
          }
          //compare end time
          int endTimeComparison = currentDateTime.hour.compareTo(parsedEndTime.hour);
          if (endTimeComparison == 0) {
            endTimeComparison = currentDateTime.minute.compareTo(parsedEndTime.minute);
          }

          //combine two comparison
          if (startDateComparison >= 0 && endDateComparison <= 0) {
            if (startTimeComparison >= 0 && endTimeComparison <= 0) {
              inTime = true;
            } else {
              inTime = false;
            }
          } else {
            inTime = false;
          }
        } else if (sDate != null && eDate != null) {
          DateTime parsedStartDate = DateTime.parse(sDate);
          DateTime parsedEndDate = DateTime.parse(eDate);

          int startDateComparison = currentDateTime.compareTo(parsedStartDate);
          int endDateComparison = currentDateTime.compareTo(parsedEndDate);

          if (startDateComparison >= 0 && endDateComparison <= 0) {
            inTime = true;
          } else {
            inTime = false;
          }
        } else if (sTime != null && eTime != null) {
          DateTime startTime = DateFormat("HH:mm").parse(sTime);
          DateTime endTime = DateFormat("HH:mm").parse(eTime);

          TimeOfDay parsedStartTime = TimeOfDay.fromDateTime(startTime);
          TimeOfDay parsedEndTime = TimeOfDay.fromDateTime(endTime);
          //compare start time
          int startTimeComparison = currentDateTime.hour.compareTo(parsedStartTime.hour);
          if (startTimeComparison == 0) {
            startTimeComparison = currentDateTime.minute.compareTo(parsedStartTime.minute);
          }
          //compare end time
          int endTimeComparison = currentDateTime.hour.compareTo(parsedEndTime.hour);
          if (endTimeComparison == 0) {
            endTimeComparison = currentDateTime.minute.compareTo(parsedEndTime.minute);
          }
          //combine two comparison
          if (startTimeComparison >= 0 && endTimeComparison <= 0) {
            inTime = true;
          } else {
            inTime = false;
          }
        }
      } else {
        //compare with order cache created date time
        if (sDate != null && eDate != null && sTime != null && eTime != null) {
          //parse date
          DateTime parsedCacheDate = DateTime.parse(cache_created_at);
          DateTime parsedStartDate = DateTime.parse(sDate);
          DateTime parsedEndDate = DateTime.parse(eDate);
          //format time
          String formatDate = DateFormat("HH:mm").format(parsedCacheDate);
          //parse time
          DateTime cacheTime = DateFormat("HH:mm").parse(formatDate);
          DateTime startTime = DateFormat("HH:mm").parse(sTime);
          DateTime endTime = DateFormat("HH:mm").parse(eTime);
          TimeOfDay parsedCacheTime = TimeOfDay.fromDateTime(cacheTime);
          TimeOfDay parsedStartTime = TimeOfDay.fromDateTime(startTime);
          TimeOfDay parsedEndTime = TimeOfDay.fromDateTime(endTime);
          //compare date
          int startDateComparison = parsedCacheDate.compareTo(parsedStartDate);
          int endDateComparison = parsedCacheDate.compareTo(parsedEndDate);

          //compare start time
          int startTimeComparison = parsedCacheTime.hour.compareTo(parsedStartTime.hour);
          if (startTimeComparison == 0) {
            startTimeComparison = parsedCacheTime.minute.compareTo(parsedStartTime.minute);
          }
          //compare end time
          int endTimeComparison = parsedCacheTime.hour.compareTo(parsedEndTime.hour);
          if (endTimeComparison == 0) {
            endTimeComparison = parsedCacheTime.minute.compareTo(parsedEndTime.minute);
          }
          //combine two comparison
          if (startDateComparison >= 0 && endDateComparison <= 0) {
            if (startTimeComparison >= 0 && endTimeComparison <= 0) {
              inTime = true;
            } else {
              inTime = false;
            }
          } else {
            inTime = false;
          }
        } else if (sDate != null && eDate != null) {
          DateTime parsedCacheDate = DateTime.parse(cache_created_at);
          DateTime parsedStartDate = DateTime.parse(sDate);
          DateTime parsedEndDate = DateTime.parse(eDate);

          int startDateComparison = parsedCacheDate.compareTo(parsedStartDate);
          int endDateComparison = parsedCacheDate.compareTo(parsedEndDate);

          if (startDateComparison >= 0 && endDateComparison <= 0) {
            inTime = true;
          } else {
            inTime = false;
          }
        } else if (sTime != null && eTime != null) {
          DateTime cacheDate = DateTime.parse(cache_created_at);

          String formatDate = DateFormat("HH:mm").format(cacheDate);

          DateTime cacheTime = DateFormat("HH:mm").parse(formatDate);
          DateTime startTime = DateFormat("HH:mm").parse(sTime);
          DateTime endTime = DateFormat("HH:mm").parse(eTime);

          TimeOfDay parsedCacheTime = TimeOfDay.fromDateTime(cacheTime);
          TimeOfDay parsedStartTime = TimeOfDay.fromDateTime(startTime);
          TimeOfDay parsedEndTime = TimeOfDay.fromDateTime(endTime);
          //compare start time
          int startTimeComparison = parsedCacheTime.hour.compareTo(parsedStartTime.hour);
          if (startTimeComparison == 0) {
            startTimeComparison = parsedCacheTime.minute.compareTo(parsedStartTime.minute);
          }
          //compare end time
          int endTimeComparison = parsedCacheTime.hour.compareTo(parsedEndTime.hour);
          if (endTimeComparison == 0) {
            endTimeComparison = parsedCacheTime.minute.compareTo(parsedEndTime.minute);
          }
          //combine two comparison
          if (startTimeComparison >= 0 && endTimeComparison <= 0) {
            inTime = true;
          } else {
            inTime = false;
          }
        }
      }
      return inTime;
    } catch (e) {
      print('error caught:$e');
      return;
    }
  }

  getAutoApplyPromotion(CartModel cart) {
    try {
      //cart.removeAutoPromotion();
      autoApplyPromotionList = [];
      promoName = '';
      hasPromo = false;
      if (cart.cartNotifierItem.isNotEmpty) {
        //loop promotion list get promotion
        for (int j = 0; j < promotionList.length; j++) {
          promotionList[j].promoAmount = 0.0;
          //check is the promotion auto apply
          if (promotionList[j].auto_apply == '1') {
            //check is promotion all day & all time
            if (promotionList[j].all_day == '1' && promotionList[j].all_time == '1') {
              if (promotionList[j].specific_category == '1') {
                //Auto apply specific category promotion
                for (int m = 0; m < cart.cartNotifierItem.length; m++) {
                  if (cart.cartNotifierItem[m].category_id == promotionList[j].category_id) {
                    hasPromo = true;
                    promoName = promotionList[j].name!;
                    if (!autoApplyPromotionList.contains(promotionList[j])) {
                      autoApplyPromotionList.add(promotionList[j]);
                      if (widget.currentPage != 'menu') {
                        cart.addAutoApplyPromo(promotionList[j]);
                      }
                    }
                    autoApplySpecificCategoryAmount(promotionList[j], cart.cartNotifierItem[m]);
                  }
                }
              } else {
                //Auto apply non specific category promotion
                if (cart.cartNotifierItem.isNotEmpty) {
                  hasPromo = true;
                  autoApplyPromotionList.add(promotionList[j]);
                  if (widget.currentPage != 'menu') {
                    cart.addAutoApplyPromo(promotionList[j]);
                  }
                  promoName = promotionList[j].name!;
                  autoApplyNonSpecificCategoryAmount(promotionList[j], cart);
                }
              }
            } else {
              if (promotionList[j].all_day == '0' && promotionList[j].all_time == '0') {
                if (cart.cartNotifierItem[0].status == 0) {
                  if (promotionDateTimeChecking(
                          sDate: promotionList[j].sdate,
                          eDate: promotionList[j].edate,
                          sTime: promotionList[j].stime,
                          eTime: promotionList[j].etime) ==
                      true) {
                    if (promotionList[j].specific_category == '1') {
                      //Auto apply specific category promotion
                      for (int m = 0; m < cart.cartNotifierItem.length; m++) {
                        if (cart.cartNotifierItem[m].category_id == promotionList[j].category_id) {
                          hasPromo = true;
                          promoName = promotionList[j].name!;
                          if (!autoApplyPromotionList.contains(promotionList[j])) {
                            autoApplyPromotionList.add(promotionList[j]);
                            if (widget.currentPage != 'menu') {
                              cart.addAutoApplyPromo(promotionList[j]);
                            }
                          }
                          autoApplySpecificCategoryAmount(promotionList[j], cart.cartNotifierItem[m]);
                        }
                      }
                    } else {
                      //Auto apply non specific category promotion
                      if (cart.cartNotifierItem.isNotEmpty) {
                        hasPromo = true;
                        autoApplyPromotionList.add(promotionList[j]);
                        if (widget.currentPage != 'menu') {
                          cart.addAutoApplyPromo(promotionList[j]);
                        }
                        promoName = promotionList[j].name!;
                        autoApplyNonSpecificCategoryAmount(promotionList[j], cart);
                      }
                    }
                  }
                } else {
                  if (promotionDateTimeChecking(
                          sDate: promotionList[j].sdate,
                          eDate: promotionList[j].edate,
                          sTime: promotionList[j].stime,
                          eTime: promotionList[j].etime,
                          cache_created_at: cart.cartNotifierItem[0].first_cache_created_date_time) ==
                      true) {
                    if (promotionList[j].specific_category == '1') {
                      //Auto apply specific category promotion
                      for (int m = 0; m < cart.cartNotifierItem.length; m++) {
                        if (cart.cartNotifierItem[m].category_id == promotionList[j].category_id) {
                          hasPromo = true;
                          promoName = promotionList[j].name!;
                          if (!autoApplyPromotionList.contains(promotionList[j])) {
                            autoApplyPromotionList.add(promotionList[j]);
                            if (widget.currentPage != 'menu') {
                              cart.addAutoApplyPromo(promotionList[j]);
                            }
                          }
                          autoApplySpecificCategoryAmount(promotionList[j], cart.cartNotifierItem[m]);
                        }
                      }
                    } else {
                      //Auto apply non specific category promotion
                      if (cart.cartNotifierItem.isNotEmpty) {
                        hasPromo = true;
                        autoApplyPromotionList.add(promotionList[j]);
                        if (widget.currentPage != 'menu') {
                          cart.addAutoApplyPromo(promotionList[j]);
                        }
                        promoName = promotionList[j].name!;
                        autoApplyNonSpecificCategoryAmount(promotionList[j], cart);
                      }
                    }
                  }
                }
              } else if (promotionList[j].all_day == '0' && promotionList[j].all_time == '1') {
                //check cart item status and promotion time
                if (cart.cartNotifierItem[0].status == 0) {
                  if (promotionDateTimeChecking(sDate: promotionList[j].sdate, eDate: promotionList[j].edate) == true) {
                    if (promotionList[j].specific_category == '1') {
                      //Auto apply specific category promotion
                      for (int m = 0; m < cart.cartNotifierItem.length; m++) {
                        if (cart.cartNotifierItem[m].category_id == promotionList[j].category_id) {
                          hasPromo = true;
                          promoName = promotionList[j].name!;
                          if (!autoApplyPromotionList.contains(promotionList[j])) {
                            autoApplyPromotionList.add(promotionList[j]);
                            if (widget.currentPage != 'menu') {
                              cart.addAutoApplyPromo(promotionList[j]);
                            }
                          }
                          autoApplySpecificCategoryAmount(promotionList[j], cart.cartNotifierItem[m]);
                        }
                      }
                    } else {
                      //Auto apply non specific category promotion
                      if (cart.cartNotifierItem.isNotEmpty) {
                        hasPromo = true;
                        autoApplyPromotionList.add(promotionList[j]);
                        if (widget.currentPage != 'menu') {
                          cart.addAutoApplyPromo(promotionList[j]);
                        }
                        promoName = promotionList[j].name!;
                        autoApplyNonSpecificCategoryAmount(promotionList[j], cart);
                      }
                    }
                  }
                } else {
                  if (promotionDateTimeChecking(
                          sDate: promotionList[j].sdate,
                          eDate: promotionList[j].edate,
                          cache_created_at: cart.cartNotifierItem[0].first_cache_created_date_time) ==
                      true) {
                    if (promotionList[j].specific_category == '1') {
                      //Auto apply specific category promotion
                      for (int m = 0; m < cart.cartNotifierItem.length; m++) {
                        if (cart.cartNotifierItem[m].category_id == promotionList[j].category_id) {
                          hasPromo = true;
                          promoName = promotionList[j].name!;
                          if (!autoApplyPromotionList.contains(promotionList[j])) {
                            autoApplyPromotionList.add(promotionList[j]);
                            if (widget.currentPage != 'menu') {
                              cart.addAutoApplyPromo(promotionList[j]);
                            }
                          }
                          autoApplySpecificCategoryAmount(promotionList[j], cart.cartNotifierItem[m]);
                        }
                      }
                    } else {
                      //Auto apply non specific category promotion
                      if (cart.cartNotifierItem.isNotEmpty) {
                        hasPromo = true;
                        autoApplyPromotionList.add(promotionList[j]);
                        if (widget.currentPage != 'menu') {
                          cart.addAutoApplyPromo(promotionList[j]);
                        }
                        promoName = promotionList[j].name!;
                        autoApplyNonSpecificCategoryAmount(promotionList[j], cart);
                      }
                    }
                  }
                }
              } else if (promotionList[j].all_time == '0' && promotionList[j].all_day == '1') {
                //check cart item status and promotion time
                if (cart.cartNotifierItem[0].status == 0) {
                  if (promotionDateTimeChecking(sTime: promotionList[j].stime, eTime: promotionList[j].etime) == true) {
                    if (promotionList[j].specific_category == '1') {
                      //Auto apply specific category promotion
                      for (int m = 0; m < cart.cartNotifierItem.length; m++) {
                        if (cart.cartNotifierItem[m].category_id == promotionList[j].category_id) {
                          hasPromo = true;
                          promoName = promotionList[j].name!;
                          if (!autoApplyPromotionList.contains(promotionList[j])) {
                            autoApplyPromotionList.add(promotionList[j]);
                            if (widget.currentPage != 'menu') {
                              cart.addAutoApplyPromo(promotionList[j]);
                            }
                          }
                          autoApplySpecificCategoryAmount(promotionList[j], cart.cartNotifierItem[m]);
                        }
                      }
                    } else {
                      //Auto apply non specific category promotion
                      if (cart.cartNotifierItem.isNotEmpty) {
                        hasPromo = true;
                        autoApplyPromotionList.add(promotionList[j]);
                        if (widget.currentPage != 'menu') {
                          cart.addAutoApplyPromo(promotionList[j]);
                        }
                        promoName = promotionList[j].name!;
                        autoApplyNonSpecificCategoryAmount(promotionList[j], cart);
                      }
                    }
                  }
                } else {
                  if (promotionDateTimeChecking(
                          sTime: promotionList[j].stime,
                          eTime: promotionList[j].etime,
                          cache_created_at: cart.cartNotifierItem[0].first_cache_created_date_time) ==
                      true) {
                    if (promotionList[j].specific_category == '1') {
                      //Auto apply specific category promotion
                      for (int m = 0; m < cart.cartNotifierItem.length; m++) {
                        if (cart.cartNotifierItem[m].category_id == promotionList[j].category_id) {
                          hasPromo = true;
                          promoName = promotionList[j].name!;
                          if (!autoApplyPromotionList.contains(promotionList[j])) {
                            autoApplyPromotionList.add(promotionList[j]);
                            if (widget.currentPage != 'menu') {
                              cart.addAutoApplyPromo(promotionList[j]);
                            }
                          }
                          autoApplySpecificCategoryAmount(promotionList[j], cart.cartNotifierItem[m]);
                        }
                      }
                    } else {
                      //Auto apply non specific category promotion
                      if (cart.cartNotifierItem.isNotEmpty) {
                        hasPromo = true;
                        autoApplyPromotionList.add(promotionList[j]);
                        if (widget.currentPage != 'menu') {
                          cart.addAutoApplyPromo(promotionList[j]);
                        }
                        promoName = promotionList[j].name!;
                        autoApplyNonSpecificCategoryAmount(promotionList[j], cart);
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    } catch (error) {
      print('Promotion error $error');
      promo = 0.0;
    }
    // if (!controller.isClosed) {
    //   controller.sink.add('refresh');
    // }
  }

  autoApplyNonSpecificCategoryAmount(Promotion promotion, CartModel cart) {
    try {
      promo = 0.0;
      for (int i = 0; i < cart.cartNotifierItem.length; i++) {
        if (promotion.type == 1) {
          promo += (double.parse(promotion.amount!) * cart.cartNotifierItem[i].quantity!);
          promotion.promoAmount = promo;
          promoRate = 'RM${promotion.amount!}';
          promotion.promoRate = promoRate;
        } else {
          promo += (double.parse(cart.cartNotifierItem[i].price!) * cart.cartNotifierItem[i].quantity!) * (double.parse(promotion.amount!) / 100);
          promotion.promoAmount = promo;
          promoRate = '${promotion.amount!}%';
          promotion.promoRate = promoRate;
        }
      }
      promoAmount += promo;
    } catch (e) {
      print("calc auto apply non specific error: $e");
      promoRate = '';
      promo = 0.0;
    }

    //controller.add('refresh');
  }

  autoApplySpecificCategoryAmount(Promotion promotion, cartProductItem cartItem) {
    try {
      promo = 0.0;
      if (promotion.type == 1) {
        promo += (double.parse(promotion.amount!) * cartItem.quantity!);
        promotion.promoAmount = promotion.promoAmount! + promo;
        promoRate = 'RM${promotion.amount!}';
        promotion.promoRate = promoRate;
      } else {
        promo += (double.parse(cartItem.price!) * cartItem.quantity!) * (double.parse(promotion.amount!) / 100);
        promotion.promoAmount = promotion.promoAmount! + promo;
        promoRate = '${promotion.amount!}%';
        promotion.promoRate = promoRate;
      }
      promoAmount += promo;
    } catch (e) {
      print("calc auto apply specific category error: $e");
      promoRate = '';
      promo = 0.0;
    }
    //controller.add('refresh');
  }

  getDiningTax(CartModel cart) async {
    // final prefs = await SharedPreferences.getInstance();
    // final int? branch_id = prefs.getInt('branch_id');
    // try {
    //   //get dining option data
    //   List<DiningOption> data = await PosDatabase.instance.checkSelectedOption(cart.selectedOption);
    //   if(data.isNotEmpty){
    //     diningOptionID = data[0].dining_id!;
    //
    //     //get dining tax
    //     List<Tax> taxData = await PosDatabase.instance.readTax(branch_id.toString(), diningOptionID.toString());
    //     if (taxData.isNotEmpty) {
    //       taxRateList = List.from(taxData);
    //     } else {
    //       taxRateList = [];
    //     }
    //   }
    // } catch (error) {
    //   print('get dining tax in cart error: $error');
    // }
    // if (!controller.isClosed) {
    //   controller.sink.add('refresh');
    // }
  }

/*
  receipt menu initial call
*/
  // getReceiptPaymentDetail(CartModel cart) {
  //   this.total = 0.0;
  //   this.totalAmount = 0.0;
  //   this.rounding = 0.0;
  //   this.finalAmount = '0.00';
  //   this.paymentReceived = 0.0;
  //   this.paymentChange = 0.0;
  //   this.orderTaxList = [];
  //   this.orderPromotionList = [];
  //   this.localOrderId = '';
  //
  //   for (int i = 0; i < cart.cartNotifierPayment.length; i++) {
  //     this.total = cart.cartNotifierPayment[i].subtotal;
  //     this.totalAmount = cart.cartNotifierPayment[i].amount;
  //     this.rounding = cart.cartNotifierPayment[i].rounding;
  //     this.finalAmount = cart.cartNotifierPayment[i].finalAmount;
  //     this.paymentReceived = cart.cartNotifierPayment[i].paymentReceived;
  //     this.paymentChange = cart.cartNotifierPayment[i].paymentChange;
  //     this.orderTaxList = cart.cartNotifierPayment[i].orderTaxList;
  //     this.orderPromotionList = cart.cartNotifierPayment[i].orderPromotionDetail;
  //     this.localOrderId = cart.cartNotifierPayment[i].localOrderId;
  //   }
  //   // if (!controller.isClosed) {
  //   //   controller.sink.add('refresh');
  //   // }
  // }

/*
  Cart Ordering initial called
*/
  getSubTotal(CartModel cart) async {
    try {
      if(!isFirstLoad){
        isFirstLoad = true;
        await preload();
      }
      //widget.currentPage == 'table' || widget.currentPage == 'qr_order' ? cart.selectedOption = 'Dine in' : null;
      total = 0.0;
      newOrderSubtotal = 0.0;
      promo = 0.0;
      promoAmount = 0.0;
      for (int i = 0; i < cart.cartNotifierItem.length; i++) {
        total += (double.parse((cart.cartNotifierItem[i].price!)) * cart.cartNotifierItem[i].quantity!);
        if (cart.cartNotifierItem[i].status == 0) {
          newOrderSubtotal += (double.parse((cart.cartNotifierItem[i].price!)) * cart.cartNotifierItem[i].quantity!);
          cart.subtotal = newOrderSubtotal.toStringAsFixed(2);
        }
      }
    } catch (e) {
      print('Sub Total Error: $e');
      total = 0.0;
    }
    //await getDiningTax(cart);
    calPromotion(cart);
    getTaxAmount(cart);
    getRounding();
    getAllTotal();
    checkCartItem(cart);
    if (cart.myCount == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollDown();
      });
      cart.myCount++;
    }

    cartController.sink.add("refresh");
    // if (!controller.isClosed) {
    //   controller.sink.add('refresh');
    // }
  }

  void getTaxAmount(CartModel cart) {
    try {
      discountPrice = total - promoAmount;
      currentDiningTax = taxLinkDiningList.where((tax) => tax.dining_id == cart.selectedOptionId).toList();
      print("current dining tax: ${currentDiningTax.length}");
      if (currentDiningTax.isNotEmpty) {
        for (int i = 0; i < currentDiningTax.length; i++) {
          priceIncTaxes = discountPrice * (double.parse(currentDiningTax[i].tax_rate!) / 100);
          currentDiningTax[i].tax_amount = priceIncTaxes;
        }
      }
    } catch (e) {
      print('get tax amount error: $e');
    }
    // if (!controller.isClosed) {
    //   controller.sink.add('refresh');
    // }
  }

  double sumAllTaxAmount() {
    double total = 0.0;
    for (int i = 0; i < currentDiningTax.length; i++) {
      total = total + currentDiningTax[i].tax_amount!;
    }
    return total;
  }

  void getRounding() {
    double round = 0.0;
    totalAmount = 0.0;
    discountPrice = total - promoAmount;
    totalAmount = discountPrice + sumAllTaxAmount();
    round = Utils.roundToNearestFiveSen(double.parse(totalAmount.toStringAsFixed(2))) - double.parse(totalAmount.toStringAsFixed(2));
    rounding = round;

    // if (!controller.isClosed) {
    //   controller.sink.add('refresh');
    // }
  }

  getAllTotal() {
    try {
      finalAmount = Utils.roundToNearestFiveSen(double.parse(totalAmount.toStringAsFixed(2))).toStringAsFixed(2);
    } catch (error) {
      print('Total calc error: $error');
    }

    // if (!controller.isClosed) {
    //   controller.sink.add('refresh');
    // }
  }

/*
  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/
  // Future<Future<Object?>> openReprintDialog(List<Printer> printerList, CartModel cart) async {
  //   return showGeneralDialog(
  //       barrierColor: Colors.black.withOpacity(0.5),
  //       transitionBuilder: (context, a1, a2, widget) {
  //         final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
  //         return Transform(
  //           transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
  //           child: Opacity(
  //             opacity: a1.value,
  //             child: ReprintDialog(
  //               printerList: printerList,
  //               cart: cart,
  //             ),
  //           ),
  //         );
  //       },
  //       transitionDuration: Duration(milliseconds: 200),
  //       barrierDismissible: false,
  //       context: context,
  //       pageBuilder: (context, animation1, animation2) {
  //         // ignore: null_check_always_fails
  //         return null!;
  //       });
  // }

  Future<Future<Object?>> openChooseTableDialog(CartModel cartModel) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: CartDialog(
                selectedTableList: cartModel.selectedTable,
              ),
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 200),
        barrierDismissible: false,
        context: context,
        pageBuilder: (context, animation1, animation2) {
          // ignore: null_check_always_fails
          return null!;
        });
  }

  // Future<Future<Object?>> openPromotionDialog() async {
  //   return showGeneralDialog(
  //       barrierColor: Colors.black.withOpacity(0.5),
  //       transitionBuilder: (context, a1, a2, widget) {
  //         final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
  //         return Transform(
  //           transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
  //           child: Opacity(
  //             opacity: a1.value,
  //             child: PromotionDialog(),
  //           ),
  //         );
  //       },
  //       transitionDuration: Duration(milliseconds: 200),
  //       barrierDismissible: false,
  //       context: context,
  //       pageBuilder: (context, animation1, animation2) {
  //         // ignore: null_check_always_fails
  //         return null!;
  //       });
  // }

  Future<Future<Object?>> openRemoveCartItemDialog(cartProductItem item, String currentPage) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: CartRemoveDialog(
                cartItem: item,
                currentPage: currentPage,
              ),
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 200),
        barrierDismissible: false,
        context: context,
        pageBuilder: (context, animation1, animation2) {
          // ignore: null_check_always_fails
          return null!;
        });
  }

  Future<Future<Object?>> openLoadingDialogBox() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: LoadingDialog(),
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 200),
        barrierDismissible: false,
        context: context,
        pageBuilder: (context, animation1, animation2) {
          // ignore: null_check_always_fails
          return null!;
        });
  }

  // openPaymentSelect(CartModel cart) async {
  //   return showGeneralDialog(
  //       barrierColor: Colors.black.withOpacity(0.5),
  //       transitionBuilder: (context, a1, a2, widget) {
  //         final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
  //         return Transform(
  //           transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
  //           child: Opacity(
  //             opacity: a1.value,
  //             child: PaymentSelect(dining_id: diningOptionID.toString(), dining_name: cart.selectedOption),
  //           ),
  //         );
  //       },
  //       transitionDuration: Duration(milliseconds: 200),
  //       barrierDismissible: false,
  //       context: context,
  //       pageBuilder: (context, animation1, animation2) {
  //         // ignore: null_check_always_fails
  //         return null!;
  //       });
  // }

  // Future<Future<Object?>> openLogOutDialog() async {
  //   return showGeneralDialog(
  //       barrierColor: Colors.black.withOpacity(0.5),
  //       transitionBuilder: (context, a1, a2, widget) {
  //         final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
  //         return Transform(
  //           transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
  //           child: Opacity(
  //             opacity: a1.value,
  //             child: LogoutConfirmDialog(),
  //           ),
  //         );
  //       },
  //       transitionDuration: Duration(milliseconds: 200),
  //       barrierDismissible: false,
  //       context: context,
  //       pageBuilder: (context, animation1, animation2) {
  //         // ignore: null_check_always_fails
  //         return null!;
  //       });
  // }

  checkCashRecord() async {
    // List<CashRecord> data = await PosDatabase.instance.readBranchCashRecord();
    // if (data.length <= 0) {
    //   _isSettlement = true;
    // } else {
    //   _isSettlement = false;
    // }
  }

  // readAllBranchLinkDiningOption() async {
  //   diningList.clear();
  //   branchLinkDiningIdList.clear();
  //   final prefs = await SharedPreferences.getInstance();
  //   final int? branch_id = prefs.getInt('branch_id');
  //   List<BranchLinkDining> data = await PosDatabase.instance.readBranchLinkDiningOption(branch_id!.toString());
  //   for (int i = 0; i < data.length; i++) {
  //     diningList.add(data[i]);
  //     branchLinkDiningIdList.add(data[i].dining_id!);
  //   }
  //   if (!controller.isClosed) {
  //     controller.sink.add('refresh');
  //   }
  // }
  //
  // void getPromotionData() async {
  //   promotionList.clear();
  //   try {
  //     List<BranchLinkPromotion> data = await PosDatabase.instance.readBranchLinkPromotion();
  //     for (int i = 0; i < data.length; i++) {
  //       List<Promotion> temp = await PosDatabase.instance.checkPromotion(data[i].promotion_id!);
  //       if (temp.isNotEmpty) promotionList.add(temp[0]);
  //     }
  //   } catch (error) {
  //     print('promotion list error $error');
  //   }
  // }

  // resetValue() {
  //   this.table_use_value = [].toString();
  //   this.table_use_detail_value = [].toString();
  //   this.order_cache_value = [].toString();
  //   this.order_detail_value = [].toString();
  //   this.order_modifier_detail_value = [].toString();
  //   this.branch_link_product_value = [].toString();
  //   this.table_value = [].toString();
  // }

/*
  Not dine in call
*/
  callPlaceOrder(CartModel cart, String action) async {
    print("json cart model: ${jsonEncode(cart)}");
    await clientAction.connectRequestPort(action: action, param: jsonEncode(cart), callback: responseStatusCheck);
    // resetValue();
    // if(cart.selectedOption == "Take Away"){
    //   print("json cart model: ${jsonEncode(cart)}");
    //   await clientAction.connectRequestPort(action: '9', param: jsonEncode(cart));
    // } else {
    //   //await clientAction.connectRequestPort(action: '10', param: jsonEncode(cart.cartNotifierItem));
    // }
    // await createOrderCache(cart, connectivity);
    // await createOrderDetail(cart, connectivity);
    // await syncAllToCloud();
    // if(this.isLogOut == true){
    //   openLogOutDialog();
    //   return;
    // }
    // await printReceipt.printCheckList(printerList, int.parse(this.orderCacheId), context);
    // await printReceipt.printKitchenList(printerList, context, cart, int.parse(this.orderCacheId));
  }

  void responseStatusCheck(response){
    var json = jsonDecode(response);
    if(json['status'] == '1'){
      Navigator.of(context).pop();
    }
  }

/*
  dine in call
*/
  callCreateNewOrder(CartModel cart) async {
    Map<String, dynamic>? objectData = {
      'cartNotifierItem': cart.cartNotifierItem,
      'selectedTable': cart.selectedTable,
    };
    await clientAction.connectRequestPort(action: '8', param: jsonEncode(objectData));
    // await createTableUseID(connectivity);
    // await createTableUseDetail(cart);
    // await createOrderCache(cart, connectivity);
    // await createOrderDetail(cart, connectivity);
    // await updatePosTable(cart, connectivity);
    // await syncAllToCloud();
    // if(this.isLogOut == true){
    //   openLogOutDialog();
    //   return;
    // }
    // await printReceipt.printCheckList(printerList, int.parse(this.orderCacheId), context);
    // await printReceipt.printKitchenList(printerList, context, cart, int.parse(this.orderCacheId));
  }

/*
  add-on call (dine in)
*/
  callAddOrderCache(CartModel cart) async {
    Map<String, dynamic>? objectData = {
      'cartNotifierItem': cart.cartNotifierItem,
      'selectedTable': cart.selectedTable,
    };
    await clientAction.connectRequestPort(action: '9', param: jsonEncode(objectData));
    // await createOrderCache(cart, connectivity, isAddOrder: true);
    // await createOrderDetail(cart, connectivity);
    // await syncAllToCloud();
    // if(this.isLogOut == true){
    //   openLogOutDialog();
    //   return;
    // }
    // await printReceipt.printCheckList(printerList, int.parse(this.orderCacheId), context);
    // await printReceipt.printKitchenList(printerList, context, cart, int.parse(this.orderCacheId));
  }

  randomColor() {
    return Color(Random().nextInt(0xffffffff)).withAlpha(0xff);
  }

  colorToHex(Color color) {
    String hex = '#${color.value.toRadixString(16).substring(2)}';
    return hex;
  }

  hexToInteger(String hexCode) {
    int temp = int.parse(hexCode, radix: 16);
    return temp;
  }

  // colorChecking() async {
  //   String? hexCode;
  //   bool colorFound = false;
  //   bool found = false;
  //   int tempColor = 0;
  //   int matchColor = 0;
  //   int diff = 0;
  //   int count = 0;
  //   final prefs = await SharedPreferences.getInstance();
  //   final int? branch_id = prefs.getInt('branch_id');
  //   List<TableUse> data = await PosDatabase.instance.readAllTableUseId(branch_id!);
  //
  //   while (colorFound == false) {
  //     /* change color */
  //     hexCode = colorToHex(randomColor());
  //     if (data.length > 0) {
  //       for (int i = 0; i < data.length; i++) {
  //         if (hexCode == data[i].card_color) {
  //           found = false;
  //           break;
  //         } else {
  //           tempColor = hexToInteger(hexCode!.replaceAll('#', ''));
  //           matchColor = hexToInteger(data[i].card_color!.replaceAll('#', ''));
  //           diff = tempColor - matchColor;
  //           if (diff.abs() < 160000) {
  //             print('color too close or not yet loop finish');
  //             print('diff: ${diff.abs()}');
  //             found = false;
  //             break;
  //           } else {
  //             print('color is ok');
  //             print('diff: ${diff}');
  //             if (i < data.length) {
  //               continue;
  //             }
  //           }
  //         }
  //       }
  //       found = true;
  //     } else {
  //       found = true;
  //       break;
  //     }
  //     if (found == true) colorFound = true;
  //   }
  //   return hexCode;
  // }

  // randomBatch() {
  //   return Random().nextInt(1000000) + 1;
  // }
  //
  // batchChecking() async {
  //   print('batch checking called!');
  //   int tempBatch = 0;
  //   bool batchFound = false;
  //   bool founded = false;
  //   final prefs = await SharedPreferences.getInstance();
  //   final int? branch_id = prefs.getInt('branch_id');
  //
  //   List<OrderCache> data = await PosDatabase.instance.readBranchOrderCache(branch_id!);
  //   while (batchFound == false) {
  //     tempBatch = randomBatch();
  //     if (data.length > 0) {
  //       for (int i = 0; i < data.length; i++) {
  //         if (tempBatch.toString() == data[i].batch_id!.toString()) {
  //           print('batch same!');
  //           founded = false;
  //           break;
  //         } else {
  //           if (i < data.length) {
  //             print('not yet loop finish');
  //             continue;
  //           }
  //         }
  //       }
  //       founded = true;
  //     } else {
  //       founded = true;
  //       break;
  //     }
  //
  //     if (founded == true) batchFound = true;
  //   }
  //   return tempBatch;
  // }

/*
  ---------------Place Order part--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/
  // createTableUseID(ConnectivityChangeNotifier connectivity) async {
  //   List<String> _value = [];
  //   DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
  //   String dateTime = dateFormat.format(DateTime.now());
  //   final prefs = await SharedPreferences.getInstance();
  //   final int? branch_id = prefs.getInt('branch_id');
  //   String? hexCode;
  //   localTableUseId = '';
  //   try {
  //     hexCode = await colorChecking();
  //     if (hexCode != null) {
  //       TableUse data = TableUse(
  //           table_use_id: 0,
  //           branch_id: branch_id,
  //           table_use_key: '',
  //           order_cache_key: '',
  //           card_color: hexCode.toString(),
  //           status: 0,
  //           sync_status: 0,
  //           created_at: dateTime,
  //           updated_at: '',
  //           soft_delete: '');
  //       //create table use data
  //       TableUse tableUseData = await PosDatabase.instance.insertSqliteTableUse(data);
  //       localTableUseId = tableUseData.table_use_sqlite_id.toString();
  //       TableUse _updatedTableUseData = await insertTableUseKey(tableUseData, dateTime);
  //       _value.add(jsonEncode(_updatedTableUseData));
  //       //sync tot cloud
  //       //await syncTableUseIdToCloud(_updatedTableUseData);
  //     }
  //   } catch (e) {
  //     print(e);
  //     Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "Create table id error: ${e}");
  //   }
  // }

  // syncTableUseIdToCloud(TableUse updatedTableUseData) async {
  //   List<String> _value = [];
  //   //check is host reachable
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     _value.add(jsonEncode(updatedTableUseData));
  //     Map response = await Domain().SyncTableUseToCloud(_value.toString());
  //     if (response['status'] == '1') {
  //       List responseJson = response['data'];
  //       int syncData = await PosDatabase.instance.updateTableUseSyncStatusFromCloud(responseJson[0]['table_use_key']);
  //     }
  //   }
  // }

  // generateTableUseKey(TableUse tableUse) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final int? device_id = prefs.getInt('device_id');
  //   var bytes = tableUse.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') + tableUse.table_use_sqlite_id.toString() + device_id.toString();
  //   return md5.convert(utf8.encode(bytes)).toString();
  // }

  // insertTableUseKey(TableUse tableUse, String dateTime) async {
  //   TableUse? _tbUseList;
  //   tableUseKey = await generateTableUseKey(tableUse);
  //   if (tableUseKey != null) {
  //     TableUse tableUseObject =
  //         TableUse(table_use_key: tableUseKey, sync_status: 0, updated_at: dateTime, table_use_sqlite_id: tableUse.table_use_sqlite_id);
  //     int tableUseData = await PosDatabase.instance.updateTableUseUniqueKey(tableUseObject);
  //     if (tableUseData == 1) {
  //       TableUse data = await PosDatabase.instance.readSpecificTableUseIdByLocalId(tableUseObject.table_use_sqlite_id!);
  //       _tbUseList = data;
  //     }
  //   }
  //   return _tbUseList;
  // }

  // generateTableUseDetailKey(TableUseDetail tableUseDetail) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final int? device_id = prefs.getInt('device_id');
  //   var bytes = tableUseDetail.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') +
  //       tableUseDetail.table_use_detail_sqlite_id.toString() +
  //       device_id.toString();
  //   return md5.convert(utf8.encode(bytes)).toString();
  // }

  // insertTableUseDetailKey(TableUseDetail tableUseDetail, String dateTime) async {
  //   TableUseDetail? _tableUseDetailData;
  //   tableUseDetailKey = await generateTableUseDetailKey(tableUseDetail);
  //   if (tableUseDetailKey != null) {
  //     TableUseDetail tableUseDetailObject = TableUseDetail(
  //         table_use_detail_key: tableUseDetailKey,
  //         sync_status: 0,
  //         updated_at: dateTime,
  //         table_use_detail_sqlite_id: tableUseDetail.table_use_detail_sqlite_id);
  //     int data = await PosDatabase.instance.updateTableUseDetailUniqueKey(tableUseDetailObject);
  //     if (data == 1) {
  //       TableUseDetail detailData = await PosDatabase.instance.readSpecificTableUseDetailByLocalId(tableUseDetailObject.table_use_detail_sqlite_id!);
  //       _tableUseDetailData = detailData;
  //     }
  //   }
  //   return _tableUseDetailData;
  // }

  // createTableUseDetail(CartModel cart) async {
  //   DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
  //   String dateTime = dateFormat.format(DateTime.now());
  //   List<String> _value = [];
  //   try {
  //     for (int i = 0; i < cart.selectedTable.length; i++) {
  //       //create table use detail
  //       TableUseDetail tableUseDetailData = await PosDatabase.instance.insertSqliteTableUseDetail(TableUseDetail(
  //           table_use_detail_id: 0,
  //           table_use_detail_key: '',
  //           table_use_sqlite_id: localTableUseId,
  //           table_use_key: tableUseKey,
  //           table_sqlite_id: cart.selectedTable[i].table_sqlite_id.toString(),
  //           table_id: cart.selectedTable[i].table_id.toString(),
  //           status: 0,
  //           sync_status: 0,
  //           created_at: dateTime,
  //           updated_at: '',
  //           soft_delete: ''));
  //       TableUseDetail updatedDetail = await insertTableUseDetailKey(tableUseDetailData, dateTime);
  //       _value.add(jsonEncode(updatedDetail));
  //     }
  //     table_use_detail_value = _value.toString();
  //     //sync to cloud
  //     //syncTableUseDetailToCloud(_value.toString());
  //   } catch (e) {
  //     print(e);
  //     Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "Create table detail error: ${e}");
  //   }
  // }

  // syncTableUseDetailToCloud(String value) async {
  //   //check is host reachable
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     Map response = await Domain().SyncTableUseDetailToCloud(value);
  //     if (response['status'] == '1') {
  //       List responseJson = response['data'];
  //       for (int i = 0; i < responseJson.length; i++) {
  //         int updateStatus = await PosDatabase.instance.updateTableUseDetailSyncStatusFromCloud(responseJson[i]['table_use_detail_key']);
  //       }
  //     }
  //   }
  // }

  // createOrderCache(CartModel cart, ConnectivityChangeNotifier connectivity, {isAddOrder}) async {
  //   DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
  //   String dateTime = dateFormat.format(DateTime.now());
  //
  //   final prefs = await SharedPreferences.getInstance();
  //   final int? branch_id = prefs.getInt('branch_id');
  //   final String? user = prefs.getString('user');
  //   List<TableUse> _tableUse = [];
  //   List<String> _value = [];
  //   Map userObject = json.decode(user!);
  //   String _tableUseId = '';
  //   int batch = 0;
  //   try {
  //     if(isAddOrder == true){
  //       batch = int.parse(cart.cartNotifierItem[0].first_cache_batch!);
  //     } else {
  //       batch = await batchChecking();
  //     }
  //     //check selected table is in use or not
  //     if (cart.selectedOption == 'Dine in') {
  //       for (int i = 0; i < cart.selectedTable.length; i++) {
  //         List<TableUseDetail> useDetail = await PosDatabase.instance.readSpecificTableUseDetail(cart.selectedTable[i].table_sqlite_id!);
  //         if (useDetail.length > 0) {
  //           _tableUseId = useDetail[0].table_use_sqlite_id!;
  //         } else {
  //           _tableUseId = this.localTableUseId;
  //         }
  //       }
  //       List<TableUse> tableUseData = await PosDatabase.instance.readSpecificTableUseId(int.parse(_tableUseId));
  //       _tableUse = tableUseData;
  //     }
  //     if (batch != 0) {
  //       //create order cache
  //       OrderCache data = await PosDatabase.instance.insertSqLiteOrderCache(OrderCache(
  //           order_cache_id: 0,
  //           order_cache_key: '',
  //           company_id: userObject['company_id'].toString(),
  //           branch_id: branch_id.toString(),
  //           order_detail_id: '',
  //           table_use_sqlite_id: cart.selectedOption == 'Dine in' ? _tableUseId : '',
  //           table_use_key: cart.selectedOption == 'Dine in' ? _tableUse[0].table_use_key : '',
  //           batch_id: batch.toString().padLeft(6, '0'),
  //           dining_id: this.diningOptionID.toString(),
  //           order_sqlite_id: '',
  //           order_key: '',
  //           order_by: userObject['name'].toString(),
  //           order_by_user_id: userObject['user_id'].toString(),
  //           cancel_by: '',
  //           cancel_by_user_id: '',
  //           customer_id: '0',
  //           total_amount: newOrderSubtotal.toStringAsFixed(2),
  //           qr_order: 0,
  //           qr_order_table_sqlite_id: '',
  //           qr_order_table_id: '',
  //           accepted: 0,
  //           sync_status: 0,
  //           created_at: dateTime,
  //           updated_at: '',
  //           soft_delete: ''));
  //       orderCacheId = data.order_cache_sqlite_id.toString();
  //       OrderCache updatedCache = await insertOrderCacheKey(data, dateTime);
  //       if (updatedCache.sync_status == 0) {
  //         //sync updated table use (with order cache key)
  //         await insertOrderCacheKeyIntoTableUse(cart, updatedCache, dateTime, connectivity);
  //       }
  //       _value.add(jsonEncode(updatedCache));
  //       order_cache_value = _value.toString();
  //       //sync to cloud
  //       //syncOrderCacheToCloud(updatedCache);
  //     }
  //   } catch (e) {
  //     print('error: ${e}');
  //     Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "Create order cache error: ${e}");
  //   }
  // }

  // syncOrderCacheToCloud(OrderCache updatedCache) async {
  //   List<String> _orderCacheValue = [];
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     _orderCacheValue.add(jsonEncode(updatedCache));
  //     Map response = await Domain().SyncOrderCacheToCloud(_orderCacheValue.toString());
  //     if (response['status'] == '1') {
  //       List responseJson = response['data'];
  //       int orderCacheData = await PosDatabase.instance.updateOrderCacheSyncStatusFromCloud(responseJson[0]['order_cache_key']);
  //     }
  //   }
  // }

  // generateOrderCacheKey(OrderCache orderCache) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final int? device_id = prefs.getInt('device_id');
  //   var bytes = orderCache.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') + orderCache.order_cache_sqlite_id.toString() + device_id.toString();
  //   return md5.convert(utf8.encode(bytes)).toString();
  // }
  //
  // insertOrderCacheKey(OrderCache orderCache, String dateTime) async {
  //   OrderCache? data;
  //   orderCacheKey = await generateOrderCacheKey(orderCache);
  //   if (orderCacheKey != null) {
  //     OrderCache orderCacheObject =
  //         OrderCache(order_cache_key: orderCacheKey, sync_status: 0, updated_at: dateTime, order_cache_sqlite_id: orderCache.order_cache_sqlite_id);
  //     int cacheUniqueKey = await PosDatabase.instance.updateOrderCacheUniqueKey(orderCacheObject);
  //     if (cacheUniqueKey == 1) {
  //       OrderCache orderCacheData = await PosDatabase.instance.readSpecificOrderCacheByLocalId(orderCacheObject.order_cache_sqlite_id!);
  //       if (orderCacheData.sync_status == 0) {
  //         data = orderCacheData;
  //       }
  //     }
  //   }
  //   return data;
  // }

  // insertOrderCacheKeyIntoTableUse(CartModel cart, OrderCache orderCache, String dateTime, ConnectivityChangeNotifier connectivity) async {
  //   List<String> _tableUseValue = [];
  //   if (cart.selectedOption == "Dine in") {
  //     List<TableUse> checkTableUse = await PosDatabase.instance.readSpecificTableUseId(int.parse(orderCache.table_use_sqlite_id!));
  //     TableUse tableUseObject = TableUse(
  //         order_cache_key: orderCacheKey,
  //         sync_status: checkTableUse[0].sync_status == 0 ? 0 : 2,
  //         updated_at: dateTime,
  //         table_use_sqlite_id: int.parse(orderCache.table_use_sqlite_id!));
  //     int tableUseCacheKey = await PosDatabase.instance.updateTableUseOrderCacheUniqueKey(tableUseObject);
  //     if (tableUseCacheKey == 1 && connectivity.isConnect) {
  //       List<TableUse> updatedTableUseRead = await PosDatabase.instance.readSpecificTableUseId(tableUseObject.table_use_sqlite_id!);
  //       _tableUseValue.add(jsonEncode(updatedTableUseRead[0]));
  //       table_use_value = _tableUseValue.toString();
  //       //sync to cloud
  //       //syncUpdatedTableUseIdToCloud(_tableUseValue.toString());
  //     }
  //   }
  // }

  // syncUpdatedTableUseIdToCloud(String tableUseValue) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     var response = await Domain().SyncTableUseToCloud(tableUseValue);
  //     if (response != null) {
  //       if (response['status'] == '1') {
  //         List responseJson = response['data'];
  //         int updatedTableUse = await PosDatabase.instance.updateTableUseSyncStatusFromCloud(responseJson[0]['table_use_key']);
  //       }
  //     } else {
  //       this.timeOutDetected = true;
  //     }
  //   }
  // }

  // createOrderDetail(CartModel cart, ConnectivityChangeNotifier connectivity) async {
  //   DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
  //   String dateTime = dateFormat.format(DateTime.now());
  //   List<String> _orderDetailValue = [];
  //   List<String> _orderModifierValue = [];
  //   List<String> _branchLinkProductValue = [];
  //   bool _hasModifier = false;
  //   //loop cart item & create order detail
  //   for (int j = 0; j < cart.cartNotifierItem.length; j++) {
  //     if (cart.cartNotifierItem[j].status == 0) {
  //       OrderDetail object = OrderDetail(
  //           order_detail_id: 0,
  //           order_detail_key: '',
  //           order_cache_sqlite_id: orderCacheId,
  //           order_cache_key: orderCacheKey,
  //           branch_link_product_sqlite_id: cart.cartNotifierItem[j].branch_link_product_sqlite_id,
  //           category_sqlite_id: cart.cartNotifierItem[j].category_sqlite_id,
  //           category_name: cart.cartNotifierItem[j].category_name,
  //           productName: cart.cartNotifierItem[j].product_name,
  //           has_variant: cart.cartNotifierItem[j].variant!.length == 0 ? '0' : '1',
  //           product_variant_name: getVariant2(cart.cartNotifierItem[j]),
  //           price: cart.cartNotifierItem[j].price,
  //           original_price: cart.cartNotifierItem[j].base_price,
  //           quantity: cart.cartNotifierItem[j].quantity.toString(),
  //           remark: cart.cartNotifierItem[j].remark,
  //           account: '',
  //           cancel_by: '',
  //           cancel_by_user_id: '',
  //           status: 0,
  //           sync_status: 0,
  //           created_at: dateTime,
  //           updated_at: '',
  //           soft_delete: '');
  //       OrderDetail orderDetailData = await PosDatabase.instance.insertSqliteOrderDetail(object);
  //       BranchLinkProduct branchLinkProductData = await updateProductStock(orderDetailData.branch_link_product_sqlite_id.toString(), int.parse(orderDetailData.quantity!), dateTime);
  //       _branchLinkProductValue.add(jsonEncode(branchLinkProductData.toJson()));
  //       branch_link_product_value = _branchLinkProductValue.toString();
  //       //insert order detail key
  //       OrderDetail updatedOrderDetailData = await insertOrderDetailKey(orderDetailData, dateTime);
  //       _orderDetailValue.add(jsonEncode(updatedOrderDetailData.syncJson()));
  //       order_detail_value = _orderDetailValue.toString();
  //       //insert order modifier detail
  //       if (cart.cartNotifierItem[j].modifier!.isNotEmpty) {
  //         for (int k = 0; k < cart.cartNotifierItem[j].modifier!.length; k++) {
  //           ModifierGroup group = cart.cartNotifierItem[j].modifier![k];
  //           for (int m = 0; m < group.modifierChild!.length; m++) {
  //             if (group.modifierChild![m].isChecked!) {
  //               _hasModifier = true;
  //               OrderModifierDetail orderModifierDetailData = await PosDatabase.instance.insertSqliteOrderModifierDetail(OrderModifierDetail(
  //                   order_modifier_detail_id: 0,
  //                   order_modifier_detail_key: '',
  //                   order_detail_sqlite_id: orderDetailData.order_detail_sqlite_id.toString(),
  //                   order_detail_id: '0',
  //                   order_detail_key: await orderDetailKey,
  //                   mod_item_id: group.modifierChild![m].mod_item_id.toString(),
  //                   mod_name: group.modifierChild![m].name,
  //                   mod_price: group.modifierChild![m].price,
  //                   mod_group_id: group.mod_group_id.toString(),
  //                   sync_status: 0,
  //                   created_at: dateTime,
  //                   updated_at: '',
  //                   soft_delete: ''));
  //               //insert unique key
  //               OrderModifierDetail updatedOrderModifierDetail = await insertOrderModifierDetailKey(orderModifierDetailData, dateTime);
  //               if (updatedOrderModifierDetail.order_modifier_detail_key != '' && connectivity.isConnect) {
  //                 _orderModifierValue.add(jsonEncode(updatedOrderModifierDetail));
  //                 order_modifier_detail_value = _orderModifierValue.toString();
  //               }
  //             }
  //           }
  //         }
  //       }
  //     }
  //   }
  //   if (this.timeOutDetected == false) {
  //     // syncOrderDetailToCloud(_orderDetailValue.toString());
  //     // syncBranchLinkProductStock(_branchLinkProductValue.toString());
  //     // if (_hasModifier) {
  //     //   syncOrderModifierToCloud(_orderModifierValue.toString());
  //     // }
  //   }
  // }

  // updateProductStock(String branch_link_product_sqlite_id, int quantity, String dateTime) async {
  //   int _totalStockQty = 0, updateStock = 0;
  //   BranchLinkProduct? object;
  //   List<BranchLinkProduct> checkData = await PosDatabase.instance.readSpecificBranchLinkProduct(branch_link_product_sqlite_id);
  //   if (checkData[0].stock_type == '2') {
  //     _totalStockQty = int.parse(checkData[0].stock_quantity!) - quantity;
  //     object = BranchLinkProduct(
  //         updated_at: dateTime,
  //         sync_status: 2,
  //         stock_quantity: _totalStockQty.toString(),
  //         branch_link_product_sqlite_id: int.parse(branch_link_product_sqlite_id));
  //     updateStock = await PosDatabase.instance.updateBranchLinkProductStock(object);
  //   } else {
  //     _totalStockQty = int.parse(checkData[0].daily_limit_amount!) - quantity;
  //     object = BranchLinkProduct(
  //         updated_at: dateTime,
  //         sync_status: 2,
  //         daily_limit_amount: _totalStockQty.toString(),
  //         branch_link_product_sqlite_id: int.parse(branch_link_product_sqlite_id));
  //     updateStock = await PosDatabase.instance.updateBranchLinkProductDailyLimitAmount(object);
  //   }
  //   //return updated value
  //   if (updateStock == 1) {
  //     List<BranchLinkProduct> updatedData = await PosDatabase.instance.readSpecificBranchLinkProduct(branch_link_product_sqlite_id);
  //     return updatedData[0];
  //   }
  // }

  // syncBranchLinkProductStock(String value) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     Map orderDetailResponse = await Domain().SyncBranchLinkProductToCloud(value);
  //     if (orderDetailResponse['status'] == '1') {
  //       List responseJson = orderDetailResponse['data'];
  //       for (int i = 0; i < responseJson.length; i++) {
  //         int syncUpdated = await PosDatabase.instance.updateBranchLinkProductSyncStatusFromCloud(responseJson[i]['branch_link_product_id']);
  //       }
  //     }
  //   }
  // }

  // syncOrderDetailToCloud(String orderDetailValue) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     Map orderDetailResponse = await Domain().SyncOrderDetailToCloud(orderDetailValue);
  //     if (orderDetailResponse['status'] == '1') {
  //       List responseJson = orderDetailResponse['data'];
  //       for (int i = 0; i < responseJson.length; i++) {
  //         int syncUpdated = await PosDatabase.instance.updateOrderDetailSyncStatusFromCloud(responseJson[i]['order_detail_key']);
  //       }
  //     }
  //   }
  // }
  //
  // syncOrderModifierToCloud(String orderModifierValue) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     Map orderModifierResponse = await Domain().SyncOrderModifierDetailToCloud(orderModifierValue);
  //     if (orderModifierResponse['status'] == '1') {
  //       List responseJson = orderModifierResponse['data'];
  //       for (int i = 0; i < responseJson.length; i++) {
  //         int syncUpdated = await PosDatabase.instance.updateOrderModifierDetailSyncStatusFromCloud(responseJson[i]['order_modifier_detail_key']);
  //       }
  //     }
  //   }
  // }

  // insertOrderModifierDetailKey(OrderModifierDetail orderModifierDetail, String dateTime) async {
  //   OrderModifierDetail? detailData;
  //   orderModifierDetailKey = await generateOrderModifierDetailKey(orderModifierDetail);
  //   if (orderModifierDetailKey != null) {
  //     OrderModifierDetail orderModifierDetailData = OrderModifierDetail(
  //         order_modifier_detail_key: orderModifierDetailKey,
  //         updated_at: dateTime,
  //         sync_status: orderModifierDetail.sync_status == 0 ? 0 : 2,
  //         order_modifier_detail_sqlite_id: orderModifierDetail.order_modifier_detail_sqlite_id);
  //     int updateUniqueKey = await PosDatabase.instance.updateOrderModifierDetailUniqueKey(orderModifierDetailData);
  //     if (updateUniqueKey == 1) {
  //       OrderModifierDetail data =
  //           await PosDatabase.instance.readSpecificOrderModifierDetailByLocalId(orderModifierDetailData.order_modifier_detail_sqlite_id!);
  //       detailData = data;
  //     }
  //   }
  //   return detailData;
  // }

  // insertOrderDetailKey(OrderDetail orderDetail, String dateTime) async {
  //   OrderDetail? detailData;
  //   try {
  //     orderDetailKey = await generateOrderDetailKey(orderDetail);
  //     if (orderDetailKey != null) {
  //       OrderDetail orderDetailObject = OrderDetail(
  //           order_detail_key: orderDetailKey, sync_status: 0, updated_at: dateTime, order_detail_sqlite_id: orderDetail.order_detail_sqlite_id);
  //       int updateUniqueKey = await PosDatabase.instance.updateOrderDetailUniqueKey(orderDetailObject);
  //       if (updateUniqueKey == 1) {
  //         OrderDetail data = await PosDatabase.instance.readSpecificOrderDetailByLocalId(orderDetailObject.order_detail_sqlite_id!);
  //         detailData = data;
  //       }
  //     }
  //     return detailData;
  //   } catch (e) {
  //     print('insert order detail key error: ${e}');
  //     return;
  //   }
  // }

  // generateOrderDetailKey(OrderDetail orderDetail) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final int? device_id = prefs.getInt('device_id');
  //   var bytes = orderDetail.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') + orderDetail.order_detail_sqlite_id.toString() + device_id.toString();
  //   return md5.convert(utf8.encode(bytes)).toString();
  // }

  // generateOrderModifierDetailKey(OrderModifierDetail orderModifierDetail) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final int? device_id = prefs.getInt('device_id');
  //   var bytes = orderModifierDetail.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') +
  //       orderModifierDetail.order_modifier_detail_sqlite_id.toString() +
  //       device_id.toString();
  //   return md5.convert(utf8.encode(bytes)).toString();
  // }

  // updatePosTable(CartModel cart, ConnectivityChangeNotifier connectivity) async {
  //   try {
  //     List<String> _value = [];
  //     DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
  //     String dateTime = dateFormat.format(DateTime.now());
  //
  //     for (int i = 0; i < cart.selectedTable.length; i++) {
  //       List<PosTable> result = await PosDatabase.instance.checkPosTableStatus(cart.selectedTable[i].table_sqlite_id!);
  //       List<TableUseDetail> tableUseDetail = await PosDatabase.instance.readSpecificTableUseDetail(cart.selectedTable[i].table_sqlite_id!);
  //       if (result[0].status == 0) {
  //         PosTable posTableData = PosTable(
  //             table_sqlite_id: cart.selectedTable[i].table_sqlite_id,
  //             table_use_detail_key: tableUseDetail[0].table_use_detail_key,
  //             table_use_key: tableUseKey,
  //             status: 1,
  //             updated_at: dateTime);
  //         int data = await PosDatabase.instance.updateCartPosTableStatus(posTableData);
  //         if (data == 1 && connectivity.isConnect) {
  //           List<PosTable> posTable = await PosDatabase.instance.readSpecificTable(posTableData.table_sqlite_id.toString());
  //           if (posTable[0].sync_status == 2) {
  //             _value.add(jsonEncode(posTable[0]));
  //           }
  //         }
  //       }
  //     }
  //     table_value = _value.toString();
  //     if (this.timeOutDetected == false) {
  //       //syncUpdatedTableToCloud(_value.toString());
  //     }
  //   } catch (e) {
  //     Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "update table error: ${e}");
  //     print("update table error: $e");
  //   }
  // }

  // syncUpdatedTableToCloud(String value) async {
  //   bool _hasInternetAccess = await Domain().isHostReachable();
  //   if (_hasInternetAccess) {
  //     Map data = await Domain().SyncUpdatedPosTableToCloud(value);
  //     if (data['status'] == '1') {
  //       List responseJson = data['data'];
  //       for (var i = 0; i < responseJson.length; i++) {
  //         int syncData = await PosDatabase.instance.updatePosTableSyncStatusFromCloud(responseJson[i]['table_id']);
  //       }
  //     }
  //   }
  // }

  // syncAllToCloud() async {
  //   if(mainSyncToCloud.count == 0){
  //     mainSyncToCloud.count = 1;
  //     final prefs = await SharedPreferences.getInstance();
  //     final int? device_id = prefs.getInt('device_id');
  //     final String? login_value = prefs.getString('login_value');
  //     bool _hasInternetAccess = await Domain().isHostReachable();
  //     if (_hasInternetAccess) {
  //       Map data = await Domain().syncLocalUpdateToCloud(
  //           device_id: device_id.toString(),
  //           value: login_value,
  //           table_use_value: this.table_use_value,
  //           table_use_detail_value: this.table_use_detail_value,
  //           order_cache_value: this.order_cache_value,
  //           order_detail_value: this.order_detail_value,
  //           branch_link_product_value: this.branch_link_product_value,
  //           order_modifier_value: this.order_modifier_detail_value,
  //           table_value: this.table_value);
  //       if (data['status'] == '1') {
  //         print('success');
  //         List responseJson = data['data'];
  //         for (int i = 0; i < responseJson.length; i++) {
  //           switch (responseJson[i]['table_name']) {
  //             case 'tb_table_use':
  //               {
  //                 await PosDatabase.instance.updateTableUseSyncStatusFromCloud(responseJson[i]['table_use_key']);
  //               }
  //               break;
  //             case 'tb_table_use_detail':
  //               {
  //                 await PosDatabase.instance.updateTableUseDetailSyncStatusFromCloud(responseJson[i]['table_use_detail_key']);
  //               }
  //               break;
  //             case 'tb_order_cache':
  //               {
  //                 await PosDatabase.instance.updateOrderCacheSyncStatusFromCloud(responseJson[i]['order_cache_key']);
  //               }
  //               break;
  //             case 'tb_order_detail':
  //               {
  //                 await PosDatabase.instance.updateOrderDetailSyncStatusFromCloud(responseJson[i]['order_detail_key']);
  //               }
  //               break;
  //             case 'tb_order_modifier_detail':
  //               {
  //                 await PosDatabase.instance.updateOrderModifierDetailSyncStatusFromCloud(responseJson[i]['order_modifier_detail_key']);
  //               }
  //               break;
  //             case 'tb_branch_link_product':
  //               {
  //                 await PosDatabase.instance.updateBranchLinkProductSyncStatusFromCloud(responseJson[i]['branch_link_product_id']);
  //               }
  //               break;
  //             case 'tb_table':
  //               {
  //                 await PosDatabase.instance.updatePosTableSyncStatusFromCloud(responseJson[i]['table_id']);
  //               }
  //               break;
  //             default:
  //               {
  //                 return;
  //               }
  //           }
  //         }
  //       }else if(data['status'] == '7'){
  //         this.isLogOut = true;
  //       }
  //     }
  //     mainSyncToCloud.count = 0;
  //   }
  // }
}
