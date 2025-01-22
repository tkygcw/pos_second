import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:optimy_second_device/object/dining_option.dart';
import 'package:optimy_second_device/object/order_cache.dart';

import '../../main.dart';

class OtherOrderFunction extends ChangeNotifier {
  static final OtherOrderFunction instance = OtherOrderFunction._init();
  List<DiningOption> _diningOption = [];
  List<OrderCache> _orderCache = [];

  List<OrderCache> get orderCache => _orderCache;

  OtherOrderFunction._init();

  Future<void> readAllOrderCache(String diningName) async {
    await clientAction.connectRequestPort(action: '22', param: diningName, callback: _decodeOrderCache);
  }

  void _decodeOrderCache(response){
    try{
      var json = jsonDecode(clientAction.response!);
      String status = json['status'];
      switch(status){
        case '1': {
          Iterable value1 = json['data'];
          _orderCache = List<OrderCache>.from(value1.map((json) => OrderCache.fromJson(json)));
          // print("order cache length: ${_orderCache.first.dining_name}");
          notifyListeners();
        }break;
        default: {
          clientAction.openReconnectDialog(action: json['action'], callback: _decodeData);
        }
      }
    }catch(e, s){
      print('get dining option error: $e, trace: ${s}');
      //readAllTable();
    }
  }

  Future<List<DiningOption>> readAllDiningOption() async {
    await clientAction.connectRequestPort(action: '21', param: '', callback: _decodeData);
    return _diningOption;
  }

  void _decodeData(response){
    try{
      var json = jsonDecode(clientAction.response!);
      String status = json['status'];
      switch(status){
        case '1': {
          Iterable value1 = json['data'];
          _diningOption = [DiningOption(name: 'All')];
          _diningOption.addAll(List<DiningOption>.from(value1.map((json) => DiningOption.fromJson(json))));
          readAllOrderCache(_diningOption.first.name!);
        }break;
        default: {
          clientAction.openReconnectDialog(action: json['action'], callback: _decodeData);
        }
      }
    }catch(e, s){
      print('get dining option error: $e, trace: ${s}');
      //readAllTable();
    }
  }
}