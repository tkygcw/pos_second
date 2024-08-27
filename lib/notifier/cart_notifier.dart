import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:optimy_second_device/main.dart';

import '../object/branch_link_dining_option.dart';
import '../object/cart_payment.dart';
import '../object/cart_product.dart';
import '../object/promotion.dart';
import '../object/table.dart';

class CartModel extends ChangeNotifier {
  List<cartProductItem> cartNotifierItem = [];
  List<cartPaymentDetail> cartNotifierPayment  = [];
  List<Promotion> autoPromotion = [];
  Promotion? selectedPromotion ;
  List<PosTable> selectedTable = [];
  String selectedOption = 'Dine in';
  String selectedOptionId = '';
  String? subtotal;
  bool isInit = false;
  int myCount = 0;
  bool isChange = false;

  Map<String, Object?> toJson() => {
    'selectedTable': this.selectedTable,
    'cartNotifierItem': this.cartNotifierItem,
    'selectedOption': this.selectedOption,
    'selectedOptionId': this.selectedOptionId,
    'subtotal': this.subtotal
  };

  List<int> getSelectedTableIdList(){
    List<int> idList = selectedTable.map((e) => e.table_sqlite_id!).toList();
    return idList;
    // for(int i = 0; i < selectedTable.length; i++){
    //   idList.add(selectedTable[i].table_sqlite_id!);
    // }
    // return idList;
  }

  void initBranchLinkDiningOption() {
    List<BranchLinkDining> data = decodeAction.decodedBranchLinkDiningList!;
    if (data.length == 3) {
      selectedOption = 'Dine in';
    } else {
      selectedOption = "Take Away";
    }
    selectedOptionId = data.firstWhere((e) => e.name == selectedOption).dining_id!;
  }

  void initialLoad() {
    removeAllTable();
    removeAllCartItem();
    removePromotion();
    removePaymentDetail();
    initBranchLinkDiningOption();
    notifyListeners();
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
    myCount = 0;
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
    cartNotifierPayment.clear();
    notifyListeners();
  }

  void addPaymentDetail(cartPaymentDetail object){
    cartNotifierPayment.add(object);
    notifyListeners();
  }

  void addItem(cartProductItem object, {bool? notifyListener}) {
    cartNotifierItem.add(object);
    if(notifyListener == null){
      notifyListeners();
    }
  }

  void removeItem(cartProductItem object) {
    cartNotifierItem.remove(object);
    notifyListeners();
  }

  void removeSpecificItem({String? orderCacheLocalId}){
    cartNotifierItem.removeWhere((item) => item.order_cache_sqlite_id == orderCacheLocalId);
    /*for(int i = 0; i < cartNotifierItem.length; i++){
      print("pass order cache id: ${object.order_cache_sqlite_id}");
      print("list order cache id: ${cartNotifierItem[i].order_cache_sqlite_id}");
      if(object.order_cache_sqlite_id == cartNotifierItem[i].order_cache_sqlite_id){
        cartNotifierItem.removeAt(i);
        break;
      }
    }*/
    notifyListeners();
  }

  void removeAllCartItem(){
    cartNotifierItem.clear();
    notifyListeners();
  }

  void removePartialCartItem(){
    List<cartProductItem> removeItem = [];
    for(int j = 0; j < cartNotifierItem.length; j++){
      if(cartNotifierItem[j].status == 0){
        removeItem.add(cartNotifierItem[j]);
      }
    }
    cartNotifierItem.removeWhere((element) => removeItem.contains(element));
    notifyListeners();
  }

  void addTable(PosTable posTable){
    selectedTable.add(posTable);
    notifyListeners();
  }

  void addAllTable(List<PosTable> tableList){
    selectedTable.addAll(tableList);
    notifyListeners();
  }

  void removeAllTable(){
    selectedTable.clear();
    notifyListeners();
  }

  void removeSpecificTable(PosTable posTable){
    for(int i= 0; i < selectedTable.length; i++){
      if(posTable.table_id == selectedTable[i].table_id){
        selectedTable.removeAt(i);
        break;
      }
    }
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