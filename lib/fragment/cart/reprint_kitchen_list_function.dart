import 'package:optimy_second_device/notifier/fail_print_notifier.dart';

import '../../object/order_detail.dart';

class ReprintKitchenListFunction {

  Map<String, List<OrderDetail>> groupOrder() {
    Map<String, List<OrderDetail>> groupedOrderDetails = {};
    for (OrderDetail orderItem in FailPrintModel.instance.failPrintOrderDetails) {
      String cardID = '';
      // if(getOrderNumber(orderItem) != '') {
      //   cardID = getOrderNumber(orderItem);
      // } else
      if(getTableNumber(orderItem) != '') {
        cardID = getTableNumber(orderItem);
      }
      else {
        cardID = orderItem.order_cache_key.toString().replaceAll("[", "").replaceAll("]", "");
      }
      if (groupedOrderDetails.containsKey(cardID)) {
        groupedOrderDetails[cardID]!.add(orderItem);
      } else {
        groupedOrderDetails[cardID] = [orderItem];
      }
    }
    return groupedOrderDetails;
  }

  checkChange({bool? value}){
    if(value == false){
      unselectAllOrderDetail();
      FailPrintModel.instance.setAllAsUnselected();
      //disableButton();
    } else {
      resetOrderDetail();
      FailPrintModel.instance.setAllAsSelected();
      //enableButton();
    }
  }

  unselectAllOrderDetail(){
    for(int i = 0; i < FailPrintModel.instance.failPrintOrderDetails.length; i++){
      FailPrintModel.instance.failPrintOrderDetails[i].isSelected = false;
    }
    FailPrintModel.instance.clearAllSelectedOrder();
  }

  resetOrderDetail(){
    for(int i = 0; i < FailPrintModel.instance.failPrintOrderDetails.length; i++){
      FailPrintModel.instance.failPrintOrderDetails[i].isSelected = true;
    }
  }

  checkIsLastItem(items, String cardID){
    List<OrderDetail> selectedList = items.where((element) => element.isSelected == true).toList();
    if(selectedList.isEmpty){
      FailPrintModel.instance.selectedOrder.remove(cardID);
      FailPrintModel.instance.setAllAsUnselected();
    }
  }

  checkIsLastOrder(){
    List<OrderDetail> selectedList = FailPrintModel.instance.failPrintOrderDetails.where((element) => element.isSelected == true).toList();
    if(selectedList.isEmpty){
      FailPrintModel.instance.setAllAsUnselected();
      //isSelectAll = false;
      //disableButton();
    } else if (selectedList.length != FailPrintModel.instance.failPrintOrderDetails.length) {
      FailPrintModel.instance.setAllAsUnselected();
      //isSelectAll = false;
      //enableButton();
    } else {
      FailPrintModel.instance.setAllAsSelected();
      //isSelectAll = true;
      //enableButton();
    }
  }

  checkAllOrderItem(bool value, items){
    print("checkAllOrderItem: ${value}");
    if(value == false){
      for(int i = 0; i < items.length; i++){
        items[i].isSelected = false;
        // setState(() {
        //   items[i].isSelected = false;
        //   checkIsLastOrder();
        // });
      }
      //disableButton();
    } else {
      for(int i = 0; i < items.length; i++){
        items[i].isSelected = true;
        // setState(() {
        //   items[i].isSelected = true;
        // });
      }
      //enableButton();
    }
    checkIsLastOrder();
  }

  String getProductVariant(OrderDetail orderDetail){
    String result = '';
    try{
      if(orderDetail.product_variant_name != ''){
        result = "(${orderDetail.product_variant_name})";
      }
    }catch(e){
      result = '';
    }
    return result;
  }

  String getModifier(OrderDetail orderDetail){
    String result = '';
    List<String?> modifier = [];
    try{
      if(orderDetail.orderModifierDetail!.isNotEmpty){
        for(int i = 0; i < orderDetail.orderModifierDetail!.length; i++){
          modifier.add('${orderDetail.orderModifierDetail![i].mod_name!}\n');
          result = modifier
              .toString()
              .replaceAll('[', '')
              .replaceAll(']', '')
              .replaceAll(',', '+')
              .replaceFirst('', '+ ');
        }
      }
    }catch(e){
      result = '';
    }
    return result;
  }

  String getRemark(OrderDetail orderDetail){
    String result = '';
    try{
      if(orderDetail.remark != ''){
        result = "**${orderDetail.remark}";
      }
    }catch(e){
      result = '';
    }
    return result;
  }

  String getOrderNumber(OrderDetail orderDetail){
    String orderNumber = "";
    try{
      orderNumber = orderDetail.orderQueue.toString().replaceAll("[", "").replaceAll("]", "");
    }catch(e){
      orderNumber = "-";
    }
    return orderNumber;
  }

  String getTableNumber(OrderDetail orderDetail){
    print("order detail table number: ${orderDetail.tableNumber}");
    String tableNumber = "";
    try{
      tableNumber = orderDetail.tableNumber.toString().replaceAll("[", "").replaceAll("]", "");
    }catch(e){
      tableNumber = "-";
    }
    return tableNumber;
  }
}