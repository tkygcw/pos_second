import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:optimy_second_device/main.dart';
import 'package:optimy_second_device/object/app_setting.dart';
import 'package:provider/provider.dart';

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

  const ProductOrderDialog({Key? key, this.productDetail}) : super(key: key);

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
  List<BranchLinkProduct> branchLinkProductList = [];
  List<ProductVariant> productVariantList = decodeAction.decodedProductVariantList!;
  List<BranchLinkModifier> branchLinkModifierList = decodeAction.decodedBranchLinkModifierList!;
  AppSetting appSetting = decodeAction.decodedAppSetting!;
  Categories? categories;
  BranchLinkProduct? branchLinkProduct;
  String basePrice = '';
  String finalPrice = '';
  String dialogPrice = '', dialogStock = '', productName = '';
  num simpleIntInput = 1, pressed = 0;
  int checkedModifierLength = 0;
  String modifierItemPrice = '';
  List<VariantGroup> variantGroup = [];
  List<ModifierGroup> modifierGroup = [];
  List<ModifierItem> checkedModItem = [];
  final remarkController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController nameController = TextEditingController();

  bool checkboxValueA = false;
  bool isLoaded = false;
  bool hasPromo = false;
  bool isButtonDisabled = false, isAddButtonDisabled = false;
  bool customPriceModified = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    contentStream = controller.stream;
    actionStream = actionController.stream;
    simpleIntInput = widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ? 0 : 1;
    quantityController = TextEditingController(text: widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ? '' : '$simpleIntInput');
    priceController = TextEditingController(text:  int.tryParse(widget.productDetail!.price!) == 0 && widget.productDetail!.unit == 'each_c' ? '' : widget.productDetail!.price);
    // priceController = TextEditingController(text: widget.productDetail!.price);
    nameController = TextEditingController(text: widget.productDetail!.name);
    productName = widget.productDetail!.name!;
    productChecking();
    listenAction();
  }

  @override
  void dispose() {
    actionSubscription.cancel();
    super.dispose();
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

  getInitCheckedModItem(){
    for(final group in modifierGroup){
      checkedModItem.addAll(group.modifierChild!.where((child) => child.isChecked == true).toList());
    }
  }

  productChecking() async {
    categories = decodeAction.decodedCategoryList?.firstWhereOrNull((e) => widget.productDetail!.category_id! == e.category_id!.toString());
    Map<String, dynamic> param = {
      'product_detail': widget.productDetail!,
      'dining_option_id': context.read<CartModel>().selectedOptionId
    };
    await clientAction.connectRequestPort(action: '2', param: jsonEncode(param), callback: decodeData);
  }

  decodeData(response){
    if(response != null && mounted){
      var json = jsonDecode(response);
      switch(json['status']){
        case '-1': {
          variantGroup = [];
          modifierGroup =[];
          branchLinkProductList = decodeAction.decodedBranchLinkProductList!;
          this.branchLinkProduct = branchLinkProductList.first;
          dialogPrice = '5.00';
          controller.sink.add("refresh");
        }break;
        case '1': {
          Iterable value1 = json['data']['variant'];
          variantGroup = List<VariantGroup>.from(value1.map((json) => VariantGroup.fromJson(json)));
          Iterable value2 = json['data']['modifier'];
          modifierGroup = List<ModifierGroup>.from(value2.map((json) => ModifierGroup.fromJson(json)));
          Iterable value3 = json['data']['branch_link_product'];
          branchLinkProductList = List<BranchLinkProduct>.from(value3.map((json) => BranchLinkProduct.fromJson(json)));
          getInitCheckedModItem();
          getBranchLinkProductId(widget.productDetail!);
          getProductPrice(widget.productDetail!.product_sqlite_id.toString());
          getProductDialogStock(widget.productDetail!);
          controller.sink.add("refresh");
        }break;
        case '2': {
          Map<String, dynamic> param = {
            'product_detail': widget.productDetail!,
            'dining_option_id': context.read<CartModel>().selectedOptionId
          };
          clientAction.openReconnectDialog(action: '2', param: jsonEncode(param), callback: decodeData);
        }break;
        default: {
          clientAction.openReconnectDialog(action: json['action'], param: json['param'], callback: decodeData);
        }
      }
    }
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
    bool minSelectText = false;
    int checkedModifiersCount = 0;
    int maxSelect = modifierGroup.max_select ?? 0;
    int minSelect = modifierGroup.min_select ?? 0;
    for(int i = 0; i < modifierGroup.modifierChild!.length; i++){
      if(modifierGroup.modifierChild![i].isChecked!){
        checkedModifiersCount++;
      }
    }

    if(minSelect != 0 && checkedModifiersCount < minSelect) {
      minSelectText = true;
      isAddButtonDisabled = true;
    } else {
      minSelectText = false;
    }

    String getModifierMinMaxHint() {
      if (minSelectText) {
        return ' (${AppLocalizations.of(context)!.translate('choose_at_least')} $minSelect ${AppLocalizations.of(context)!.translate('ge')})';
      } else if (maxSelect != 0) {
        return ' (${AppLocalizations.of(context)!.translate('choose_maximum')} $maxSelect ${AppLocalizations.of(context)!.translate('ge')})';
      } else {
        return '';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: modifierGroup.name!,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (maxSelect != 0 || minSelectText)
                TextSpan(
                  text: getModifierMinMaxHint(),
                  style: TextStyle(color: minSelectText ? Colors.red : Colors.black, fontSize: 14),
                ),
            ],
          ),
        ),
        for (int i = 0; i < modifierGroup.modifierChild!.length; i++)
          CheckboxListTile(
            title: Row(
              children: [
                Text('${modifierGroup.modifierChild![i].name!}'),
                Text(
                  ' (+$currency_symbol ${Utils.convertTo2Dec(modifierGroup.modifierChild![i].price)})',
                  style: TextStyle(fontSize: 12),
                )
              ],
            ),
            value: modifierGroup.modifierChild![i].isChecked,
            onChanged: modifierGroup.modifierChild![i].mod_status! == '2'
                ? null
                : (isChecked) {
              if (isChecked! && maxSelect != 0 && checkedModifiersCount >= maxSelect) {
                Fluttertoast.showToast(
                    backgroundColor: Colors.red,
                    msg: '${modifierGroup.name} ${AppLocalizations.of(context)!.translate('choose_maximum')} $maxSelect ${AppLocalizations.of(context)!.translate('ge')}'
                );
                return;
              }
              setState(() {
                checkedModifiersCount++;
                modifierGroup.modifierChild![i].isChecked = isChecked;
                addCheckedModItem(modifierGroup.modifierChild![i]);
                actionController.sink.add("add-on");
                print("checkedModifiersCount: $checkedModifiersCount");
                print("minSelect: $minSelect");
                if(minSelect != 0 && checkedModifiersCount < minSelect) {
                  isAddButtonDisabled = true;
                } else {
                  isAddButtonDisabled = false;
                }
              });
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
                if (constraints.maxWidth > 900 && constraints.maxHeight > 500) {
                  return AlertDialog(
                    title: Row(
                      children: [
                        Container(
                          constraints: BoxConstraints(maxWidth: 300),
                          child: Text(productName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              )),
                        ),
                        Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ?
                            Text("$currency_symbol ${Utils.convertTo2Dec(dialogPrice)} / ${widget.productDetail!.per_quantity_unit!}${widget.productDetail!.unit!}",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                )) :
                            Text("$currency_symbol ${Utils.convertTo2Dec(dialogPrice)} / each",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                )),
                            Visibility(
                              visible: dialogStock != '' ? true : false,
                              child: Text("${AppLocalizations.of(context)!.translate('in_stock')}: $dialogStock${widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ? widget.productDetail!.unit : ''}",
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
                    content: SizedBox(
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width / 3,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Visibility(
                              visible: decodeAction.decodedAppSetting!.show_product_desc == 1 ? true : false,
                              child: Padding(
                                padding: EdgeInsets.only(bottom: 15.0),
                                child: Text(widget.productDetail!.description!),
                              ),
                            ),
                            Visibility(
                              visible: widget.productDetail!.unit == 'each_c' ? true : false,
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppLocalizations.of(context)!.translate('product_name'),
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: 400,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 273,
                                          child: TextField(
                                            autofocus: false,
                                            controller: nameController,
                                            keyboardType: TextInputType.text,
                                            textAlign: TextAlign.center,
                                            decoration: InputDecoration(
                                              errorText: getErrorText(nameController.text),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(color: color.backgroundColor),
                                              ),
                                            ),
                                            onChanged: (value) => setState(() {
                                              try{
                                                productName = value;
                                              }catch (e){
                                                productName = "Custom";
                                              }
                                            }),
                                            onSubmitted: (value) {
                                              if(productName.isNotEmpty || productName == ''){
                                                setState(() {
                                                  productName = value;
                                                });
                                              }else {
                                                Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('product_name_empty'));
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppLocalizations.of(context)!.translate('price'),
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: 400,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 273,
                                          child: TextField(
                                            autofocus: true,
                                            controller: priceController,
                                            keyboardType: TextInputType.number,
                                            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                                            textAlign: TextAlign.center,
                                            decoration: InputDecoration(
                                              errorText: getPriceErrorText(priceController.text),
                                              prefixText: '$currency_symbol ',
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(color: color.backgroundColor),
                                              ),
                                              hintText: Utils.convertTo2Dec(dialogPrice),
                                            ),
                                            onChanged: (value) {
                                              setState(() {
                                                customPriceModified = true;
                                                getProductPrice(widget.productDetail!.product_sqlite_id.toString());
                                              });
                                            },
                                            onSubmitted: (value) {
                                              setState(() {
                                                getProductPrice(widget.productDetail!.product_sqlite_id.toString());
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                                        AppLocalizations.of(context)!.translate('quantity'),
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                // quantity input
                                SizedBox(
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
                                                quantityController.text = widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ? simpleIntInput.toStringAsFixed(2) : simpleIntInput.toString();
                                                simpleIntInput = widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ? double.parse(quantityController.text.replaceAll(',', '')) : int.parse(quantityController.text.replaceAll(',', ''));
                                              });
                                            } else{
                                              setState(() {
                                                simpleIntInput = 0;
                                                quantityController.text =  widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ? simpleIntInput.toStringAsFixed(2) : simpleIntInput.toString();
                                                simpleIntInput = widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ? double.parse(quantityController.text.replaceAll(',', '')) : int.parse(quantityController.text.replaceAll(',', ''));
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      // quantity input text field
                                      SizedBox(
                                        width: 273,
                                        child: TextField(
                                          autofocus: widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ? true : false,
                                          controller: quantityController,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ? <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))]
                                              : <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                                          textAlign: TextAlign.center,
                                          decoration: InputDecoration(
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: color.backgroundColor),
                                            ),
                                          ),
                                          onChanged: (value) {
                                            if(value != ''){
                                              setState(() => simpleIntInput = widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ? double.parse(value.replaceAll(',', '')): int.parse(value.replaceAll(',', '')));
                                            } else {
                                              simpleIntInput = 0;
                                            }
                                          },
                                          onSubmitted: (value) => _onSubmitted(value, color),
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
                                        AppLocalizations.of(context)!.translate('remark'),
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
                          onPressed: isButtonDisabled ? null : () {
                            Navigator.of(context).pop();

                            // Disable the button after it has been pressed
                            setState(() {
                              isButtonDisabled = true;
                            });
                          },
                          child: Text('${AppLocalizations.of(context)?.translate('close')}')
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 4,
                        height: MediaQuery.of(context).size.height / 12,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color.buttonColor,
                          ),
                          onPressed: isButtonDisabled || isAddButtonDisabled ? null : ()  {
                            if((priceController.text.isEmpty || priceController.text.trim().isEmpty) || (nameController.text.isEmpty || nameController.text.trim().isEmpty)){
                              Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('custom_field_required'));
                            } else {
                              _productStockStatusAction(color);
                            }
                          },
                          child: Text('${AppLocalizations.of(context)?.translate('add')}')
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
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width / 2),
                              child: Text(productName,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  )),
                            ),
                            Spacer(),
                            isLandscapeOrien() ? Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ?
                                Text("$currency_symbol ${Utils.convertTo2Dec(dialogPrice)} / ${widget.productDetail!.per_quantity_unit!}${widget.productDetail!.unit!}",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    )) :
                                Text("$currency_symbol ${Utils.convertTo2Dec(dialogPrice)} / each",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    )),
                                Visibility(
                                  visible: dialogStock != '' ? true : false,
                                  child: Text("${AppLocalizations.of(context)!.translate('in_stock')}: $dialogStock${widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ? widget.productDetail!.unit : ''}",
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: dialogStock == '0' ? Colors.red : Colors.black
                                      )),
                                )

                              ],
                            ) : Container()
                          ],
                        ),
                        content: SizedBox(
                          height: MediaQuery.of(context).size.height /2.5,
                          width: MediaQuery.of(context).size.width / 1.5,
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                isLandscapeOrien() ? Container() :Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ?
                                      Text("$currency_symbol ${Utils.convertTo2Dec(dialogPrice)} / ${widget.productDetail!.per_quantity_unit!}${widget.productDetail!.unit!}",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          )) :
                                      Text("$currency_symbol ${Utils.convertTo2Dec(dialogPrice)} / each",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          )),
                                      Visibility(
                                        visible: dialogStock != '' ? true : false,
                                        child: Text("${AppLocalizations.of(context)!.translate('in_stock')}: $dialogStock${widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ? widget.productDetail!.unit : ''}",
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: dialogStock == '0' ? Colors.red : Colors.black
                                            )),
                                      )

                                    ],
                                  ),
                                ),
                                Visibility(
                                  visible: widget.productDetail!.unit == 'each_c' ? true : false,
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            Text(
                                              AppLocalizations.of(context)!.translate('product_name'),
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                autofocus: false,
                                                controller: nameController,
                                                keyboardType: TextInputType.text,
                                                textAlign: TextAlign.center,
                                                decoration: InputDecoration(
                                                  errorText: getErrorText(nameController.text),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderSide: BorderSide(color: color.backgroundColor),
                                                  ),
                                                ),
                                                onChanged: (value) => setState(() {
                                                  try{
                                                    productName = value;
                                                  }catch (e){
                                                    productName = "Custom";
                                                  }
                                                }),
                                                onSubmitted: (value) {
                                                  if(productName.isNotEmpty){
                                                    setState(() {
                                                      productName = value;
                                                    });
                                                  }else {
                                                    Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('product_name_empty'));
                                                  }
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            Text(
                                              AppLocalizations.of(context)!.translate('price'),
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                autofocus: true,
                                                controller: priceController,
                                                keyboardType: TextInputType.number,
                                                inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                                                textAlign: TextAlign.center,
                                                decoration: InputDecoration(
                                                  errorText: getPriceErrorText(priceController.text),
                                                  prefixText: '$currency_symbol ',
                                                  focusedBorder: OutlineInputBorder(
                                                    borderSide: BorderSide(color: color.backgroundColor),
                                                  ),
                                                  hintText: Utils.convertTo2Dec(dialogPrice),
                                                ),
                                                onChanged: (value) =>  setState(() {
                                                  customPriceModified = true;
                                                  getProductPrice(widget.productDetail!.product_sqlite_id.toString());
                                                }),
                                                onSubmitted: (value) {
                                                  setState(() {
                                                    getProductPrice(widget.productDetail!.product_sqlite_id.toString());
                                                  });
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                for (int i = 0; i < variantGroup.length; i++)
                                  variantGroupLayout(variantGroup[i]),
                                for (int j = 0; j < modifierGroup.length; j++)
                                  Visibility(
                                    visible: modifierGroup[j].modifierChild!.isNotEmpty && modifierGroup[j].dining_id == "" || modifierGroup[j].dining_id == cart.selectedOptionId ? true : false,
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
                                            AppLocalizations.of(context)!.translate('quantity'),
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // quantity input
                                    SizedBox(
                                      width: 400,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          // quantity input remove button
                                          Expanded(
                                            flex: 1,
                                            child: Container(
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
                                                      quantityController.text = widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ? simpleIntInput.toStringAsFixed(2) : simpleIntInput.toString();
                                                      simpleIntInput = widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ? double.parse(quantityController.text.replaceAll(',', '')) : int.parse(quantityController.text.replaceAll(',', ''));
                                                    });
                                                  } else{
                                                    setState(() {
                                                      simpleIntInput = 0;
                                                      quantityController.text =  widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ? simpleIntInput.toStringAsFixed(2) : simpleIntInput.toString();
                                                      simpleIntInput = widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ? double.parse(quantityController.text.replaceAll(',', '')) : int.parse(quantityController.text.replaceAll(',', ''));
                                                    });
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          // quantity input text field
                                          Expanded(
                                            flex: 4,
                                            child: SizedBox(
                                              width: isLandscapeOrien() ? 273 : constraints.maxWidth / 3,
                                              child: TextField(
                                                autofocus: widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ? true : false,
                                                controller: quantityController,
                                                keyboardType: TextInputType.number,
                                                inputFormatters: widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ? <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))]
                                                    : <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                                                textAlign: TextAlign.center,
                                                decoration: InputDecoration(
                                                  focusedBorder: OutlineInputBorder(
                                                    borderSide: BorderSide(color: color.backgroundColor),
                                                  ),
                                                ),
                                                onChanged: (value) {
                                                  if(value != ''){
                                                    setState(() => simpleIntInput = widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ? double.parse(value.replaceAll(',', '')): int.parse(value.replaceAll(',', '')));
                                                  } else {
                                                    simpleIntInput = 0;
                                                  }
                                                },
                                                onSubmitted: (value) => _onSubmitted(value, color),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          // quantity input add button
                                          Expanded(
                                            flex: 1,
                                            child: Container(
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
                                                      Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('product_variant_sold_out'));
                                                    }
                                                  }
                                                },
                                              ),
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
                                            AppLocalizations.of(context)!.translate('remark'),
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
                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: SizedBox(
                                  width: isLandscapeOrien() ? MediaQuery.of(context).size.width / 2.5 : MediaQuery.of(context).size.width / 3,
                                  height: isLandscapeOrien() ? MediaQuery.of(context).size.height / 10 : MediaQuery.of(context).size.height / 20,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: color.backgroundColor),
                                    onPressed: isButtonDisabled ? null : () {
                                      // Disable the button after it has been pressed
                                      setState(() {
                                        isButtonDisabled = true;
                                      });
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('${AppLocalizations.of(context)?.translate('close')}'),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                flex: 1,
                                child: SizedBox(
                                  width: isLandscapeOrien() ? MediaQuery.of(context).size.width / 2.5 : MediaQuery.of(context).size.width / 3,
                                  height: isLandscapeOrien() ? MediaQuery.of(context).size.height / 10 : MediaQuery.of(context).size.height / 20,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: color.buttonColor,
                                    ),
                                    onPressed: isButtonDisabled || isAddButtonDisabled ? null : () {
                                      if((priceController.text.isEmpty || priceController.text.trim().isEmpty) || (nameController.text.isEmpty || nameController.text.trim().isEmpty)){
                                        Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('custom_field_required'));
                                      } else {
                                        _productStockStatusAction(color);
                                      }
                                    },
                                    child: Text('${AppLocalizations.of(context)?.translate('add')}'),
                                  ),
                                ),
                              ),
                            ],
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

  String? getErrorText(String textInController){
    if(textInController.isEmpty || textInController.trim().isEmpty){
      return "${AppLocalizations.of(context)?.translate('product_name_empty')}";
    } else {
      return null;
    }
  }

  String? getPriceErrorText(String textInController){
    if(textInController.isEmpty || textInController.trim().isEmpty){
      return "${AppLocalizations.of(context)?.translate('product_price_empty')}";
    } else {
      return null;
    }
  }

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

  void getBranchLinkProductId(Product product){
    if(branchLinkProductList.isNotEmpty){
      if (product.has_variant == 0) {
        BranchLinkProduct? branchLinkProduct = branchLinkProductList.firstWhere((item) => item.product_sqlite_id == product.product_sqlite_id.toString());
        this.branchLinkProduct = branchLinkProduct;
      } else {
        String productVariantId = getProductVariant(product.product_sqlite_id.toString());
        BranchLinkProduct? branchLinkProduct =
        branchLinkProductList.firstWhereOrNull((item) => item.product_sqlite_id == product.product_sqlite_id.toString() && item.product_variant_sqlite_id == productVariantId);
        this.branchLinkProduct = branchLinkProduct;
      }
    }
  }

  void _productStockStatusAction(ThemeColor color){
    print("_productStockStatusAction called");
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
          if(appSetting.table_order == 2) {
            if (simpleIntInput > 0) {
              if (cart.selectedTableIndex != '') {
                // Disable the button after it has been pressed
                setState(() {
                  isButtonDisabled = true;
                });
                addToCart(cart);
                Navigator.of(context).pop();
              } else {
                // openChooseTableDialog(cart);
                enterTableNumberDialog(cart, context, color);
              }
            } else {
              Fluttertoast.showToast(
                  backgroundColor: Color(0xFFFF0000), msg: "Invalid qty input");
            }
          } else if(appSetting.table_order != 0) {
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
  }

  Future<void> enterTableNumberDialog(CartModel cart, BuildContext context, ThemeColor color) async {
    TextEditingController tableController = TextEditingController();
    bool isButtonDisabled = true;
    if(cart.selectedTableIndex != ''){
      tableController.text = cart.selectedTableIndex;
      isButtonDisabled = false;
    }

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.translate('table_mode_custom_note')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      height: 75,
                      width: 350,
                      child: TextField(
                        autofocus: true,
                        controller: tableController,
                        keyboardType: TextInputType.text,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            return newValue.copyWith(
                              text: newValue.text.toUpperCase(),
                              selection: newValue.selection,
                            );
                          }),
                        ],
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          errorText: tableController.text.isEmpty ? AppLocalizations.of(context)!.translate('enter_table_number') : null,
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: color.backgroundColor),
                          ),
                          hintText: AppLocalizations.of(context)!.translate('enter_table_number'),
                        ),
                        onChanged: (value) {
                          setState(() {
                            tableController.text = value.replaceFirst(RegExp(r'^0+'), '');
                            tableController.selection = TextSelection.fromPosition(
                              TextPosition(offset: tableController.text.length),
                            );
                            isButtonDisabled = tableController.text.isEmpty;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color.backgroundColor,
                          ),
                          child: Text(AppLocalizations.of(context)!.translate('close'), style: TextStyle(color: Colors.white)),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color.buttonColor,
                          ),
                          child: Text(AppLocalizations.of(context)!.translate('ok'), style: TextStyle(color: Colors.white)),
                          onPressed: isButtonDisabled
                              ? null
                              : () {
                            cart.selectedTableIndex = tableController.text;
                            Navigator.of(context).pop(tableController.text);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  _onSubmitted(String value, ThemeColor color) {
    _productStockStatusAction(color);
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
      if (branchLinkProduct != null) {
        switch(branchLinkProduct!.stock_type){
          case '1' :{
            if (int.parse(branchLinkProduct!.daily_limit!) > 0 && simpleIntInput <= int.parse(branchLinkProduct!.daily_limit!)) {
              num stockLeft = int.parse(branchLinkProduct!.daily_limit!) - checkCartProductQuantity(cart, branchLinkProduct!);
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
            if (int.parse(branchLinkProduct!.stock_quantity!) > 0 && simpleIntInput <= int.parse(branchLinkProduct!.stock_quantity!)) {
              num stockLeft = int.parse(branchLinkProduct!.stock_quantity!) - checkCartProductQuantity(cart, branchLinkProduct!);
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
        stockStatus = 1;
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
                productVariantLocalId = data.product_variant_sqlite_id.toString();
                break;
              }
            } else if (variant2 == '') {
              variant2 = "$variant | ${group.child![i].name!}";
              if (variantGroup.length == 2) {
                ProductVariant data = productVariantList.firstWhere((item) => item.product_sqlite_id == productLocalId && item.variant_name == variant2);
                productVariantLocalId = data.product_variant_sqlite_id.toString();
                break;
              }
            } else if (variant3 == '') {
              variant3 = "$variant2 | ${group.child![i].name!}";
              if (variantGroup.length == 3) {
                ProductVariant data = productVariantList.firstWhere((item) => item.product_sqlite_id == productLocalId && item.variant_name == variant3);
                productVariantLocalId = data.product_variant_sqlite_id.toString();
                break;
              }
            }
          }
        }
      }
      return productVariantLocalId;
    } catch (error) {
      print('get product variant error: $error');
      return;
    }
  }

  double getTotalCheckedModItem(){
    double totalModPrice = 0.0;
    if(checkedModItem.isNotEmpty){
      for(int i = 0; i < checkedModItem.length; i++){
        String currentModItemId = checkedModItem[i].mod_item_id.toString();
        BranchLinkModifier branchLinkModifier = branchLinkModifierList.firstWhere((item) => item.mod_item_id == currentModItemId);
        totalModPrice += double.parse(branchLinkModifier.price!);
      }
    }
    return totalModPrice;
  }

  void getProductPrice(String? productLocalId){
    double totalBasePrice = 0.0;
    try {
      if(branchLinkProduct != null){
        if(widget.productDetail!.unit == 'each_c'){


          if(!customPriceModified) {
            if(branchLinkProduct != null){
              priceController = TextEditingController(text: int.tryParse(branchLinkProduct!.price!) != 0 ? branchLinkProduct!.price! : '');
            }
          }
          basePrice = priceController.text.isNotEmpty ? priceController.text : '0';

        } else {
          basePrice = branchLinkProduct!.price!;
        }
        totalBasePrice = double.parse(basePrice) + getTotalCheckedModItem();
        finalPrice = totalBasePrice.toStringAsFixed(2);
      } else {
        finalPrice = '0.00';
      }
    } catch (error) {
      print('Get product base price error $error');
      finalPrice = '0.00';
      clientAction.openReconnectDialog(action: '2', param: '', callback: decodeData, disableQuickConnect: true);
    }
    dialogPrice = finalPrice;
  }

  void getProductDialogStock(Product product){
    if (branchLinkProduct != null) {
      switch(branchLinkProduct!.stock_type){
        case '1': {
          dialogStock = branchLinkProduct!.daily_limit.toString();
        }break;
        case '2': {
          dialogStock = branchLinkProduct!.stock_quantity.toString();
        }break;
        default:{
          dialogStock = '';
        }
      }
    } else {
      dialogStock = '0';
    }
  }

  compareCartProductModifier({required List<ModifierItem> cartProductModifier}){
    return checkSame(cartProductModifier, checkedModItem);
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
      if(comparedList.length == checkedModItem.length){
        same = true;
      } else {
        same = false;
      }
    }
    return same;
  }

  quantityStack({required cartProductItem cartItem, required cartProductItem newAddItem}){
    num value;
    try{
      if(cartItem.unit != 'each' && cartItem.unit != 'each_c'){
        value = num.parse((cartItem.quantity! + newAddItem.quantity!).toStringAsFixed(2));
      } else {
        value = cartItem.quantity! + newAddItem.quantity!;
      }
    }catch(e){
      print("quantity stack error: $e");
      // FLog.error(
      //   className: "product_order_dialog",
      //   text: "quantity stack error",
      //   exception: e,
      // );
      value = cartItem.quantity! + newAddItem.quantity!;
    }
    return value;
  }

  String getProductVariantName(){
    List<String?> variant = [];
    String result = '';
    var length = variantGroup.length;
    for (int i = 0; i < length; i++) {
      VariantGroup group = variantGroup[i];
      for (int j = 0; j < group.child!.length; j++) {
        if (group.child![j].isSelected!) {
          variant.add(group.child![j].name!);
          result = variant.toString().replaceAll('[', '').replaceAll(']', '').replaceAll(",", " |");
        }
      }
    }
    return result;
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
        branch_link_product_id: branchLinkProduct!.branch_link_product_id,
        branch_link_product_sqlite_id: branchLinkProduct!.branch_link_product_sqlite_id.toString(),
        product_name: productName,
        category_id: widget.productDetail!.category_id!,
        category_name: categories != null ? categories!.name : '',
        price: dialogPrice,
        quantity: simpleIntInput,
        promo: {},
        charge: {},
        tax: {},
        checkedModifierLength: checkedModifierLength,
        checkedModifierItem: checkedModItem,
        productVariantName: getProductVariantName(),
        remark: remarkController.text,
        status: 0,
        category_sqlite_id: widget.productDetail!.category_sqlite_id,
        base_price: basePrice,
        refColor: Colors.black,
        unit: widget.productDetail!.unit!,
        per_quantity_unit: widget.productDetail!.unit! != 'each' && widget.productDetail!.unit != 'each_c' ? widget.productDetail!.per_quantity_unit! : '',
        allow_ticket: widget.productDetail!.allow_ticket,
        ticket_count: widget.productDetail!.ticket_count,
        ticket_exp: widget.productDetail!.ticket_exp,
        product_sku: widget.productDetail!.SKU,
    );
    List<cartProductItem> item = [];
    if(cart.cartNotifierItem.isEmpty){
      cart.addItem(value);
    } else {
      for(int k = 0; k < cart.cartNotifierItem.length; k++){
        if(cart.cartNotifierItem[k].branch_link_product_sqlite_id == value.branch_link_product_sqlite_id
            && value.product_name == cart.cartNotifierItem[k].product_name
            && value.price == cart.cartNotifierItem[k].price
            && value.remark == cart.cartNotifierItem[k].remark
            && value.checkedModifierLength == cart.cartNotifierItem[k].checkedModifierLength
            && cart.cartNotifierItem[k].status == 0) {
          item.add(cart.cartNotifierItem[k]);
        }
      }
      while(item.length > 1){
        for(int i = 0 ; i < item.length; i++){
          bool status = compareCartProductModifier(cartProductModifier: item[i].checkedModifierItem!);
          if(status == false){
            item.remove(item[i]);
          }
        }
      }
      if(item.length == 1){
        if(item.first.checkedModifierLength == 0){
          item.first.quantity = quantityStack(cartItem: item.first, newAddItem: value);
        } else {
          bool status = compareCartProductModifier(cartProductModifier: item.first.checkedModifierItem!);
          if(status == false){
            cart.addItem(value);
          } else{
            item.first.quantity = quantityStack(cartItem: item.first, newAddItem: value);
          }
        }
      } else {
        cart.addItem(value);
      }
    }
    cart.resetCount();
    decodeAction.cartProductController.sink.add(cart);
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
