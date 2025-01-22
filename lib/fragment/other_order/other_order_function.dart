import 'dart:convert';

import 'package:optimy_second_device/object/dining_option.dart';

import '../../main.dart';

class OtherOrderFunction {
  final List<DiningOption> _diningOption = [];

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
          _diningOption.add(DiningOption(name: 'All'));
          _diningOption.addAll(List<DiningOption>.from(value1.map((json) => DiningOption.fromJson(json))));
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