import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:optimy_second_device/fragment/cart/function/promotion_function.dart';
import 'package:optimy_second_device/main.dart';
import 'package:optimy_second_device/object/tax_link_dining.dart';
import 'package:optimy_second_device/utils/Utils.dart';

import '../object/branch_link_dining_option.dart';
import '../object/cart_payment.dart';
import '../object/cart_product.dart';
import '../object/order_cache.dart';
import '../object/promotion.dart';
import '../object/table.dart';

class CartModel extends ChangeNotifier {
  CartPaymentDetail? cartNotifierPayment;
  List<Promotion> autoPromotion = [];
  List<PosTable> _selectedTable = [];
  Promotion? _selectedPromotion ;
  String selectedOption = 'Dine in';
  String selectedOptionId = '';
  bool isInit = false;
  bool isChange = false;
  List<cartProductItem> _cartNotifierItem = [];
  List<OrderCache> _currentOrderCache = [];

  int _cartScrollDown = 0;

  Promotion? get selectedPromotion => _selectedPromotion;
  List<PosTable> get selectedTable => _selectedTable;
  List<cartProductItem> get cartNotifierItem => _cartNotifierItem;
  int get cartScrollDown => _cartScrollDown;
  List<OrderCache> get currentOrderCache => _currentOrderCache;

  set setCurrentOrderCache(List<OrderCache> value) {
    _currentOrderCache = value;
  }

  set setSelectedTable(List<PosTable> value) {
    _selectedTable = value;
  }

  set setCartNotifierItem(List<cartProductItem> value) {
    _cartNotifierItem = value;
  }

  set setCartScrollDown(int value) {
    _cartScrollDown = value;
  }

  // Calculate subtotal (before discount)
  double get subtotal {
    return cartNotifierItem.fold(0, (total, item) => total + double.parse(item.price!) * item.quantity!);
  }

  List<Promotion> get applicablePromotions {
    final promoFunc = PromotionFunction();
    List<Promotion> promotionList = decodeAction.decodedBranchPromotionList!.where((e) => e.auto_apply == '1').toList();
    return promotionList.where((promotion) {
      if (cartNotifierItem.isEmpty) return false;
      promotion.promoRate =  promotion.type == 0 ?  '${promotion.amount!}%' : 'RM${promotion.amount!}';
      if (promotion.specific_category == '1') {
        //compare with cart item category
        return promoFunc.isPromotionAvailable(promotion, CartModel(cartNotifierItem: cartNotifierItem));
      } else {
        if (promotion.all_day == '1' && promotion.all_time == '1') {
          return true;
        } else if (promotion.all_day == '0' && promotion.all_time == '1'){
          //check both promo date
          return promoFunc.isPromotionAvailable(promotion, CartModel(cartNotifierItem: cartNotifierItem));
        } else if (promotion.all_day == '1' && promotion.all_time == '0') {
          return promoFunc.isPromotionAvailable(promotion, CartModel(cartNotifierItem: cartNotifierItem));
          //check both promo time
        } else {
          return false;
          //check both promo dateTime
        }
      }
    }).toList();
  }

  // Calculate the discount for each promotion
  double discountForPromotion(Promotion promo) {
    var totalDiscount = 0.0;
    try{
      if (promo.specific_category == '1') {
        List<cartProductItem> categorizeItem = cartNotifierItem.where((item) => item.category_id == promo.category_id!).toList();
        for (var item in categorizeItem) {
          if (promo.type == 1) {
            // Fixed amount discount
            totalDiscount += (double.parse(promo.amount!) * item.quantity!);
          } else {
            // Percentage discount
            totalDiscount += (double.parse(item.price!) * item.quantity!) * (double.parse(promo.amount!) / 100);
          }
        }
      } else {
        if(promo.auto_apply == '1'){
          for (var item in cartNotifierItem) {
            if (promo.type == 0) {
              // Percentage discount
              totalDiscount += (double.parse(item.price!) * item.quantity!) * (double.parse(promo.amount!) / 100);
            } else {
              // Fixed amount discount
              totalDiscount += (double.parse(promo.amount!) * item.quantity!);
            }
          }
        } else {
          if (promo.type == 0) {
            // Percentage discount
            totalDiscount += subtotal * (double.parse(promo.amount!) / 100);
          } else {
            // Fixed amount discount
            totalDiscount += double.parse(promo.amount!);
          }
        }
      }
    }catch(e){
      totalDiscount = 0.0;
    }
    return totalDiscount;
  }

