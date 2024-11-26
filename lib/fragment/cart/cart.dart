import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:optimy_second_device/fragment/cart/reprint_kitchen_list_dialog.dart';
import 'package:optimy_second_device/notifier/fail_print_notifier.dart';
import 'package:optimy_second_device/object/app_setting.dart';
import 'package:optimy_second_device/object/tax_link_dining.dart';
import 'package:optimy_second_device/page/progress_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';


import '../../main.dart';
import '../../notifier/cart_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/branch_link_dining_option.dart';
import '../../object/branch_link_product.dart';
import '../../object/cart_payment.dart';
import '../../object/cart_product.dart';
import '../../object/modifier_group.dart';
import '../../object/order_promotion_detail.dart';
import '../../object/order_tax_detail.dart';
import '../../object/printer.dart';
import '../../object/promotion.dart';
import '../../object/table_use.dart';
import '../../object/tax.dart';
import '../../object/user.dart';
import '../../object/variant_group.dart';
import '../../page/loading_dialog.dart';
import '../../translation/AppLocalizations.dart';
import '../../utils/Utils.dart';
import '../toast/custom_toastification.dart';
import 'cart_dialog.dart';
import 'cart_remove_dialog.dart';

class CartPage extends StatefulWidget {
  final String currentPage;

  const CartPage({required this.currentPage, Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  StreamController cartController = StreamController();
  late Stream cartStream;
  late CartModel cart;
  final ScrollController _scrollController = ScrollController();
  late final SharedPreferences prefs;
  FlutterUsbPrinter flutterUsbPrinter = FlutterUsbPrinter();
  List<Printer> printerList = [];
  List<Promotion> autoApplyPromotionList = [];
  List<Promotion> promotionList = decodeAction.decodedBranchPromotionList!;
  List<BranchLinkDining> diningList = decodeAction.decodedBranchLinkDiningList!;
  List<TaxLinkDining> taxLinkDiningList = decodeAction.decodedTaxLinkDiningList, currentDiningTax = [];
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
  AppSetting appSetting = decodeAction.decodedAppSetting!;

  void _scrollDown() {
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  @override
  void initState() {
    // preload();
    cartStream = cartController.stream;
    cart = context.read<CartModel>();
    cart.initBranchLinkDiningOption();
    getPreferences();
    super.initState();
  }

  @override
  dispose() {
    // cart.initialLoad(notify: false);
    super.dispose();
  }

  getPreferences() async{
    prefs = await SharedPreferences.getInstance();
  }

  preload() async {
    await clientAction.connectRequestPort(action: '6', callback: decodeData);
  }

  decodeData(response) {
    try {
      var json = jsonDecode(response);
      Iterable value3 = json['data']['promotion_list'];
      promotionList = List<Promotion>.from(value3.map((json) => Promotion.fromJson(json)));
    } catch (e) {
      print("cart decode data error: $e");
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<CartModel>(builder: (context, CartModel cart, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          getSubTotal();
        });
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Scaffold(
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
                toolbarHeight: isLandscapeOrien() ? null : MediaQuery.of(context).size.height * 0.06,
                backgroundColor: Colors.white,
                actions: [
                  Visibility(
                    visible: widget.currentPage == 'menu' ? true : false,
                    child: Expanded(
                      child: Consumer<FailPrintModel>(builder: (context, FailPrintModel failPrint, child) {
                        return IconButton(
                          tooltip: 'kitchen print',
                          icon: Badge(
                            isLabelVisible: FailPrintModel.instance.failPrintOrderDetails.isEmpty ? false : true,
                            label: Text(FailPrintModel.instance.failPrintOrderDetails.length.toString()),
                            child: const Icon(
                              Icons.print,
                            ),
                          ),
                          color: color.backgroundColor,
                          onPressed: () {
                            openReprintKitchenDialog();
                          },
                        );
                      }),
                    ),
                  ),
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
                          openChooseTableDialog(cart);
                        },
                      ),
                    ),
                  ),
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
                ],
              ),
              body: StreamBuilder(
                  stream: cartStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: isLandscapeOrien() ? Border.all(color: Colors.grey.shade100, width: 3.0) : null,
                        ),
                        child: Column(
                          children: [
                            Container(
                              margin: MediaQuery.of(context).size.height > 500 ? EdgeInsets.only(bottom: 10) : EdgeInsets.zero,
                              child: GridView(
                                  physics: NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    childAspectRatio: isLandscapeOrien() ? 1.8 : MediaQuery.of(context).size.height * 0.004,
                                  ),
                                  children: List.generate(diningList.length, (index) {
                                    return InkWell(
                                      onTap: () {
                                        widget.currentPage == 'menu' ? cart.cartNotifierItem.isEmpty ? setState(() {
                                          cart.removeAllTable();
                                          cart.selectedOption = diningList[index].name!;
                                          cart.selectedOptionId = diningList[index].dining_id!;

                                        }) : cart.cartNotifierItem.isNotEmpty && cart.cartNotifierItem[0].status != 1 && cart.selectedOption != diningList[index].name! ?
                                        setState(() {
                                          showSecondDialog(context, color, cart, diningList[index]);
                                        }) : null
                                            : null;
                                      },
                                      child: Container(
                                          color: cart.selectedOption == diningList[index].name! ?
                                          color.buttonColor : color.backgroundColor,
                                          alignment: Alignment.center,
                                          child: Text(
                                            diningList[index].name!,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: cart.selectedOption == diningList[index].name! ? color.iconColor : Colors.white,
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
                                                      color: cart.cartNotifierItem[index].status == 1 ? font : cart.cartNotifierItem[index].refColor,
                                                      fontWeight: FontWeight.bold),
                                                ),
                                                TextSpan(
                                                    text: "RM${cart.cartNotifierItem[index].price!} (${getCartUnit(cart.cartNotifierItem[index])})",
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: cart.cartNotifierItem[index].status == 1 ? font : cart.cartNotifierItem[index].refColor,
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
                                                  visible: widget.currentPage == 'menu' ? true : false,
                                                  child: IconButton(
                                                      hoverColor: Colors.transparent,
                                                      icon: Icon(Icons.remove),
                                                      onPressed: () {
                                                        if (cart.cartNotifierItem[index].status == 0) {
                                                          if (cart.cartNotifierItem[index].quantity! > 1) {
                                                            if (cart.cartNotifierItem[index].unit != 'each' && cart.cartNotifierItem[index].unit != 'each_c') {
                                                              setState(() {
                                                                cart.cartNotifierItem[index].quantity = (cart.cartNotifierItem[index].quantity! - 1).ceilToDouble();
                                                              });
                                                            } else {
                                                              setState(() {
                                                                cart.cartNotifierItem[index].quantity = (cart.cartNotifierItem[index].quantity! - 1);
                                                              });
                                                            }
                                                          } else {
                                                            cart.removeItem(cart.cartNotifierItem[index]);
                                                          }
                                                        } else {
                                                          Fluttertoast.showToast(
                                                            backgroundColor: Colors.red,
                                                            msg: AppLocalizations.of(context)!.translate('order_already_placed'),
                                                          );
                                                        }
                                                      }),
                                                ),
                                                Text(
                                                  cart.cartNotifierItem[index].quantity.toString(),
                                                  style: TextStyle(color: cart.cartNotifierItem[index].refColor),
                                                ),
                                                widget.currentPage == 'menu' ?
                                                IconButton(
                                                    hoverColor: Colors.transparent,
                                                    icon: Icon(Icons.add),
                                                    onPressed: () async {
                                                      if (cart.cartNotifierItem[index].status == 0) {
                                                        if (checkProductStock(cart, cart.cartNotifierItem[index]) == true) {
                                                          setState(() {
                                                            cart.cartNotifierItem[index].quantity = cart.cartNotifierItem[index].quantity! + 1;
                                                          });
                                                        } else {
                                                          Fluttertoast.showToast(
                                                              backgroundColor: Colors.red, msg: AppLocalizations.of(context)!.translate('product_out_of_stock'));
                                                        }
                                                      } else {
                                                        Fluttertoast.showToast(
                                                            backgroundColor: Colors.red, msg: AppLocalizations.of(context)!.translate('order_already_placed'));
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
                            SizedBox(height: MediaQuery.of(context).size.height > 500 ? isLandscapeOrien() ? 20 : 10 : 5),
                            Divider(
                              color: Colors.grey,
                              height: 1,
                              thickness: 1,
                              indent: 20,
                              endIndent: 20,
                            ),
                            SizedBox(height: MediaQuery.of(context).size.height > 500 ? isLandscapeOrien() ? 10 : 0 : 5),
                            SizedBox(
                              height: MediaQuery.of(context).size.height > 500 ?
                              widget.currentPage == 'menu' || widget.currentPage == 'table' ? isLandscapeOrien() ? 130 : 100 :
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
                                            title: Text('${currentDiningTax[index].tax_name}(${currentDiningTax[index].tax_rate}%)',
                                                style: TextStyle(fontSize: 14)),
                                            trailing: Text('${currentDiningTax[index].tax_amount?.toStringAsFixed(2)}',
                                                style: TextStyle(fontSize: 14)),
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
                                            title: Text('${orderTaxList[index].tax_name}(${orderTaxList[index].rate}%)',
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
                            SizedBox(height: isLandscapeOrien() ? 10 : 0),
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
                                            if (cart.selectedOption == 'Dine in' && appSetting.table_order != 0) {
                                              if (cart.selectedTable.isNotEmpty) {
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
                                                      msg: AppLocalizations.of(context)!.translate('make_sure_cart_is_not_empty_and_table_is_selected'));
                                                }
                                              }
                                            } else {
                                              // not dine in call
                                              print('not dine in');
                                              cart.removeAllTable();
                                              if (cart.cartNotifierItem.isNotEmpty) {
                                                await callPlaceOrder(cart, '8');
                                              } else {
                                                Fluttertoast.showToast(
                                                    backgroundColor: Colors.red,
                                                    msg: "${AppLocalizations.of(context)?.translate('empty_cart')}");
                                              }
                                            }
                                          }
                                        }
                                      },
                                      child: MediaQuery.of(context).size.height > 500 && MediaQuery.of(context).size.width > 900 ?
                                      Text('${AppLocalizations.of(context)!.translate('place_order')}\n (RM $finalAmount)') :
                                      Text(AppLocalizations.of(context)!.translate('place_order')),
                                    ),
                                  ),
                                  //some spacing for second button
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
          ),
        );
      });
    });
  }

  String getCartUnit(cartProductItem productItem){
    if(productItem.unit != 'each' && productItem.unit! != 'each_c'){
      return productItem.per_quantity_unit! + productItem.unit!;
    } else {
      return 'each';
    }
  }

  checkProductStock(CartModel cart, cartProductItem cartItem) {
    bool hasStock = true;
    List<BranchLinkProduct> data = decodeAction.decodedBranchLinkProductList!;
    if (data.isNotEmpty) {
      BranchLinkProduct product = data.firstWhere((e) => e.branch_link_product_sqlite_id.toString() == cartItem.branch_link_product_sqlite_id);
      switch (product.stock_type) {
        case '1':
          {
            if (int.parse(product.daily_limit!) > 0 && simpleIntInput <= int.parse(product.daily_limit!)) {
              num stockLeft = int.parse(product.daily_limit!) - checkCartProductQuantity(cart, product);
              if (stockLeft > 0) {
                hasStock = true;
              } else {
                hasStock = false;
              }
            } else {
              hasStock = false;
            }
          }
          break;
        case '2':
          {
            num stockQuantity = int.parse(product.stock_quantity!);
            if (stockQuantity > 0 && simpleIntInput <= stockQuantity) {
              num stockLeft = stockQuantity - checkCartProductQuantity(cart, product);
              if (stockLeft > 0) {
                hasStock = true;
              } else {
                hasStock = false;
              }
            } else {
              hasStock = false;
            }
          }
          break;
        default:
          {
            hasStock = true;
          }
      }
    }

    return hasStock;
  }

  num checkCartProductQuantity(CartModel cart, BranchLinkProduct branchLinkProduct) {
    ///get all same item in cart
    List<cartProductItem> sameProductList =
    cart.cartNotifierItem.where((item) => item.branch_link_product_sqlite_id == branchLinkProduct.branch_link_product_sqlite_id.toString() && item.status == 0).toList();
    if (sameProductList.isNotEmpty) {
      /// sum all quantity
      num totalQuantity = sameProductList.fold(0, (sum, product) => sum + product.quantity!);
      return totalQuantity;
    } else {
      return 0;
    }
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
    if(cart.cartNotifierItem.isEmpty){
      isButtonDisabled = true;
    } else {
      isButtonDisabled = false;
    }
    for (int i = 0; i < cart.cartNotifierItem.length; i++) {
      if (cart.cartNotifierItem[i].status == 0) {
        hasNewItem = true;
      } else {
        hasNewItem = false;
      }
    }
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
    if (object.checkedModifierItem != null && object.checkedModifierItem!.isNotEmpty) {
      modifier = object.checkedModifierItem!.map((e) => '${e.name}\n').toList();
      result = modifier.toString().replaceAll('[', '').replaceAll(']', '').replaceAll(',', '+').replaceFirst('', '+ ');
    }
    return result;
  }

