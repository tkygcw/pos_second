import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:optimy_second_device/main.dart';

import '../object/branch_link_dining_option.dart';
import '../object/cart_payment.dart';
import '../object/cart_product.dart';
import '../object/promotion.dart';
import '../object/table.dart';

class CartModel extends ChangeNotifier {
  CartPaymentDetail? cartNotifierPayment;
  List<Promotion> autoPromotion = [];
  Promotion? selectedPromotion ;
  List<PosTable> _selectedTable = [];

  List<PosTable> get selectedTable => _selectedTable;

  set setSelectedTable(List<PosTable> value) {
    _selectedTable = value;
  }


  String selectedOption = 'Dine in';
  String selectedOptionId = '';
  String? subtotal;
  bool isInit = false;
  bool isChange = false;
  List<cartProductItem> _cartNotifierItem = [];
  int _cartScrollDown = 0;

  List<cartProductItem> get cartNotifierItem => _cartNotifierItem;

  int get cartScrollDown => _cartScrollDown;

  set setCartNotifierItem(List<cartProductItem> value) {
    _cartNotifierItem = value;
  }

  set setCartScrollDown(int value) {
    _cartScrollDown = value;
  }

  CartModel({
    List<PosTable>? selectedTable,
    List<cartProductItem>? cartNotifierItem,
    String? selectedOption,
    String? selectedOptionId,
    String? subtotal
  }){
    this._selectedTable = selectedTable ?? [];
    this._cartNotifierItem = cartNotifierItem ?? [];
    this.selectedOption = selectedOption ?? 'Dine in';
    this.selectedOptionId = selectedOptionId ?? '';
    this.subtotal = subtotal ?? '';
  }

  CartModel.addOrderCopy(CartModel cart)
      : this._selectedTable = cart.selectedTable,
        this._cartNotifierItem = cart.cartNotifierItem.where((e) => e.status == 0).toList(),
        this.selectedOption = cart.selectedOption,
        this.selectedOptionId = cart.selectedOptionId,
        this.subtotal = cart.subtotal;

  Map<String, Object?> toJson() => {
    'selectedTable': this._selectedTable,
    'cartNotifierItem': this._cartNotifierItem,
    'selectedOption': this.selectedOption,
    'selectedOptionId': this.selectedOptionId,
    'subtotal': this.subtotal
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
    selectedPromotion = null;
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
    selectedPromotion = promo;
    notifyListeners();
  }

  void removePromotion(){
    selectedPromotion = null;
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