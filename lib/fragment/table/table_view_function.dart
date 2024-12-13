import 'dart:convert';
import 'package:optimy_second_device/object/order_cache.dart';
import 'package:optimy_second_device/object/order_detail.dart';

import '../../main.dart';
import '../../object/table.dart';

class TableViewFunction {
  List<PosTable> _tableList = [];
  List<OrderCache> _orderCacheList = [];
  List<OrderDetail> _orderDetailList = [];

  List<OrderDetail> get orderDetailList => _orderDetailList;

  List<OrderCache> get orderCacheList => _orderCacheList;


  List<PosTable> get tableList => _tableList;

  Future<List<PosTable>> readAllTable({model, notification}) async {
    await clientAction.connectRequestPort(action: '13', param: '', callback: _decodeData);
    return _tableList;
  }

  void _decodeData(response){
    try{
      var json = jsonDecode(clientAction.response!);
      String status = json['status'];
      switch(status){
        case '1': {
          Iterable value1 = json['data']['table_list'];
          _tableList = List<PosTable>.from(value1.map((json) => PosTable.fromJson(json)));
        }break;
        default: {
          clientAction.openReconnectDialog(action: json['action'], callback: _decodeData);
        }
      }
    }catch(e, s){
      print('init table error: $e, trace: ${s}');
      //readAllTable();
    }
  }

  Future<void> readSpecificTableDetail(PosTable posTable) async {
    await clientAction.connectRequestPort(action: '16', param: jsonEncode(posTable), callback: _decodeTableDetail);
  }

  void _decodeTableDetail(response){
    try{
      var json = jsonDecode(clientAction.response!);
      String status = json['status'];
      switch(status){
        case '1': {
          Iterable orderCache = json['data']['orderCacheList'];
          Iterable orderDetail = json['data']['orderDetailList'];
          _orderCacheList = List<OrderCache>.from(orderCache.map((json) => OrderCache.fromJson(json)));
          _orderDetailList = List<OrderDetail>.from(orderDetail.map((json) => OrderDetail.fromJson(json)));
        }break;
        default: {
          clientAction.openReconnectDialog(action: json['action'], callback: _decodeTableDetail);
        }
      }
    }catch(e){
      print('init table error: $e');
      //readAllTable();
    }
  }
}