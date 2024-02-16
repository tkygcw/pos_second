import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:optimy_second_device/main.dart';
import 'package:provider/provider.dart';
import 'package:quantity_input/quantity_input.dart';

import '../../notifier/cart_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/modifier_group.dart';
import '../../object/modifier_item.dart';
import '../../translation/AppLocalizations.dart';
import '../fragment/cart/cart_dialog.dart';
import '../object/branch_link_modifier.dart';
import '../object/branch_link_product.dart';
import '../object/cart_product.dart';
import '../object/categories.dart';
import '../object/product.dart';
import '../object/product_variant.dart';
import '../object/variant_group.dart';
import '../page/progress_bar.dart';
import '../utils/Utils.dart';

class ProductOrderDialog extends StatefulWidget {
  final Product? productDetail;
  final CartModel cartModel;

  const ProductOrderDialog({Key? key, this.productDetail, required this.cartModel}) : super(key: key);

  @override
  _ProductOrderDialogState createState() => _ProductOrderDialogState();
}

class _ProductOrderDialogState extends State<ProductOrderDialog> {
  StreamController controller = StreamController();
  StreamController actionController = StreamController();
  late Stream contentStream;
  late Stream actionStream;
  late StreamSubscription actionSubscription;
  late CartModel cart;
  List<BranchLinkProduct> branchLinkProductList = decodeAction.decodedBranchLinkProductList!;
  List<ProductVariant> productVariantList = decodeAction.decodedProductVariantList!;
  List<BranchLinkModifier> branchLinkModifierList = decodeAction.decodedBranchLinkModifierList!;
  Categories? categories;
  late BranchLinkProduct branchLinkProduct;
  String basePrice = '';
  String finalPrice = '';
  String dialogPrice = '', dialogStock = '';
  num simpleIntInput = 1, pressed = 0;
  int checkedModifierLength = 0;
  String modifierItemPrice = '';
  List<VariantGroup> variantGroup = [];
  List<ModifierGroup> modifierGroup = [];
  List<ModifierItem> checkedModItem = [];
  final remarkController = TextEditingController();
  TextEditingController quantityController = TextEditingController();