  // Total discount from all auto apply promotions
  double get totalAutoPromotionDiscount {
    return applicablePromotions.fold(0, (sum, promo) => sum + discountForPromotion(promo));
  }

  // Total discount from selected promotions
  double get totalSelectedPromotionDiscount {
    var totalDiscount = 0.0;
    if(selectedPromotion != null){
      totalDiscount = discountForPromotion(selectedPromotion!);
    }
    return totalDiscount;
  }

  // Calculate the subtotal after promotion
  double get discountedSubtotal {
    return subtotal - totalAutoPromotionDiscount - totalSelectedPromotionDiscount;
  }

  //get all tax and charges
  List<TaxLinkDining> get applicableTax {
    return decodeAction.decodedTaxLinkDiningList.where((tax) => tax.dining_id == selectedOptionId).toList();
  }

  //calculate the tax/charges amount after promotion
  double taxAmount(TaxLinkDining tax) {
    return discountedSubtotal * (double.parse(tax.tax_rate!) / 100);
  }

  // Total discount from all promotions
  double get totalTaxAmount {
    return applicableTax.fold(0, (sum, tax) => sum + taxAmount(tax));
  }

  // Total before rounding
  double get grossTotal {
    var grossTotal = discountedSubtotal + totalTaxAmount;
    return grossTotal;
  }

  // Total rounding
  double get rounding {
    return Utils.roundToNearestFiveSen(grossTotal) - grossTotal;
  }

  // Final amount
  double get netTotal {
    var netTotal = Utils.roundToNearestFiveSen(grossTotal);
    return double.parse(netTotal.toStringAsFixed(2));
  }

  CartModel({
    List<PosTable>? selectedTable,
    List<cartProductItem>? cartNotifierItem,
    String? selectedOption,
    String? selectedOptionId
  }){
    this._selectedTable = selectedTable ?? [];
    this._cartNotifierItem = cartNotifierItem ?? [];
    this.selectedOption = selectedOption ?? 'Dine in';
    this.selectedOptionId = selectedOptionId ?? '';
  }

  CartModel.addOrderCopy(CartModel cart)
      : this._selectedTable = cart.selectedTable,
        this._cartNotifierItem = cart.cartNotifierItem.where((e) => e.status == 0).toList(),
        this.selectedOption = cart.selectedOption,
        this.selectedOptionId = cart.selectedOptionId;

  Map<String, Object?> toJson() => {
    'selectedTable': this._selectedTable,
    'cartNotifierItem': this._cartNotifierItem,
    'selectedOption': this.selectedOption,
    'selectedOptionId': this.selectedOptionId,
    'subtotal': this.subtotal.toStringAsFixed(2)
  };

  List<int> getSelectedTableIdList(){
    List<int> idList = _selectedTable.map((e) => e.table_sqlite_id!).toList();
    return idList;
    // for(int i = 0; i < selectedTable.length; i++){
    //   idList.add(selectedTable[i].table_sqlite_id!);
    // }
    // return idList;
  }

  void initBranchLinkDiningOption() {
    List<BranchLinkDining> data = decodeAction.decodedBranchLinkDiningList!;
    if(selectedOptionId == '') {
      if (data.length == 3) {
        selectedOption = 'Dine in';
      } else {
        selectedOption = "Take Away";
      }
      selectedOptionId = data.firstWhere((e) => e.name == selectedOption).dining_id!;
    }
  }

