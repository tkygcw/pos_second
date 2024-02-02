import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:optimy_second_device/page/pos_pin.dart';
import 'package:optimy_second_device/page/progress_bar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';

import '../notifier/theme_color.dart';
import 'login.dart';


class LoadingPage extends StatefulWidget {
  const LoadingPage({Key? key}) : super(key: key);

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  List<String> decodedBase64ImageList = [];
  bool isDecodeComplete = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    startLoad();
    // if(isDecodeComplete){
    //   _createProductImgFolder();
    //   toNextPage();
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Scaffold(
        backgroundColor: color.backgroundColor,
        body: CustomProgressBar(),
      );
    });
  }

  startLoad() async  {
    // if(notificationModel.contentLoaded == true){
    //
    // }
    await Future.delayed(Duration(seconds: 3), () {
      decodeAction.decodeAllFunction();
      //_createProductImgFolder();
    });
    // Future.delayed(Duration(seconds: 5), () {
    //   _createProductImgFolder();
    //   setState(() {
    //     isDecodeComplete = true;
    //   });
    // });
    // clientAction.sendRequest(action: '8', param: '');
    // Future.delayed(Duration(seconds: 2), () {
    //   decodeData();
    // });
    // try{
    //   requestData();
    // }catch(e){
    //   Navigator.of(context).pushAndRemoveUntil(
    //     // the new route
    //     MaterialPageRoute(
    //       builder: (BuildContext context) => LoginPage(),
    //     ),
    //
    //     // this function should return true when we're done removing routes
    //     // but because we want to remove all other screens, we make it
    //     // always return false
    //         (Route route) => false,
    //   );
    // }
    // Go to Page2 after 5s.

    Timer(Duration(seconds: 12), () {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PosPinPage()));
    });

  }

  toNextPage(){
    Timer(Duration(seconds: 8), () {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PosPinPage()));
    });
  }

  decodeData(){
    var json = jsonDecode(clientAction.response!);
    Iterable value7 = json['data']['image_list'];
    decodedBase64ImageList = List.from(value7);
    _createProductImgFolder();
  }

/*
  create folder to save product image
*/
  Future<String> get _localPath async {
    final directory = await getApplicationSupportDirectory();
    return directory.path;
  }

  _createProductImgFolder() async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);

    final folderName = userObject['company_id'];
    final directory = await _localPath;
    final path = '$directory/assets/$folderName';
    final pathImg = Directory(path);
    pathImg.create();
    await prefs.setString('local_path', path);
    print('image path: ${pathImg.path}');
    downloadProductImage(pathImg.path);
  }

  /*
  download product image
*/
  downloadProductImage(String path) async {
    List<String> encodedImageList = decodeAction.decodedBase64ImageList;
    for(int i = 0; i < encodedImageList.length; i++){
      Uint8List decodeByte = decodeBase64Image(encodedImageList[i]);
      print('decoded byte: ${decodeByte}');
      var localPath = '$path/test.jpeg';
      final imageFile = File(localPath);
      await imageFile.writeAsBytes(decodeByte);
    }
    // final prefs = await SharedPreferences.getInstance();
    // final String? user = prefs.getString('user');
    // Map userObject = json.decode(user!);
    // Map data = await Domain().getAllProduct(userObject['company_id']);
    // String url = '';
    // String name = '';
    // if (data['status'] == '1') {
    //   List responseJson = data['product'];
    //   for (var i = 0; i < responseJson.length; i++) {
    //     Product data = Product.fromJson(responseJson[i]);
    //     name = data.image!;
    //     if (data.image != '') {
    //       url = '${Domain.backend_domain}api/gallery/' + userObject['company_id'] + '/' + name;
    //       final response = await http.get(Uri.parse(url));
    //       var localPath = path + '/' + name;
    //       final imageFile = File(localPath);
    //       await imageFile.writeAsBytes(response.bodyBytes);
    //     }
    //   }
    // }
  }

  decodeBase64Image(String base64){
    Uint8List decodedByte = base64Decode(base64);
    return decodedByte;
  }

}