  bool checkboxValueA = false;
  bool isLoaded = false;
  bool hasPromo = false;
  bool isButtonDisabled = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    contentStream = controller.stream;
    actionStream = actionController.stream;
    productChecking();
    listenAction();
    simpleIntInput = widget.productDetail!.unit != 'each' ? 0 : 1;
    quantityController = TextEditingController(text: widget.productDetail!.unit != 'each' ? '' : '$simpleIntInput');
    //getProductPrice(widget.productDetail?.product_id);
  }

  listenAction(){
    actionSubscription = actionStream.listen((action) async {
      switch(action){
        case 'add-on':{
          getProductPrice(widget.productDetail!.product_sqlite_id.toString());
          getProductDialogStock(widget.productDetail!);
          controller.sink.add("refresh");
        }break;
        case 'variant':{
          getBranchLinkProductId(widget.productDetail!);
          getProductPrice(widget.productDetail!.product_sqlite_id.toString());
          getProductDialogStock(widget.productDetail!);
          controller.sink.add("refresh");
        }break;
      }
    });
  }

  Widget variantGroupLayout(VariantGroup variantGroup) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(variantGroup.name!, style: TextStyle(fontWeight: FontWeight.bold)),
        for (int i = 0; i < variantGroup.child!.length; i++)
          RadioListTile<int?>(
            value: variantGroup.child![i].variant_item_sqlite_id,
            groupValue: variantGroup.variant_item_sqlite_id,
            onChanged: (ind) {
              variantGroup.variant_item_sqlite_id = ind;
              actionController.sink.add("variant");
            },
            title: Text(variantGroup.child![i].name!),
            controlAffinity: ListTileControlAffinity.trailing,
          )
      ],
    );
  }

  Widget modifierGroupLayout(ModifierGroup modifierGroup, CartModel cart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(modifierGroup.name!, style: TextStyle(fontWeight: FontWeight.bold)),
        for (int i = 0; i < modifierGroup.modifierChild!.length; i++)
          CheckboxListTile(
            title: Row(
              children: [
                Text(modifierGroup.modifierChild![i].name!),
                Text(
                  ' (+RM ${Utils.convertTo2Dec(modifierGroup.modifierChild![i].price)})',
                  style: TextStyle(fontSize: 12),
                )
              ],
            ),
            value: modifierGroup.modifierChild![i].isChecked,
            onChanged: modifierGroup.modifierChild![i].mod_status! == '2' ? null : (isChecked) {
              modifierGroup.modifierChild![i].isChecked = isChecked!;
              addCheckedModItem(modifierGroup.modifierChild![i]);
              actionController.sink.add("add-on");
            },
            controlAffinity: ListTileControlAffinity.trailing,
          )
      ],
    );
  }

  addCheckedModItem(ModifierItem modifierItem){
    if(modifierItem.isChecked == true){
      checkedModItem.add(modifierItem);
    } else {
      checkedModItem.remove(modifierItem);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<CartModel>(builder: (context, CartModel cart, child) {
        this.cart = cart;
        return StreamBuilder(
          stream: contentStream,
          builder: (context, snapshot) {
            if(snapshot.hasData){
              return LayoutBuilder(builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                  return AlertDialog(
                    title: Row(
                      children: [
                        Container(
                          constraints: BoxConstraints(maxWidth: 300),
                          child: Text(widget.productDetail!.name!,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              )),
                        ),
                        Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            widget.productDetail!.unit != 'each' ?
                            Text("RM ${Utils.convertTo2Dec(dialogPrice)} / ${widget.productDetail!.per_quantity_unit!}${widget.productDetail!.unit!}",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                )) :
                            Text("RM ${Utils.convertTo2Dec(dialogPrice)} / ${widget.productDetail!.unit!}",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                )),
                            Visibility(
                              visible: dialogStock != '' ? true : false,
                              child: Text("In stock: ${dialogStock}${widget.productDetail!.unit != 'each'? widget.productDetail!.unit : ''}",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: dialogStock == '0' ? Colors.red : Colors.black
                                  )),
                            )
                          ],
                        )
                      ],
                    ),
                    content: Container(
                      // constraints: BoxConstraints(
                      //   maxHeight: MediaQuery.of(context).size.height > 500 ? 500.0 : MediaQuery.of(context).size.height / 2.5,
                      // ),
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width / 3,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (int i = 0; i < variantGroup.length; i++)
                              variantGroupLayout(variantGroup[i]),
                            for (int j = 0; j < modifierGroup.length; j++)
                              Visibility(
                                visible: modifierGroup[j].modifierChild!.isNotEmpty &&
                                    modifierGroup[j].dining_id == "" ||
                                    modifierGroup[j].dining_id == cart.selectedOptionId
                                    ? true
                                    : false,
                                child: modifierGroupLayout(modifierGroup[j], cart),
                              ),
                            Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Quantity",
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                // quantity input
                                Container(
                                  width: 400,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // quantity input remove button
                                      Container(
                                        decoration: BoxDecoration(
                                          color: color.backgroundColor,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: IconButton(
                                          icon: Icon(Icons.remove, color: Colors.white), // Set the icon color to white.
                                          onPressed: () {
                                            if(simpleIntInput >= 1){
                                              setState(() {
                                                simpleIntInput -= 1;
                                                quantityController.text = widget.productDetail!.unit != 'each' ? simpleIntInput.toStringAsFixed(2) : simpleIntInput.toString();
                                                simpleIntInput = widget.productDetail!.unit != 'each' ? double.parse(quantityController.text.replaceAll(',', '')) : int.parse(quantityController.text.replaceAll(',', ''));
                                              });
                                            } else{
                                              setState(() {
                                                simpleIntInput = 0;
                                                quantityController.text =  widget.productDetail!.unit != 'each' ? simpleIntInput.toStringAsFixed(2) : simpleIntInput.toString();
                                                simpleIntInput = widget.productDetail!.unit != 'each' ? double.parse(quantityController.text.replaceAll(',', '')) : int.parse(quantityController.text.replaceAll(',', ''));
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      // quantity input text field
                                      Container(
                                        width: 273,
                                        child: TextField(
                                          autofocus: widget.productDetail!.unit != 'each' ? true : false,
                                          controller: quantityController,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: widget.productDetail!.unit != 'each' ? <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))]
                                              : <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                                          textAlign: TextAlign.center,
                                          decoration: InputDecoration(
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: color.backgroundColor),
                                            ),
                                          ),
                                          onChanged: (value) {
                                            if(value != ''){
                                              setState(() => simpleIntInput = widget.productDetail!.unit != 'each' ? double.parse(value.replaceAll(',', '')): int.parse(value.replaceAll(',', '')));
                                            } else {
                                              simpleIntInput = 0;
                                            }
                                          },
                                          onSubmitted: _onSubmitted,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      // quantity input add button
                                      Container(
                                        decoration: BoxDecoration(
                                          color: color.backgroundColor,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: IconButton(
                                          icon: Icon(Icons.add, color: Colors.white),
                                          onPressed: () {
                                            // stock disable or in stock
                                            if(dialogStock == '' || simpleIntInput+1 < int.parse(dialogStock)) {
                                              setState(() {
                                                simpleIntInput += 1;
                                                quantityController.text = simpleIntInput.toString();
                                                simpleIntInput =  int.parse(quantityController.text.replaceAll(',', ''));
                                              });
                                            } else{
                                              setState(() {
                                                simpleIntInput = int.parse(dialogStock);
                                                quantityController.text = simpleIntInput.toString();
                                                simpleIntInput = int.parse(quantityController.text.replaceAll(',', ''));
                                              });
                                              if(dialogStock == '0'){
                                                print('stock_quantity: '+dialogStock);
                                                Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('product_variant_sold_out'));
                                              }
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                            Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(8, 30, 8, 10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Remark",
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                TextField(
                                  controller: remarkController,
                                  decoration: InputDecoration(
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: color.backgroundColor),
                                    ),
                                  ),
                                  keyboardType: TextInputType.multiline,
                                  maxLines: null,
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    actions: <Widget>[
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 4,
                        height: MediaQuery.of(context).size.height / 12,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color.backgroundColor,
                          ),
                          child: Text(
                            'Close',
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: isButtonDisabled
                              ? null
                              : () {
                            Navigator.of(context).pop();

                            // Disable the button after it has been pressed
                            setState(() {
                              isButtonDisabled = true;
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 4,
                        height: MediaQuery.of(context).size.height / 12,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color.buttonColor,
                          ),
                          child: Text(
                            'ADD',
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: isButtonDisabled
                              ? null
                              : ()  {
                            switch(checkProductStockStatus(widget.productDetail!, cart)){
                              case 1 : {
                                Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000),
                                    msg: "Product variant sold out!");
                              }break;
                              case 2 : {
                                Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000),
                                    msg: "Quantity input exceed stock amount");
                              }break;
                              default: {
                                if (cart.selectedOption == 'Dine in') {
                                  if (simpleIntInput > 0) {
                                    if (cart.selectedTable.isNotEmpty) {
                                      // Disable the button after it has been pressed
                                      setState(() {
                                        isButtonDisabled = true;
                                      });
                                      addToCart(cart);
                                      Navigator.of(context).pop();
                                    } else {
                                      openChooseTableDialog(cart);
                                    }
                                  } else {
                                    Fluttertoast.showToast(
                                        backgroundColor: Color(0xFFFF0000), msg: "Invalid qty input");
                                  }
                                } else {
                                  // Disable the button after it has been pressed
                                  setState(() {
                                    isButtonDisabled = true;
                                  });
                                  addToCart(cart);
                                  Navigator.of(context).pop();
                                }
                              }
                            }
                            // if (checkProductStock(widget.productDetail!, cart) == true) {
                            //   if (cart.selectedOption == 'Dine in') {
                            //     if (simpleIntInput > 0) {
                            //       if (cart.selectedTable.isNotEmpty) {
                            //         // Disable the button after it has been pressed
                            //         setState(() {
                            //           isButtonDisabled = true;
                            //         });
                            //         addToCart(cart);
                            //         Navigator.of(context).pop();
                            //       } else {
                            //         openChooseTableDialog(cart);
                            //       }
                            //     } else {
                            //       Fluttertoast.showToast(
                            //           backgroundColor: Color(0xFFFF0000), msg: "Invalid qty input");
                            //     }
                            //   } else {
                            //     // Disable the button after it has been pressed
                            //     setState(() {
                            //       isButtonDisabled = true;
                            //     });
                            //     addToCart(cart);
                            //     Navigator.of(context).pop();
                            //   }
                            // } else {
                            //   Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000),
                            //       msg: "Product variant sold out!");
                            // }
                          },
                        ),
                      ),
                    ],
                  );
                } else {
                  ///mobile layout
                  return Center(
                    child: SingleChildScrollView(
                      child: AlertDialog(
                        title: Row(
                          children: [
                            Container(
                              constraints: BoxConstraints(maxWidth: MediaQuery
                                  .of(context)
                                  .size
                                  .width / 2),
                              child: Text(widget.productDetail!.name!,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  )),
                            ),
                            Spacer(),
                            // Text("RM ${Utils.convertTo2Dec(widget.productDetail!.price!)}",
                            //     style: TextStyle(
                            //       fontSize: 16,
                            //       fontWeight: FontWeight.bold,
                            //     )),
                          ],
                        ),
                        content: this.isLoaded
                            ? Container(
                          height: MediaQuery
                              .of(context)
                              .size
                              .height, // Change as per your requirement
                          width: MediaQuery
                              .of(context)
                              .size
                              .width / 1.5,
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (int i = 0; i < variantGroup.length; i++) variantGroupLayout(
                                    variantGroup[i]),
                                for (int j = 0; j < modifierGroup.length; j++)
                                  Visibility(
                                    visible: modifierGroup[j].modifierChild!.isNotEmpty &&
                                        modifierGroup[j].dining_id == "" ||
                                        modifierGroup[j].dining_id == cart.selectedOptionId
                                        ? true
                                        : false,
                                    child: modifierGroupLayout(modifierGroup[j], cart),
                                  ),
                                Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Quantity",
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    QuantityInput(
                                        inputWidth: 273,
                                        acceptsNegatives: false,
                                        acceptsZero: false,
                                        minValue: 1,
                                        decoration: InputDecoration(
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(color: color.backgroundColor),
                                          ),
                                        ),
                                        buttonColor: color.backgroundColor,
                                        value: simpleIntInput,
                                        onChanged: (value) =>
                                            setState(() =>
                                            simpleIntInput = int.parse(value.replaceAll(',', ''))))
                                  ],
                                ),
                                Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(8, 30, 8, 10),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Remark",
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextField(
                                      controller: remarkController,
                                      decoration: InputDecoration(
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: color.backgroundColor),
                                        ),
                                      ),
                                      keyboardType: TextInputType.multiline,
                                      maxLines: null,
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                        )
                            : CustomProgressBar(),
                        actions: <Widget>[
                          SizedBox(
                            width: MediaQuery
                                .of(context)
                                .size
                                .width / 2.5,
                            height: MediaQuery
                                .of(context)
                                .size
                                .height / 10,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: color.backgroundColor),
                              child: Text('${AppLocalizations.of(context)?.translate('close')}'),
                              onPressed: isButtonDisabled
                                  ? null
                                  : () {
                                // Disable the button after it has been pressed
                                setState(() {
                                  isButtonDisabled = true;
                                });
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width / 2.5,
                            height: MediaQuery.of(context).size.height / 10,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: color.buttonColor,
                              ),
                              child: Text('${AppLocalizations.of(context)?.translate('add')}'),
                              onPressed: isButtonDisabled
                                  ? null
                                  : () async {
                                switch(checkProductStockStatus(widget.productDetail!, cart)){
                                  case 1 : {
                                    Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000),
                                        msg: "Product variant sold out!");
                                  }break;
                                  case 2 : {
                                    Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000),
                                        msg: "Quantity input exceed stock amount");
                                  }break;
                                  default: {
                                    if (cart.selectedOption == 'Dine in') {
                                      if (simpleIntInput > 0) {
                                        if (cart.selectedTable.isNotEmpty) {
                                          // Disable the button after it has been pressed
                                          setState(() {
                                            isButtonDisabled = true;
                                          });
                                          addToCart(cart);
                                          Navigator.of(context).pop();
                                        } else {
                                          openChooseTableDialog(cart);
                                        }
                                      } else {
                                        Fluttertoast.showToast(
                                            backgroundColor: Color(0xFFFF0000), msg: "Invalid qty input");
                                      }
                                    } else {
                                      // Disable the button after it has been pressed
                                      setState(() {
                                        isButtonDisabled = true;
                                      });
                                      addToCart(cart);
                                      Navigator.of(context).pop();
                                    }
                                  }
                                }
                                //await getBranchLinkProductItem(widget.productDetail!);
                                // if (checkProductStock(widget.productDetail!, cart) == true) {
                                //   if (cart.selectedOption == 'Dine in') {
                                //     if (simpleIntInput > 0) {
                                //       if (cart.selectedTable.isNotEmpty) {
                                //         // Disable the button after it has been pressed
                                //         setState(() {
                                //           isButtonDisabled = true;
                                //         });
                                //         //await addToCart(cart);
                                //         Navigator.of(context).pop();
                                //       } else {
                                //         openChooseTableDialog(cart);
                                //       }
                                //     } else {
                                //       Fluttertoast.showToast(
                                //           backgroundColor: Color(0xFFFF0000), msg: "Invalid qty input");
                                //     }
                                //   } else {
                                //     // Disable the button after it has been pressed
                                //     setState(() {
                                //       isButtonDisabled = true;
                                //     });
                                //     //await addToCart(cart);
                                //     Navigator.of(context).pop();
                                //   }
                                // } else {
                                //   Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000),
                                //       msg: "Product variant sold out!");
                                // }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              });
            } else {
              return CustomProgressBar();
            }
          }
        );
      });
    });
  }

  productChecking() async {
    await clientAction.connectRequestPort(action: '2', param: jsonEncode(widget.productDetail!), callback: decodeData);
    getBranchLinkProductId(widget.productDetail!);
    getProductPrice(widget.productDetail!.product_sqlite_id.toString());
    getProductDialogStock(widget.productDetail!);
    controller.sink.add("refresh");
    //decodeData();
    // await readProductVariant(widget.productDetail!.product_sqlite_id!);
    // await readProductModifier(widget.productDetail!.product_sqlite_id!);
    // await getProductPrice(widget.productDetail!.product_sqlite_id);
    // categories =
    // await PosDatabase.instance.readSpecificCategoryById(widget.productDetail!.category_sqlite_id!);
    //print('category init: ${categories}');
    // setState(() {
    //   this.isLoaded = true;
    // });
  }

  decodeData(response){
    var json = jsonDecode(clientAction.response!);
    Iterable value1 = json['data']['variant'];
    variantGroup = List<VariantGroup>.from(value1.map((json) => VariantGroup.fromJson(json)));
    Iterable value2 = json['data']['modifier'];
    modifierGroup = List<ModifierGroup>.from(value2.map((json) => ModifierGroup.fromJson(json)));
    // finalPrice = json['data']['final_price'];
    // basePrice = json['data']['base_price'];
    // dialogPrice = json['data']['dialog_price'];

  }

  // readProductVariant(int productID) async {
  //   //loop variant group first
  //   List<VariantGroup> data = await PosDatabase.instance.readProductVariantGroup(productID);
  //   for (int i = 0; i < data.length; i++) {
  //     variantGroup.add(VariantGroup(
  //         variant_group_sqlite_id: data[i].variant_group_sqlite_id, variant_group_id: data[i].variant_group_id, child: [], name: data[i].name));
  //
  //     //loop variant child based on variant group id
  //     List<VariantItem> itemData = await PosDatabase.instance.readProductVariantItem(data[i].variant_group_sqlite_id!);
  //     List<VariantItem> itemChild = [];
  //     for (int j = 0; j < itemData.length; j++) {
  //       //pre-check radio button
  //       if (j == 0) {
  //         variantGroup[i].variant_item_sqlite_id = itemData[j].variant_item_sqlite_id;
  //       }
  //       //store all child into one list
  //       itemChild.add(VariantItem(
  //           variant_group_sqlite_id: itemData[j].variant_group_sqlite_id,
  //           variant_group_id: itemData[j].variant_group_id.toString(),
  //           name: itemData[j].name,
  //           variant_item_sqlite_id: itemData[j].variant_item_sqlite_id,
  //           variant_item_id: itemData[j].variant_item_id));
  //     }
  //     //assign list into group child
  //     variantGroup[i].child = itemChild;
  //   }
  // }

  // readProductModifier(int productID) async {
  //   List<ModifierGroup> data = await PosDatabase.instance.readProductModifierGroupName(productID);
  //
  //   for (int i = 0; i < data.length; i++) {
  //     modifierGroup.add(ModifierGroup(
  //       modifierChild: [],
  //       name: data[i].name,
  //       mod_group_id: data[i].mod_group_id,
  //       dining_id: data[i].dining_id,
  //       compulsory: data[i].compulsory,
  //     ));
  //
  //     List<ModifierItem> itemData = await PosDatabase.instance.readProductModifierItem(data[i].mod_group_id!);
  //     List<ModifierItem> modItemChild = [];
  //
  //     for (int j = 0; j < itemData.length; j++) {
  //       modItemChild.add(ModifierItem(
  //           mod_group_id: data[i].mod_group_id.toString(),
  //           name: itemData[j].name!,
  //           mod_item_id: itemData[j].mod_item_id,
  //           mod_status: itemData[j].mod_status,
  //           isChecked: false));
  //     }
  //     if(modifierGroup[i].compulsory == '1' && modifierGroup[i].dining_id == widget.cartModel.selectedOptionId){
  //       for(int k = 0; k < modItemChild.length; k++){
  //         modItemChild[k].isChecked = true;
  //       }
  //       modifierGroup[i].modifierChild = modItemChild;
  //     }
  //     modifierGroup[i].modifierChild = modItemChild;
  //     readProductModifierItemPrice(modifierGroup[i]);
  //   }
  // }

  // readProductModifierItemPrice(ModifierGroup modGroup) async {
  //   modifierItemPrice = '';
  //
  //   for (int i = 0; i < modGroup.modifierChild.length; i++) {
  //     List<BranchLinkModifier> data = await PosDatabase.instance.readBranchLinkModifier(modGroup.modifierChild[i].mod_item_id.toString());
  //     modGroup.modifierChild[i].price = data[0].price!;
  //   }
  // }

  // getProductPrice(int? productId) async {
  //   double totalBasePrice = 0.0;
  //   double totalModPrice = 0.0;
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     final int? branch_id = prefs.getInt('branch_id');
  //
  //     List<BranchLinkProduct> data = await PosDatabase.instance.readBranchLinkSpecificProduct(branch_id.toString(), productId.toString());
  //     if (data[0].has_variant == '0') {
  //       basePrice = data[0].price!;
  //       finalPrice = basePrice;
  //       //check product mod group
  //       for (int j = 0; j < modifierGroup.length; j++) {
  //         ModifierGroup group = modifierGroup[j];
  //         //loop mod group child
  //         for (int k = 0; k < group.modifierChild.length; k++) {
  //           if (group.modifierChild[k].isChecked == true) {
  //             List<BranchLinkModifier> modPrice = await PosDatabase.instance.readBranchLinkModifier(group.modifierChild[k].mod_item_id.toString());
  //             totalModPrice += double.parse(modPrice[0].price!);
  //             totalBasePrice = double.parse(data[0].price!) + totalModPrice;
  //             finalPrice = totalBasePrice.toStringAsFixed(2);
  //           }
  //         }
  //       }
  //     } else {
  //       List<BranchLinkProduct> productVariant = await PosDatabase.instance.checkProductVariant(await getProductVariant(productId!), productId.toString());
  //       basePrice = productVariant[0].price!;
  //       finalPrice = basePrice;
  //       dialogPrice = basePrice;
  //
  //       //loop has variant product modifier group
  //       for (int j = 0; j < modifierGroup.length; j++) {
  //         ModifierGroup group = modifierGroup[j];
  //         //loop mod group child
  //         for (int k = 0; k < group.modifierChild.length; k++) {
  //           if (group.modifierChild[k].isChecked == true) {
  //             List<BranchLinkModifier> modPrice = await PosDatabase.instance.readBranchLinkModifier(group.modifierChild[k].mod_item_id.toString());
  //             totalModPrice += double.parse(modPrice[0].price!);
  //             totalBasePrice = double.parse(productVariant[0].price!) + totalModPrice;
  //             finalPrice = totalBasePrice.toStringAsFixed(2);
  //           }
  //         }
  //       }
  //     }
  //   } catch (error) {
  //     print('Get product base price error ${error}');
  //   }
  //   return finalPrice;
  // }

  // getBranchLinkProductItem(Product product) async {
  //   branchLinkProduct_id = '';
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     final int? branch_id = prefs.getInt('branch_id');
  //     if (product.has_variant == 0) {
  //       List<BranchLinkProduct> data1 = await PosDatabase.instance.readBranchLinkSpecificProduct(branch_id.toString(), product.product_sqlite_id.toString());
  //       branchLinkProduct_id = data1[0].branch_link_product_sqlite_id.toString();
  //       if(data1[0].stock_type == '2') {
  //         if (int.parse(data1[0].stock_quantity!) > 0 && simpleIntInput <= int.parse(data1[0].stock_quantity!)) {
  //           hasStock = true;
  //         } else {
  //           hasStock = false;
  //         }
  //       } else {
  //         if (int.parse(data1[0].daily_limit_amount!) > 0 && simpleIntInput <= int.parse(data1[0].daily_limit_amount!)) {
  //           hasStock = true;
  //         } else {
  //           hasStock = false;
  //         }
  //       }
  //     } else {
  //       //check has variant product stock
  //       List<BranchLinkProduct> data = await PosDatabase.instance.checkProductVariant(await getProductVariant(product.product_sqlite_id!), product.product_sqlite_id.toString());
  //       branchLinkProduct_id = data[0].branch_link_product_sqlite_id.toString();
  //       if (data[0].stock_type == '2') {
  //         if (int.parse(data[0].stock_quantity!) > 0 && simpleIntInput <= int.parse(data[0].stock_quantity!)) {
  //           hasStock = true;
  //         } else {
  //           hasStock = false;
  //         }
  //       } else {
  //         if (int.parse(data[0].daily_limit_amount!) > 0 && simpleIntInput <= int.parse(data[0].daily_limit_amount!)) {
  //           hasStock = true;
  //         } else {
  //           hasStock = false;
  //         }
  //       }
  //     }
  //     return branchLinkProduct_id;
  //   } catch (e) {
  //     Fluttertoast.showToast(msg: 'Make sure stock is restock');
  //   }
  // }

  // getProductVariant(int product_id) async {
  //   String variant = '';
  //   String variant2 = '';
  //   String variant3 = '';
  //   String productVariant = '';
  //   try {
  //     for (int j = 0; j < variantGroup.length; j++) {
  //       VariantGroup group = variantGroup[j];
  //       for (int i = 0; i < group.child!.length; i++) {
  //         if (group.variant_item_sqlite_id == group.child![i].variant_item_sqlite_id) {
  //           group.child![i].isSelected = true;
  //           if (variant == '') {
  //             variant = group.child![i].name!.trim();
  //             if (variantGroup.length == 1) {
  //               List<ProductVariant> data = await PosDatabase.instance.readSpecificProductVariant(product_id.toString(), variant);
  //               productVariant = data[0].product_variant_sqlite_id.toString();
  //               break;
  //             }
  //           } else if (variant2 == '') {
  //             variant2 = variant + " | " + group.child![i].name!;
  //             if (variantGroup.length == 2) {
  //               List<ProductVariant> data = await PosDatabase.instance.readSpecificProductVariant(product_id.toString(), variant2);
  //               productVariant = data[0].product_variant_sqlite_id.toString();
  //               break;
  //             }
  //           } else if (variant3 == '') {
  //             variant3 = variant2 + " | " + group.child![i].name!;
  //             if (variantGroup.length == 3) {
  //               List<ProductVariant> data = await PosDatabase.instance.readSpecificProductVariant(product_id.toString(), variant3);
  //               productVariant = data[0].product_variant_sqlite_id.toString();
  //               break;
  //             }
  //           }
  //         }
  //       }
  //     }
  //     // print('variant string: ${variant}');
  //     // print('product variant: ${productVariant}');
  //     return productVariant;
  //   } catch (error) {
  //     print('get product variant error: ${error}');
  //     return;
  //   }
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

  _onSubmitted(String value) {
    print("on submitted called!!!");
    //AppSetting? localSetting = await PosDatabase.instance.readLocalAppSetting(branch_id.toString());
    switch(checkProductStockStatus(widget.productDetail!, cart)){
      case 1 : {
        Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000),
            msg: "Product variant sold out!");
      }break;
      case 2 : {
        Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000),
            msg: "Quantity input exceed stock amount");
      }break;
      default: {
        if (cart.selectedOption == 'Dine in') {
          if (simpleIntInput > 0) {
            if (cart.selectedTable.isNotEmpty) {
              // Disable the button after it has been pressed
              setState(() {
                isButtonDisabled = true;
              });
              addToCart(cart);
              Navigator.of(context).pop();
            } else {
              openChooseTableDialog(cart);
            }
          } else {
            Fluttertoast.showToast(
                backgroundColor: Color(0xFFFF0000), msg: "Invalid qty input");
          }
        } else {
          // Disable the button after it has been pressed
          setState(() {
            isButtonDisabled = true;
          });
          addToCart(cart);
          Navigator.of(context).pop();
        }
      }
    }
    // if (checkProductStock(widget.productDetail!, cart) == true) {
    //   print("check product stock return true called!!!");
    //   //print("appSettingModel.table_order: ${localSetting!.table_order}");
    //   if (cart.selectedOption == 'Dine in') {
    //     if (simpleIntInput > 0) {
    //       if (cart.selectedTable.isNotEmpty) {
    //         // Disable the button after it has been pressed
    //         setState(() {
    //           isButtonDisabled = true;
    //         });
    //         addToCart(cart);
    //         Navigator.of(context).pop();
    //       } else {
    //         openChooseTableDialog(cart);
    //       }
    //     } else {
    //       Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('invalid_qty_input'));
    //     }
    //   } else {
    //     // Disable the button after it has been pressed
    //     setState(() {
    //       isButtonDisabled = true;
    //     });
    //     addToCart(cart);
    //     Navigator.of(context).pop();
    //   }
    // } else {
    //   print("on submitted else called!!!");
    //   Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('product_variant_sold_out'));
    // }
  }

  ///Check stock status
  ///
  /// 0 = has stock
  ///
  /// 1 = out of stock stock
  ///
  /// 2 = qty input stock exceed
  int checkProductStockStatus(Product product, CartModel cart) {
    int stockStatus = 0;
    try{
      if (product.has_variant == 0) {
        switch(branchLinkProduct.stock_type){
          case '1' :{
            if (int.parse(branchLinkProduct.daily_limit!) > 0 && simpleIntInput <= int.parse(branchLinkProduct.daily_limit!)) {
              num stockLeft = int.parse(branchLinkProduct.daily_limit!) - checkCartProductQuantity(cart, branchLinkProduct);
              bool isQtyNotExceed = simpleIntInput <= stockLeft;
              if(isQtyNotExceed){
                stockStatus = 0;
              } else {
                stockStatus = 2;
              }
            } else {
              stockStatus = 1;
            }
          }break;
          case '2': {
            if (int.parse(branchLinkProduct.stock_quantity!) > 0 && simpleIntInput <= int.parse(branchLinkProduct.stock_quantity!)) {
              num stockLeft = int.parse(branchLinkProduct.stock_quantity!) - checkCartProductQuantity(cart, branchLinkProduct);
              bool isQtyNotExceed = simpleIntInput <= stockLeft;
              if(isQtyNotExceed){
                stockStatus = 0;
              } else {
                stockStatus = 2;
              }
            } else {
              stockStatus = 1;
            }
          }break;
          default: {
            stockStatus = 0;
          }
        }
      } else {
        switch(branchLinkProduct.stock_type){
          case '1' :{
            if (int.parse(branchLinkProduct.daily_limit!) > 0 && simpleIntInput <= int.parse(branchLinkProduct.daily_limit!)) {
              num stockLeft =  int.parse(branchLinkProduct.daily_limit!) - checkCartProductQuantity(cart, branchLinkProduct);
              bool isQtyNotExceed = simpleIntInput <= stockLeft;
              if(isQtyNotExceed){
                stockStatus = 0;
              } else {
                stockStatus = 2;
              }
            } else {
              stockStatus = 1;
            }
          }break;
          case '2': {
            if (int.parse(branchLinkProduct.stock_quantity!) > 0 && simpleIntInput <= int.parse(branchLinkProduct.stock_quantity!)) {
              num stockLeft =  int.parse(branchLinkProduct.stock_quantity!) - checkCartProductQuantity(cart, branchLinkProduct);
              bool isQtyNotExceed = simpleIntInput <= stockLeft;
              if(isQtyNotExceed){
                stockStatus = 0;
              } else {
                stockStatus = 2;
              }
            } else {
              stockStatus = 1;
            }
          }break;
          default: {
            stockStatus = 0;
          }
        }
      }
    } catch(e){
      print("check product stock error: $e");
      stockStatus = 1;
    }
    return stockStatus;
  }

  num checkCartProductQuantity(CartModel cart, BranchLinkProduct branchLinkProduct){
    ///get all same item in cart
    List<cartProductItem> sameProductList = cart.cartNotifierItem.where(
            (item) => item.branch_link_product_sqlite_id == branchLinkProduct.branch_link_product_sqlite_id.toString() && item.status == 0
    ).toList();
    if(sameProductList.isNotEmpty){
      /// sum all quantity
      num totalQuantity = sameProductList.fold(0, (sum, product) => sum + product.quantity!);
      return totalQuantity;
    } else {
      return 0;
    }
  }

  void getBranchLinkProductId(Product product){
    if(branchLinkProductList.isNotEmpty){
      if (product.has_variant == 0) {
        BranchLinkProduct? branchLinkProduct = branchLinkProductList.firstWhere((item) => item.product_sqlite_id == product.product_sqlite_id.toString());
        this.branchLinkProduct = branchLinkProduct;
      } else {
        String productVariantId = getProductVariant(product.product_sqlite_id.toString());
        BranchLinkProduct branchLinkProduct =
        branchLinkProductList.firstWhere((item) => item.product_sqlite_id == product.product_sqlite_id.toString() && item.product_variant_sqlite_id == productVariantId);
        this.branchLinkProduct = branchLinkProduct;
      }
    }
    print('branch link product: ${branchLinkProduct.branch_link_product_sqlite_id}');
  }

  // getBranchLinkProductItem(Product product){
  //   try{
  //     if (product.has_variant == 0) {
  //       print('branch link product list: ${branchLinkProductList.length}');
  //       BranchLinkProduct? branchLinkProduct = branchLinkProductList.firstWhere((item) => item.product_sqlite_id == product.product_sqlite_id.toString());
  //       print('branch link product: ${branchLinkProduct.branch_link_product_sqlite_id}');
  //       branchLinkProduct_id = branchLinkProduct.branch_link_product_sqlite_id.toString();
  //       if(branchLinkProduct.stock_type == '2') {
  //         if (int.parse(branchLinkProduct.stock_quantity!) > 0 && simpleIntInput <= int.parse(branchLinkProduct.stock_quantity!)) {
  //           hasStock = true;
  //         } else {
  //           hasStock = false;
  //         }
  //       } else {
  //         if (int.parse(branchLinkProduct.daily_limit_amount!) > 0 && simpleIntInput <= int.parse(branchLinkProduct.daily_limit_amount!)) {
  //           hasStock = true;
  //         } else {
  //           hasStock = false;
  //         }
  //       }
  //     } else {
  //       String productVariantId = getProductVariant(product.product_sqlite_id.toString());
  //       print('product variant id: $productVariantId');
  //       BranchLinkProduct branchLinkProduct =
  //       branchLinkProductList.firstWhere((item) => item.product_sqlite_id == product.product_sqlite_id.toString() && item.product_variant_sqlite_id == productVariantId);
  //       branchLinkProduct_id = branchLinkProduct.branch_link_product_sqlite_id.toString();
  //       if (branchLinkProduct.stock_type == '2') {
  //         if (int.parse(branchLinkProduct.stock_quantity!) > 0 && simpleIntInput <= int.parse(branchLinkProduct.stock_quantity!)) {
  //           hasStock = true;
  //         } else {
  //           hasStock = false;
  //         }
  //       } else {
  //         if (int.parse(branchLinkProduct.daily_limit_amount!) > 0 && simpleIntInput <= int.parse(branchLinkProduct.daily_limit_amount!)) {
  //           hasStock = true;
  //         } else {
  //           hasStock = false;
  //         }
  //       }
  //     }
  //     return branchLinkProduct_id;
  //   } catch(e){
  //     print('get branch link product error: $e');
  //     //Fluttertoast.showToast(msg: 'Something went wrong, please try again later');
  //   }
  // }

  getProductVariant(String productLocalId){
    String variant = '';
    String variant2 = '';
    String variant3 = '';
    String productVariantLocalId = '';
    try {
      for (int j = 0; j < variantGroup.length; j++) {
        VariantGroup group = variantGroup[j];
        for (int i = 0; i < group.child!.length; i++) {
          if (group.variant_item_sqlite_id == group.child![i].variant_item_sqlite_id) {
            group.child![i].isSelected = true;
            if (variant == '') {
              variant = group.child![i].name!;
              if (variantGroup.length == 1) {
                ProductVariant? data = productVariantList.firstWhere((item) => item.product_sqlite_id == productLocalId && item.variant_name == variant);
                //List<ProductVariant> data = await PosDatabase.instance.readSpecificProductVariant(product_id.toString(), variant);
                // productVariant = data[0].product_variant_sqlite_id.toString();
                productVariantLocalId = data.product_variant_sqlite_id.toString();
                break;
              }
            } else if (variant2 == '') {
              variant2 = variant + " | " + group.child![i].name!;
              if (variantGroup.length == 2) {
                ProductVariant data = productVariantList.firstWhere((item) => item.product_sqlite_id == productLocalId && item.variant_name == variant2);
                productVariantLocalId = data.product_variant_sqlite_id.toString();
                // List<ProductVariant> data = await PosDatabase.instance.readSpecificProductVariant(product_id.toString(), variant2);
                // productVariant = data[0].product_variant_sqlite_id.toString();
                break;
              }
            } else if (variant3 == '') {
              variant3 = variant2 + " | " + group.child![i].name!;
              if (variantGroup.length == 3) {
                ProductVariant data = productVariantList.firstWhere((item) => item.product_sqlite_id == productLocalId && item.variant_name == variant3);
                productVariantLocalId = data.product_variant_sqlite_id.toString();
                // List<ProductVariant> data = await PosDatabase.instance.readSpecificProductVariant(product_id.toString(), variant3);
                // productVariant = data[0].product_variant_sqlite_id.toString();
                break;
              }
            }
          }
        }
      }
      // print('variant string: ${variant}');
      // print('product variant: ${productVariant}');
      return productVariantLocalId;
    } catch (error) {
      print('get product variant error: ${error}');
      return;
    }
  }

  void getProductPrice(String? productLocalId){
    double totalBasePrice = 0.0;
    double totalModPrice = 0.0;
    try {
      if (branchLinkProduct.has_variant == '0') {
        basePrice = branchLinkProduct.price!;
        finalPrice = basePrice;
        //check product mod group
        for (int j = 0; j < modifierGroup.length; j++) {
          ModifierGroup group = modifierGroup[j];
          //loop mod group child
          for (int k = 0; k < group.modifierChild!.length; k++) {
            if (group.modifierChild![k].isChecked == true) {
              //List<BranchLinkModifier> modPrice = await PosDatabase.instance.readBranchLinkModifier(group.modifierChild![k].mod_item_id.toString());
              BranchLinkModifier branchLinkModifier = branchLinkModifierList.firstWhere((item) => item.mod_item_id == group.modifierChild![k].mod_item_id.toString());
              totalModPrice += double.parse(branchLinkModifier.price!);
              totalBasePrice = double.parse(branchLinkProduct.price!) + totalModPrice;
              finalPrice = totalBasePrice.toStringAsFixed(2);
            }
          }
        }
      } else {
        basePrice = branchLinkProduct.price!;
        finalPrice = basePrice;
        dialogPrice = basePrice;

        //loop has variant product modifier group
        for (int j = 0; j < modifierGroup.length; j++) {
          ModifierGroup group = modifierGroup[j];
          //loop mod group child
          for (int k = 0; k < group.modifierChild!.length; k++) {
            if (group.modifierChild![k].isChecked == true) {
              BranchLinkModifier branchLinkModifier = branchLinkModifierList.firstWhere((item) => item.mod_item_id == group.modifierChild![k].mod_item_id.toString());
              totalModPrice += double.parse(branchLinkModifier.price!);
              totalBasePrice = double.parse(branchLinkProduct.price!) + totalModPrice;
              finalPrice = totalBasePrice.toStringAsFixed(2);
            }
          }
        }
      }
    } catch (error) {
      print('Get product base price error ${error}');
    }
    dialogPrice = finalPrice;
  }

  void getProductDialogStock(Product product){
    if (product.has_variant == 0) {
      switch(branchLinkProduct.stock_type){
        case '1': {
          dialogStock = branchLinkProduct.daily_limit.toString();
        }break;
        case '2': {
          dialogStock = branchLinkProduct.stock_quantity.toString();
        }break;
        default:{
          dialogStock = '';
        }
      }
    } else {
      switch(branchLinkProduct.stock_type){
        case '1': {
          dialogStock = branchLinkProduct.daily_limit.toString();
        }break;
        case '2': {
          dialogStock = branchLinkProduct.stock_quantity.toString();
        }break;
        default:{
          dialogStock = '';
        }
      }
    }
  }

  compareCartProductModifier({required List<ModifierGroup> cartModifierGroup}){
    List<ModifierItem> checkedCartModItem = [];
    //add all checked modifier item from cart product
    if(cartModifierGroup.isNotEmpty){
      for(int i = 0 ; i < cartModifierGroup.length; i++){
        ModifierGroup group = cartModifierGroup[i];
        for(int j = 0; j < group.modifierChild!.length; j++){
          if(group.modifierChild![j].isChecked == true){
            checkedCartModItem.add(cartModifierGroup[i].modifierChild![j]);
          }
        }
      }
    }
    return checkSame(checkedCartModItem, checkedModItem);
  }

  bool checkSame(List<ModifierItem> checkedCartModItem, List<ModifierItem> checkedModItem) {
    List<int> cartModItemId = [];
    List<int> checkedModItemId = [];
    bool same = true;
    if (checkedCartModItem.length != checkedModItem.length) {
      same = false;
    } else {
      //insert mod item id into a list
      for(int i = 0; i < checkedCartModItem.length; i++){
        cartModItemId.add(checkedCartModItem[i].mod_item_id!);
      }
      //insert mod item id into a list
      for(int j = 0; j< checkedModItem.length; j++){
        checkedModItemId.add(checkedModItem[j].mod_item_id!);
      }
      //get all same mod item into a list
      List<int> comparedList = cartModItemId.toSet().intersection(checkedModItemId.toSet()).toList();
      print('compared list length: ${comparedList.length}');
      if(comparedList.length == checkedModItem.length){
        same = true;
      } else {
        same = false;
      }
    }
    return same;
  }

  addToCart(CartModel cart){
    //check selected variant
    for (int j = 0; j < variantGroup.length; j++) {
      VariantGroup group = variantGroup[j];
      for (int i = 0; i < group.child!.length; i++) {
        if (group.variant_item_sqlite_id == group.child![i].variant_item_sqlite_id) {
          group.child![i].isSelected = true;
        } else {
          group.child![i].isSelected = false;
        }
      }
    }
    //check checked modifier length
    if(checkedModItem.isNotEmpty){
      checkedModifierLength = checkedModItem.length;
    } else {
      checkedModifierLength = 0;
      checkedModItem = [];
    }
    var value = cartProductItem(
        branch_link_product_sqlite_id: branchLinkProduct.branch_link_product_sqlite_id.toString(),
        product_name: widget.productDetail!.name!,
        category_id: widget.productDetail!.category_id!,
        category_name: categories != null ? categories!.name : '',
        price: dialogPrice,
        quantity: simpleIntInput,
        checkedModifierLength: checkedModifierLength,
        checkedModifierItem: checkedModItem,
        modifier: modifierGroup,
        variant: variantGroup,
        remark: remarkController.text,
        status: 0,
        category_sqlite_id: widget.productDetail!.category_sqlite_id,
        base_price: basePrice,
        refColor: Colors.black,
    );
    List<cartProductItem> item = [];
    if(cart.cartNotifierItem.isEmpty){
      cart.addItem(value);
    } else {
      for(int k = 0; k < cart.cartNotifierItem.length; k++){
        if(cart.cartNotifierItem[k].branch_link_product_sqlite_id == value.branch_link_product_sqlite_id
            && value.remark == cart.cartNotifierItem[k].remark
            && value.checkedModifierLength == cart.cartNotifierItem[k].checkedModifierLength
            && cart.cartNotifierItem[k].status == 0) {
          item.add(cart.cartNotifierItem[k]);
        }
      }
      while(item.length > 1){
        for(int i = 0 ; i < item.length; i++){
          bool status = compareCartProductModifier(cartModifierGroup: item[i].modifier!);
          if(status == false){
            item.remove(item[i]);
          }
        }
      }
      if(item.length == 1){
        if(item[0].checkedModifierLength == 0){
          item[0].quantity = item[0].quantity! + value.quantity!;
        } else {
          bool status = compareCartProductModifier(cartModifierGroup: item[0].modifier!);
          print('compared status: ${status}');
          if(status == false){
            cart.addItem(value);
          } else{
            item[0].quantity = item[0].quantity! + value.quantity!;
          }
        }
      } else {
        cart.addItem(value);
      }
    }
    cart.resetCount();
    decodeAction.cartProductController.sink.add(cart);
  }
}
