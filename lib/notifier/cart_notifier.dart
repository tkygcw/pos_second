import 'package:collection/collection.dart';
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
  static final CartModel instance = CartModel._init();
  final PromotionFunction _promoFunc = PromotionFunction();
  CartPaymentDetail? cartNotifierPayment;
  List<PosTable> _selectedTable = [];
  String selectedTableIndex = '';
  List<Promotion> _autoPromotion = [];
  Promotion? _selectedPromotion ;
  String selectedOption = 'Dine in';
  String selectedOptionId = '';
  bool isInit = false;
  bool isChange = false;
  List<cartProductItem> _cartNotifierItem = [];
  List<OrderCache> _currentOrderCache = [];
  int _cartScrollDown = 0;
  Map<String, double> _groupCategoryPrice = {};

  List<Promotion> get autoPromotion => _autoPromotion;
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

  void getAutoApplyCategorizedPromotions() {
    List<Promotion> promotionList = decodeAction.decodedBranchPromotionList!.where((e) => e.auto_apply == '1' && e.specific_category != '0').toList();
    _autoPromotion = promotionList.where((promotion) {
      if (cartNotifierItem.isEmpty) return false;
      promotion.promoRate = promotion.type == 0 ?  '${promotion.amount!}%' : 'RM${promotion.amount!}';
      //compare with cart item category
      bool status =  _promoFunc.isPromotionAvailable(promotion, CartModel(cartNotifierItem: cartNotifierItem));
      if(status) {
        promotion.promoAmount = discountForPromotion(promotion);
      }
      return status;
    }).toList();
  }

  void getManualApplyCategorizedPromotions() {
    if(_selectedPromotion != null && _selectedPromotion!.specific_category != '0'){
      _selectedPromotion!.promoRate =  _selectedPromotion!.type == 0 ?
      '${_selectedPromotion!.amount!}%' : 'RM${_selectedPromotion!.amount!}';
      _selectedPromotion!.promoAmount = discountForPromotion(_selectedPromotion!);
    }
  }

  void getAutoApplyNonCategorizedPromotions() {
    List<Promotion> promotionList = decodeAction.decodedBranchPromotionList!.where((e) => e.auto_apply == '1' && e.specific_category == '0').toList();
    _autoPromotion.addAll(promotionList.where((promotion) {
      if (cartNotifierItem.isEmpty) return false;
      promotion.promoRate =  promotion.type == 0 ? '${promotion.amount!}%' : 'RM${promotion.amount!}';
      if (promotion.all_day == '1' && promotion.all_time == '1') {
        promotion.promoAmount = discountForPromotion(promotion);
        return true;
      } else if (promotion.all_day == '0' && promotion.all_time == '1'){
        //check both promo date
        bool status =  _promoFunc.isPromotionAvailable(promotion, CartModel(cartNotifierItem: cartNotifierItem));
        if(status) {
          promotion.promoAmount = discountForPromotion(promotion);
        }
        return status;
      } else if (promotion.all_day == '1' && promotion.all_time == '0') {
        bool status =  _promoFunc.isPromotionAvailable(promotion, CartModel(cartNotifierItem: cartNotifierItem));
        if(status) {
          promotion.promoAmount = discountForPromotion(promotion);
        }
        return status;
      } else {
        return false;
      }
    }).toList());
  }

  void getManualApplyNonCategorizedPromotions() {
    if(_selectedPromotion != null && _selectedPromotion!.specific_category == '0'){
      _selectedPromotion!.promoRate =  _selectedPromotion!.type == 0 ?
      '${_selectedPromotion!.amount!}%' : 'RM${_selectedPromotion!.amount!}';
      _selectedPromotion!.promoAmount = discountForPromotion(_selectedPromotion!);
    }
  }

  void getAllApplicablePromotion(){
    groupCategoryPrice();
    getAutoApplyCategorizedPromotions();
    getManualApplyCategorizedPromotions();
    getAutoApplyNonCategorizedPromotions();
    getManualApplyNonCategorizedPromotions();
  }

  //group category total price
  void groupCategoryPrice(){
    var groupedOrders = groupBy(_cartNotifierItem, (item) => item.category_id!);
    Map<String, double> totalByCategory = {};
    groupedOrders.forEach((category, cartItem) {
      totalByCategory[category] = cartItem.fold(0, (sum, item) => sum + (double.parse(item.price!) * item.quantity!));
    });
    _groupCategoryPrice = totalByCategory;
  }

  void updateGroupCategoryPrice(double remainingPromoAmount){
    double remainingPromo = remainingPromoAmount;
    for (var item in _groupCategoryPrice.entries) {
      if (item.value >= remainingPromo) {
        _groupCategoryPrice[item.key] = item.value - remainingPromo;
        remainingPromo = 0;
      } else {
        remainingPromo -= item.value;
        _groupCategoryPrice[item.key] = 0;
      }
    }
  }

  // Calculate the discount for each promotion
  double discountForPromotion(Promotion promo) {
    var totalDiscount = 0.0;
    double categoryTotalPrice = 0;
    try{
      if (promo.specific_category == '1') {
        categoryTotalPrice = _groupCategoryPrice[promo.category_id!]!;
        if (promo.type == 1) {
          if(categoryTotalPrice <= 0) {
            totalDiscount = 0;
          } else if(double.parse(promo.amount!) > categoryTotalPrice) {
            totalDiscount = categoryTotalPrice;
          } else {
            totalDiscount = double.parse(promo.amount!);
          }
        } else {
          totalDiscount = categoryTotalPrice * (double.parse(promo.amount!) / 100);
        }
        updateGroupCategoryPrice(totalDiscount);
      } else if (promo.specific_category == '2') {
        //multiple category promo
        for (var item in _groupCategoryPrice.entries) {
          if (promo.multiple_category!.any((category) => category['category_id'].toString() == item.key)) {
            categoryTotalPrice += item.value;
          }
        }
        if (promo.type == 1) {
          // Fixed amount discount
          totalDiscount = (double.parse(promo.amount!));
        } else {
          // Percentage discount
          totalDiscount += categoryTotalPrice * (double.parse(promo.amount!) / 100);
        }
        updateGroupCategoryPrice(totalDiscount);
      } else {
        //non specific category promotion (specific_category == 0)
        double totalAmount = _groupCategoryPrice.values.reduce((a, b) => a + b);
        if(promo.auto_apply == '1'){
          if (promo.type == 1) {
            if(double.parse(promo.amount!) > totalAmount) {
              totalDiscount = totalAmount;
            } else {
              totalDiscount += double.parse(promo.amount!);
            }
          } else {
            if(totalAmount <= 0) {
              totalDiscount += 0;
            } else {
              totalDiscount += totalAmount * (double.parse(promo.amount!) / 100);
            }
          }
          updateGroupCategoryPrice(totalDiscount);
        } else {
          //manual apply all category promotion
          if (promo.type == 0) {
            if(totalAmount <= 0) {
              totalDiscount += 0;
            } else {
              totalDiscount = double.parse((totalAmount * (double.parse(promo.amount!) / 100)).toStringAsFixed(2));
            }
          } else {
            if(double.parse(promo.amount!) > totalAmount) {
              totalDiscount = totalAmount;
            } else {
              totalDiscount = double.parse(promo.amount!);
            }
          }
          updateGroupCategoryPrice(totalDiscount);
          // if (promo.type == 0) {
          //   // Percentage discount
          //   totalDiscount += subtotal * (double.parse(promo.amount!) / 100);
          // } else {
          //   // Fixed amount discount
          //   totalDiscount += double.parse(promo.amount!);
          // }
        }
      }
    }catch(e){
      totalDiscount = 0.0;
    }
    return totalDiscount;
  }

  // Total discount from all auto apply promotions
  double get totalAutoPromotionDiscount {
    return _autoPromotion.fold(0, (sum, promo) => sum + promo.promoAmount!);
  }

  // Total discount from selected promotions
  double get totalSelectedPromotionDiscount {
    double totalDiscount = 0.0;
    if(_selectedPromotion != null){
      totalDiscount = _selectedPromotion!.promoAmount!;
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

  CartModel._init();

  CartModel({
    List<PosTable>? selectedTable,
    String? selectedTableIndex,
    List<cartProductItem>? cartNotifierItem,
    String? selectedOption,
    String? selectedOptionId
  }){
    this._selectedTable = selectedTable ?? [];
    this.selectedTableIndex = selectedTableIndex ?? '';
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
    if (data.any((item) => item.name == 'Dine in')) {
      selectedOption = 'Dine in';
    } else {
      selectedOption = "Take Away";
    }
    selectedOptionId = data.firstWhere((e) => e.name == selectedOption).dining_id!;
  }

  void initialLoad({bool? notify = true}) {
    removeSelectedTableIndex();
    _currentOrderCache.clear();
    _selectedTable.clear();
    _cartNotifierItem.clear();
    _autoPromotion.clear();
    _selectedPromotion = null;
    cartNotifierPayment = null;
    initBranchLinkDiningOption();
    if(notify == true){
      notifyListeners();
    }
  }

  void notDineInInitLoad(){
    removeSelectedTableIndex();
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
    getAllApplicablePromotion();
    if(notifyListener == null){
      notifyListeners();
    }
  }

  void addAllItem(List<cartProductItem> object, {bool? notifyListener}) {
    _cartNotifierItem.addAll(object);
    getAllApplicablePromotion();
    if(notifyListener == null){
      notifyListeners();
    }
  }

  void overrideItem({required List<cartProductItem> cartItem, bool? notify = true}) {
    List<cartProductItem> notPlacedItem = _cartNotifierItem.where((e) => e.status == 0).toList();
    _cartNotifierItem = cartItem;
    _cartNotifierItem.addAll(notPlacedItem);
    _cartScrollDown = 0;
    getAllApplicablePromotion();
    if(notify = true){
      notifyListeners();
    }
  }

  void removeItem(cartProductItem object) {
    _cartNotifierItem.remove(object);
    getAllApplicablePromotion();
    notifyListeners();
  }

  void removeSpecificItem(String? table_use_key) {
    _cartNotifierItem.removeWhere((e) => e.table_use_key == table_use_key);
    getAllApplicablePromotion();
    notifyListeners();
  }

  void removeSpecificBatchItem(String? batch) {
    _cartNotifierItem.removeWhere((e) => e.first_cache_batch == batch);
    getAllApplicablePromotion();
    notifyListeners();
  }

  void removeAllCartItem(){
    _cartNotifierItem.clear();
    getAllApplicablePromotion();
    notifyListeners();
  }

  void removePartialCartItem(){
    _cartNotifierItem.removeWhere((item) => item.status == 0);
    getAllApplicablePromotion();
    notifyListeners();
  }

  bool containNewItem(){
    List<int?> itemStatus = _cartNotifierItem.map((e) => e.status).toList();
    return itemStatus.contains(0);
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

  void removeSelectedTableIndex({bool? notify = true}) {
    selectedTableIndex = '';
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
    _selectedPromotion = promo;
    getAllApplicablePromotion();
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

  void addAllCurrentOrderCache(List<OrderCache> value){
    _currentOrderCache.addAll(value);
  }

  void removeSpecificCurrentOrderCacheWithBatch(String? batch) {
    _currentOrderCache.removeWhere((e) => e.batch_id == batch);
    notifyListeners();
  }

  void updateCartItemQuantity(int index, {bool? removeItem}){
    if(removeItem != null && removeItem == true){
      if (_cartNotifierItem[index].unit != 'each' && _cartNotifierItem[index].unit != 'each_c') {
        _cartNotifierItem[index].quantity = (_cartNotifierItem[index].quantity! - 1).ceilToDouble();
      } else {
        _cartNotifierItem[index].quantity = (_cartNotifierItem[index].quantity! - 1);
      }
    } else {
      _cartNotifierItem[index].quantity = cartNotifierItem[index].quantity! + 1;
    }
    getAllApplicablePromotion();
    notifyListeners();
  }

}