  void initialLoad({bool? notify = true}) {
    _selectedTable.clear();
    _cartNotifierItem.clear();
    _selectedPromotion = null;
    cartNotifierPayment = null;
    initBranchLinkDiningOption();
    if(notify == true){
      notifyListeners();
    }
  }

  void notDineInInitLoad(){
    removeAllTable();
    removeAllCartItem();
    removePromotion();
    removePaymentDetail();
    initBranchLinkDiningOption();
    notifyListeners();
  }

  void resetCount(){
    _cartScrollDown = 0;
    notifyListeners();
  }

  void changInit(bool action) {
    isInit = action;
    notifyListeners();
  }

  void setInit(bool action) {
    isInit = action;
  }

  void setSelectedOption(String option){
    selectedOption = option;
    notifyListeners();
  }

  void removePaymentDetail(){
    cartNotifierPayment = null;
    notifyListeners();
  }

  void addPaymentDetail(CartPaymentDetail object){
    cartNotifierPayment = object;
    notifyListeners();
  }

  void addItem(cartProductItem object, {bool? notifyListener}) {
    _cartNotifierItem.add(object);
    if(notifyListener == null){
      notifyListeners();
    }
  }

  void addAllItem(List<cartProductItem> object, {bool? notifyListener}) {
    _cartNotifierItem.addAll(object);
    if(notifyListener == null){
      notifyListeners();
    }
  }

  void overrideItem({required List<cartProductItem> cartItem, bool? notify = true}) {
    List<cartProductItem> notPlacedItem = _cartNotifierItem.where((e) => e.status == 0).toList();
    _cartNotifierItem = cartItem;
    _cartNotifierItem.addAll(notPlacedItem);
    _cartScrollDown = 0;
    if(notify = true){
      notifyListeners();
    }
  }

  void removeItem(cartProductItem object) {
    _cartNotifierItem.remove(object);
    notifyListeners();
  }

  void removeSpecificItem(String? table_use_key) {
    _cartNotifierItem.removeWhere((e) => e.table_use_key == table_use_key);
    notifyListeners();
  }

  void removeAllCartItem(){
    _cartNotifierItem.clear();
    notifyListeners();
  }

  void removePartialCartItem(){
    List<cartProductItem> removeItem = [];
    for(int j = 0; j < _cartNotifierItem.length; j++){
      if(_cartNotifierItem[j].status == 0){
        removeItem.add(_cartNotifierItem[j]);
      }
    }
    _cartNotifierItem.removeWhere((element) => removeItem.contains(element));
    notifyListeners();
  }

  void addTable(PosTable posTable){
    _selectedTable.add(posTable);
    notifyListeners();
  }

  void addAllTable(List<PosTable> tableList){
    _selectedTable.addAll(tableList);
    notifyListeners();
  }

  void overrideSelectedTable(List<PosTable> tableList, {bool? notify = true}){
    _selectedTable = tableList.toList();
    if(notify == true){
      notifyListeners();
    }
  }

  void removeAllTable(){
    _selectedTable.clear();
    notifyListeners();
  }

  void removeSpecificTable(PosTable posTable){
    for(int i= 0; i < _selectedTable.length; i++){
      print("table id: ${posTable.table_id}");
      if(posTable.table_id == _selectedTable[i].table_id){
        _selectedTable.removeAt(i);
        break;
      }
    }
    notifyListeners();
  }

  void removeGroupedTable(PosTable posTable){
    _selectedTable.removeWhere((e) => e.group == posTable.group);
    notifyListeners();
  }

  void addPromotion(Promotion promo){
    promo.promoRate =  promo.type == 0 ?  '${promo.amount!}%' : 'RM${promo.amount!}';
    _selectedPromotion = promo;
    notifyListeners();
  }

  void removePromotion(){
    _selectedPromotion = null;
    notifyListeners();
  }

  void addAutoApplyPromo(Promotion promo){
    autoPromotion.add(promo);
    //notifyListeners();
  }

  void removeAutoPromotion(){
    autoPromotion.clear();
    notifyListeners();
  }

}