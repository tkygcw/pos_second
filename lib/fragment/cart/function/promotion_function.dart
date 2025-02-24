import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:optimy_second_device/notifier/cart_notifier.dart';
import 'package:optimy_second_device/object/promotion.dart';

import '../../../main.dart';

class PromotionFunction {
  List<Promotion> _promotionList = [];

  Future<List<Promotion>> getServerPromotion() async {
    await clientAction.connectRequestPort(action: '18', param: '', callback: _decodeData);
    return _promotionList;
  }

  void _decodeData(response){
    try{
      var json = jsonDecode(clientAction.response!);
      String status = json['status'];
      switch(status){
        case '1': {
          Iterable value1 = json['data']['promotion'];
          _promotionList = List<Promotion>.from(value1.map((json) => Promotion.fromJson(json)));
        }break;
        default: {
          clientAction.openReconnectDialog(action: json['action'], callback: _decodeData);
        }
      }
    }catch(e, s){
      print('get payment link company error: $e, trace: ${s}');
      //readAllTable();
    }
  }

  checkOfferAmount(Promotion promotion, String cartSubtotal){
    String subtotal = cartSubtotal;
    try{
      if(promotion.type == 0){
        return false;
      } else {
        double total = double.parse(subtotal) - double.parse(promotion.amount!);
        if(total.isNegative){
          return true;
        } else {
          return false;
        }
      }
    }catch(e, s){
      print("check offer amount error: ${e}, stackTrace: $s");
      return false;
    }
  }

  bool isPromotionAvailable(Promotion promotion, CartModel cart){
    Promotion selectedPromotion = promotion;
    if(selectedPromotion.specific_category == '1' || selectedPromotion.specific_category == '2'){
      if(containPromotionCategory(promotion, cart)){
        return _checkPromotionAvailability(selectedPromotion);
      } else {
        return false;
      }
    } else {
      return _checkPromotionAvailability(selectedPromotion);
    }

  }

  bool containPromotionCategory(Promotion promotion, CartModel cart){
    if(promotion.specific_category == '1'){
      return cart.cartNotifierItem.any((e) => e.category_id == promotion.category_id);
    } else {
      // Extract categoryIds from promotion
      Set<int> promotionCategorySet = promotion.multiple_category!.map((item) => item['category_id'] as int).toSet();
      // Extract categoryIds from cartItems
      Set<int> cartCategoryIds = cart.cartNotifierItem.map((item) => int.parse(item.category_id!)).toSet();
      // If there's any intersection, it means there are common IDs.
      return promotionCategorySet.intersection(cartCategoryIds).isNotEmpty;
    }
  }

  _checkPromotionAvailability(Promotion selectedPromotion){
    if (selectedPromotion.all_day == '1' && selectedPromotion.all_time == '1') {
      return true;
    } else if (selectedPromotion.all_day == '0' && selectedPromotion.all_time == '0') {
      return _isPromotionActiveToday(selectedPromotion);
    } else if (selectedPromotion.all_time == '1') {
      return _isDateWithinPromotionRange(DateTime.now(), selectedPromotion);
    } else {
      return _isTimeWithinPromotionRange(DateTime.now(), selectedPromotion);
    }
  }

  /// Checks if a promotion is active today.
  ///
  /// Returns:
  /// - `true` if today's date is within the promotion's date range and
  ///   the current time is within the promotion's time range.
  /// - `false` otherwise.
  bool _isPromotionActiveToday(Promotion promotion) {
    final now = DateTime.now();

    return _isDateWithinPromotionRange(now, promotion) &&
        _isTimeWithinPromotionRange(now, promotion);
  }

  /// Checks if a date is within a promotion's date range.
  ///
  /// Returns:
  /// - `true` if the given date is within the promotion's start and end dates.
  /// - `false` otherwise.
  bool _isDateWithinPromotionRange(DateTime date, Promotion promotion) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final startDate = dateFormat.parse(promotion.sdate!);
    final endDate = dateFormat.parse(promotion.edate!);

    return date.compareTo(startDate) >= 0 && date.compareTo(endDate) <=0;
  }

  /// Checks if a time is within a promotion's time range.
  ///
  /// Returns:
  /// - `true` if the given time is within the promotion's start and end times.
  /// - `false` otherwise.
  bool _isTimeWithinPromotionRange(DateTime time, Promotion promotion) {
    final timeFormat = DateFormat('HH:mm');
    final startTime = timeFormat.parse(promotion.stime!);
    final endTime = timeFormat.parse(promotion.etime!);

    final todayStartTime = DateTime(time.year, time.month, time.day,
        startTime.hour, startTime.minute);
    final todayEndTime = DateTime(time.year, time.month, time.day,
        endTime.hour, endTime.minute);

    return time.compareTo(todayStartTime) >= 0 &&
        time.compareTo(todayEndTime) < 0;
  }

}