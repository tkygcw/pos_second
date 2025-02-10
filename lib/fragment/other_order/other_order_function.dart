import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:optimy_second_device/fragment/table/table_view_function.dart';
import 'package:optimy_second_device/object/dining_option.dart';
import 'package:optimy_second_device/object/order_cache.dart';
import 'package:optimy_second_device/object/order_detail.dart';

import '../../main.dart';

class OtherOrderFunction extends ChangeNotifier {
  static final OtherOrderFunction instance = OtherOrderFunction._init();
  List<DiningOption> _diningOption = [];
  List<OrderCache> _orderCacheList = [], _selectedOrderCache = [];
  List<OrderDetail> _orderDetailList = [];
  String _selectedDiningName = '';
  int _responseStatus = 0;

  List<OrderCache> get orderCacheList => _orderCacheList;
  List<OrderDetail> get orderDetailList => _orderDetailList;
  List<OrderCache> get selectedOrderCache => _selectedOrderCache;

  OtherOrderFunction._init();

  Future<void> unselectSpecificSubPosOrderCache(String batch) async {
    await clientAction.connectRequestPort(action: '24', param: batch);
  }

  Future<int> readAllOrderDetail(OrderCache orderCache) async {
    await clientAction.connectRequestPort(action: '23', param: jsonEncode(orderCache), callback: (response) => _decodeOrderDetail(response, orderCache));
    return _responseStatus;
  }

  void _decodeOrderDetail(response, OrderCache selectedOrderCache){
    try{
      var json = jsonDecode(clientAction.response!);
      String status = json['status'];
      _responseStatus = int.parse(status);
      switch(status){
        case '1': {
          Iterable orderCache = json['data']['orderCacheList'];
          Iterable orderDetail = json['data']['orderDetailList'];
          List<OrderCache> orderCacheResponseData = List<OrderCache>.from(orderCache.map((json) => OrderCache.fromJson(json)));
          if(orderCacheResponseData.isNotEmpty){
            _selectedOrderCache = orderCacheResponseData;
          } else {
            _selectedOrderCache = [selectedOrderCache];
          }
          _orderDetailList = List<OrderDetail>.from(orderDetail.map((json) => OrderDetail.fromJson(json)));
        }break;
        case '2': {
          _selectedOrderCache = [];
          _orderDetailList = [];
        } break;
        default: {
          clientAction.openReconnectDialog(action: json['action'], callback: _decodeData);
        }
      }
    }catch(e, s){
      print('get dining option error: $e, trace: ${s}');
      //readAllTable();
    }
  }

  Future<List<OrderCache>> readAllOrderCache({String? diningName, bool? resetMainPosOrderCache}) async {
    _selectedDiningName = diningName ?? _selectedDiningName;
    await clientAction.connectRequestPort(
        action: '22',
        param: _selectedDiningName,
        callback: (response) => _decodeOrderCache(response, resetMainPosOrderCache),
    );
    return _orderCacheList;
  }

  void _decodeOrderCache(response, bool? resetMainPosOrderCache){
    try{
      var json = jsonDecode(clientAction.response!);
      String status = json['status'];
      switch(status){
        case '1': {
          Iterable value1 = json['data'];
          _orderCacheList = List<OrderCache>.from(value1.map((json) => OrderCache.fromJson(json)));
          if(resetMainPosOrderCache != null && resetMainPosOrderCache == true){
            TableViewFunction().unselectAllSubPosOrderCache();
          }
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
          readAllOrderCache(diningName: _diningOption.first.name!, resetMainPosOrderCache: true);
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