/*
  Get Cart product variant
*/
  getVariant(cartProductItem object) {
    String result = '';
    if (object.productVariantName != null && object.productVariantName != '') {
      result = "${object.productVariantName!.replaceAll('|', '\n+').replaceFirst('', '+ ')}\n";
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
    // getManualApplyPromotion(cart);
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
  getSubTotal() {
    try {
      // if(!isFirstLoad){
      //   isFirstLoad = true;
      //   await preload();
      // }
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
    getTaxAmount();
    getRounding();
    getAllTotal();
    checkCartItem(cart);
    if (cart.cartScrollDown == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollDown();
      });
      cart.setCartScrollDown = 1;
    }
    cartController.sink.add('refresh');
    // if (!controller.isClosed) {
    //   controller.sink.add('refresh');
    // }
  }

  void getTaxAmount() {
    try {
      discountPrice = total - promoAmount;
      currentDiningTax = taxLinkDiningList.where((tax) => tax.dining_id == cart.selectedOptionId).toList();
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
    totalAmount = 0.0;
    discountPrice = total - promoAmount;
    totalAmount = discountPrice + sumAllTaxAmount();
    rounding = Utils.roundToNearestFiveSen(double.parse(totalAmount.toStringAsFixed(2))) - double.parse(totalAmount.toStringAsFixed(2));

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

  openReprintKitchenDialog() {
    return showDialog(
        context: context,
        builder: (BuildContext context){
          return ReprintKitchenListDialog();
        }
    );
  }

  // openReprintKitchenDialog() async {
  //   return showGeneralDialog(
  //       barrierColor: Colors.black.withOpacity(0.5),
  //       transitionBuilder: (context, a1, a2, widget) {
  //         final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
  //         return Transform(
  //           transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
  //           child: Opacity(
  //             opacity: a1.value,
  //             child: ReprintKitchenListDialog(),
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
              child: CartDialog(),
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

  ///place order
  callPlaceOrder(CartModel cart, String action) async {
    CartModel newCart = cart;
    if(action == '9'){
      newCart = CartModel.addOrderCopy(cart);
    }
    final String? pos_user = prefs.getString('pos_pin_user');
    Map<String, dynamic> userMap = json.decode(pos_user!);
    User userData = User.fromJson(userMap);
    Map<String, dynamic> map = {
      'order_by_user_id': userData.user_id.toString(),
      'order_by': userData.name,
      'cart':newCart
    };
    await clientAction.connectRequestPort(action: action, param: jsonEncode(map), callback: responseStatusCheck);
  }

  void responseStatusCheck(response){
    if(response != null){
      var json = jsonDecode(response);
      switch(json['status']){
        case '1': {
          //place order success
          CustomSuccessToast(title: AppLocalizations.of(context)!.translate('place_order_success')).showToast();
          updateBranchLinkProductData(json['data']['tb_branch_link_product']);
          Navigator.of(context).pop();
          cart.initialLoad();
        }break;
        case '2': {
          //product out of stock
          updateBranchLinkProductData(json['data']['tb_branch_link_product']);
          Navigator.of(context).pop();
          showOutOfStockDialog(json['data']['cartItem']);
        }break;
        case '3': {
          updateBranchLinkProductData(json['data']['tb_branch_link_product']);
          Navigator.of(context).pop();
          CustomFailedToast(title: AppLocalizations.of(context)!.translate(json['error']), duration: 6).showToast();
        }break;
        case '4': {
          Navigator.of(context).pop();
          CustomFailedToast(
              title: AppLocalizations.of(context)!.translate('place_order_failed'),
              description: json['exception'],
              duration: 6,
          ).showToast();
          cart.initialLoad();
        }break;
        default: {
          clientAction.openReconnectDialog(action: json['action'], param: json['param'], callback: responseStatusCheck);
        }
      }
    }
  }

  Future<void> showOutOfStockDialog(response) async {
    List<cartProductItem> item = List<cartProductItem>.from(response.map((json) => cartProductItem.fromJson(json)));
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context){
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.translate("product_out_of_stock")),
            content: Container(
              constraints: BoxConstraints(maxHeight: 400),
              width: 350,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${AppLocalizations.of(context)!.translate("total_item")}: ${item.where((e) => e.status == 0).toList().length}'),
                    SizedBox(height: 10),
                    ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: item.where((e) => e.status == 0).toList().length,
                        itemBuilder: (context, index) {
                          return Card(
                            elevation: 5,
                            child: ListTile(
                              isThreeLine: true,
                              title: Text(item[index].product_name!, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                              subtitle: Text(getCartVariant(item[index]) + getCartModifier(item[index])),
                              trailing: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text("x${item[index].quantity}"),
                                  Text("${AppLocalizations.of(context)!.translate("available_stock")}: ${getStockLeft(item[index])}", style: TextStyle(color: Colors.red),)
                                ],
                              ),
                            ),
                          );
                        },
                    )
                        // separatorBuilder: (BuildContext context, int index) => const Divider()),
                  ],
                ),
              ),
            ),
            actions: [
              ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: (){
                    Navigator.of(context).pop();
                  },
                  child: Text(AppLocalizations.of(context)!.translate("close")))
            ],
          );
        });
  }

  String getCartVariant(cartProductItem object){
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

  String getCartModifier(cartProductItem cartItem){
    List<String?> modifier = [];
    String result = '';
    for(int i = 0; i < cartItem.modifier!.length; i++){
      ModifierGroup group =  cartItem.modifier![i];
      for(int j = 0; j < group.modifierChild!.length; j++){
        if (group.modifierChild![j].isChecked!) {
          modifier.add('${group.modifierChild![j].name!}\n');
          result = modifier.toString().replaceAll('[', '').replaceAll(']', '').replaceAll(',', '+').replaceFirst('', '+ ');
        }
      }
    }
    return result;
  }


  String getStockLeft(cartProductItem cartItem){
    String stockLeft = '';
    BranchLinkProduct product = decodeAction.decodedBranchLinkProductList!.firstWhere((e) => e.branch_link_product_sqlite_id.toString() == cartItem.branch_link_product_sqlite_id);
    switch (product.stock_type) {
      case '1':
        return stockLeft = product.daily_limit!;
      case '2':
        return stockLeft = product.stock_quantity!;
    }
    return stockLeft;
  }


  ///add order
  // callAddOrderCache(CartModel cart) async {
  //   Map<String, dynamic>? objectData = {
  //     'cartNotifierItem': cart.cartNotifierItem,
  //     'selectedTable': cart.selectedTable,
  //   };
  //   await clientAction.connectRequestPort(action: '9', param: jsonEncode(objectData), callback: responseStatusCheck);
  //   // await createOrderCache(cart, connectivity, isAddOrder: true);
  //   // await createOrderDetail(cart, connectivity);
  //   // await syncAllToCloud();
  //   // if(this.isLogOut == true){
  //   //   openLogOutDialog();
  //   //   return;
  //   // }
  //   // await printReceipt.printCheckList(printerList, int.parse(this.orderCacheId), context);
  //   // await printReceipt.printKitchenList(printerList, context, cart, int.parse(this.orderCacheId));
  // }

  // requestBranchLinkProductData(String action) async{
  //   await clientAction.connectRequestPort(action: action, callback: updateBranchLinkProductData);
  // }

  updateBranchLinkProductData(response){
    Iterable value4 = response;
    List<BranchLinkProduct> product = List<BranchLinkProduct>.from(value4.map((json) => BranchLinkProduct.fromJson(json)));
    for(int i = 0; i < product.length; i++){
      decodeAction.decodedBranchLinkProductList?.removeWhere((e) => e.branch_link_product_sqlite_id == product[i].branch_link_product_sqlite_id);
      decodeAction.decodedBranchLinkProductList?.add(product[i]);
    }
    //decodeAction.decodedBranchLinkProductList = List<BranchLinkProduct>.from(value4.map((json) => BranchLinkProduct.fromJson(json)));
  }

  updateAllBranchLinkProductData(response){
    var json = jsonDecode(response);
    switch(json['status']){
      case '1': {
        Iterable value4 = json['data']['tb_branch_link_product'];
        List<BranchLinkProduct> product = List<BranchLinkProduct>.from(value4.map((json) => BranchLinkProduct.fromJson(json)));
        decodeAction.decodedBranchLinkProductList = product;
        Navigator.of(context).pop();
        cart.initialLoad();
      } break;
      default: {
        clientAction.openReconnectDialog(action: '15', callback: updateAllBranchLinkProductData);
      }
    }
  }

  bool isLandscapeOrien() {
    try {
      if(MediaQuery.of(context).orientation == Orientation.landscape) {
        return true;
      } else {
        return false;
      }
    } catch(e) {
      print("isLandscapeOrien error: $e");
      return false;
    }
  }
}
