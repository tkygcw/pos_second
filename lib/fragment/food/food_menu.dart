import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import '../../notifier/cart_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/categories.dart';
import '../../object/colorCode.dart';
import '../../object/product.dart';
import '../../object/search_delegate.dart';
import '../../page/progress_bar.dart';
import '../../product/product_order_dialog.dart';

class FoodMenu extends StatefulWidget {
  final CartModel cartModel;

  const FoodMenu({Key? key, required this.cartModel}) : super(key: key);

  @override
  _FoodMenuState createState() => _FoodMenuState();
}

class _FoodMenuState extends State<FoodMenu> with TickerProviderStateMixin {
  final double screenWidth = WidgetsBinding.instance.platformDispatcher.views.first.physicalSize.width;
  List<Tab> categoryTab = [];
  List<Widget> categoryTabContent = [];
  List<String> categoryList = [];
  late TabController _tabController;
  late String companyID;
  List<Product> allProduct = [];
  List<Product> specificProduct = [];
  List<Categories> initCategory = [];
  List<Product> initProduct = [];
  TextEditingController searchController = new TextEditingController();
  bool isLoading = true;
  int loadCount = 0;
  String imagePath = '';

  @override
  void initState() {
    readAllCategories();
    super.initState();
    //sendRequest();
    //preload();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.cartModel.initialLoad();
    });
    // _tabController = TabController(length: 0, vsync: this);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _tabController.dispose();
    super.dispose();
  }

  getPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    imagePath = prefs.getString('local_path')!;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      // if(notificationModel.contentLoad == true) {
      //   isLoading = true;
      //   //print('notification refresh called!');
      // }
      // if(notificationModel.contentLoad == true && notificationModel.contentLoaded == true){
      //   notificationModel.resetContentLoaded();
      //   notificationModel.resetContentLoad();
      //   Future.delayed(const Duration(seconds: 1), () {
      //     if(mounted){
      //       setState(() {
      //         readAllCategories(hasNotification: true);
      //       });
      //     }
      //   });
      // }
      return isLoading ?
      CustomProgressBar() :
      Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          title: Text(
            "Menu",
            style: TextStyle(fontSize: 25, color: color.backgroundColor),
          ),
          actions: [
            IconButton(
              color: color.buttonColor,
              onPressed: (){
                showSearch(context: context, delegate: ProductSearchDelegate(productList: allProduct, imagePath: imagePath, cartModel: widget.cartModel));
              },
              icon: Icon(Icons.search),
            )
          ],
        ),
        resizeToAvoidBottomInset: false,
        body: Column(
            children: [
              TabBar(
                isScrollable: true,
                unselectedLabelColor: Colors.black,
                labelColor: color.buttonColor,
                indicatorColor: color.buttonColor,
                tabs: categoryTab,
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: TabBarView(controller: _tabController, children: categoryTabContent),
                ),
              ),
            ]),
      );
    });
  }

  Future<Future<Object?>> openProductOrderDialog(Product product, CartModel cartModel) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
                opacity: a1.value,
                child: ProductOrderDialog(
                  cartModel:  cartModel,
                  productDetail: product,
                )),
          );
        },
        transitionDuration: Duration(milliseconds: 200),
        barrierDismissible: false,
        context: context,
        pageBuilder: (context, animation1, animation2) {
          // ignore: null_check_always_fails
          return null!;
        });
  }

  void refresh() {
    isLoading = false;
    setState(() {});
  }

  // decodeData() {
  //   var json = jsonDecode(clientAction.response!);
  //   print('json: ${json}');
  //   if (json['status'] == '1') {
  //     print('data: ${json['data']}');
  //     setState(() {
  //       Iterable value = json['data']['tb_categories'];
  //       initCategory = List<Categories>.from(value.map((json) => Categories.fromJson(json)));
  //       Iterable value2 = json['data']['tb_product'];
  //       initProduct = List<Product>.from(value2.map((json) => Product.fromJson(json)));
  //     });
  //     Future.delayed(const Duration(seconds: 2), () {
  //       readAllCategories();
  //     });
  //   }
  // }
  //
  // Future<List<Product>> decodeData2() async {
  //   var json = jsonDecode(clientAction.response!);
  //   print('json: ${json}');
  //   if (json['status'] == '1') {
  //     print('data: ${json['data']}');
  //     setState(() {
  //       Iterable value3 = json['data']['tb_product2'];
  //       specificProduct = List<Product>.from(value3.map((json) => Product.fromJson(json)));
  //     });
  //   }
  //   return specificProduct;
  // }

  // sendRequest(){
  //   print('send request called');
  //   Map<String, dynamic>? result;
  //   result = {'action': '4', 'param': ''};
  //   clientAction.socket.write(jsonEncode(result));
  //   Future.delayed(const Duration(seconds: 1), () {
  //     decodeData();
  //   });
  // }
  //
  // sendRequest2(String categoryName) async  {
  //   print('send request 2 called');
  //   Map<String, dynamic>? result;
  //   result = {'action': '5', 'param': categoryName};
  //   clientAction.socket.write(jsonEncode(result));
  //   Future.delayed(const Duration(milliseconds: 500), () async {
  //     specificProduct = await decodeData2();
  //   });
  // }

  readAllCategories() async {
    await getPreferences();
    initCategory = decodeAction.decodedCategoryList!;
    initProduct = decodeAction.decodedProductList!;

    List<Categories> data = initCategory;
    sortCategory(data);
    categoryTab.add(Tab(
      text: 'All Category',
    ));
    categoryList.add('All Category');
    for (int i = 0; i < data.length; i++) {
      categoryTab.add(Tab(
        text: data[i].name!,
      ));
      categoryList.add(data[i].name!);
    }
    for (int i = 0; i < categoryList.length; i++) {
      if (categoryList[i] == 'All Category') {
        List<Product> data = initProduct;
        sortProduct(data);
        allProduct = data;
        categoryTabContent.add(GridView.count(
            shrinkWrap: true,
            crossAxisCount: MediaQuery.of(MyApp.navigatorKey.currentContext!).size.height > 500 && MediaQuery.of(MyApp.navigatorKey.currentContext!).size.width > 900 ? 5 : 3,
            children: List.generate(data.length, (index) {
              return Card(
                child: Container(
                  decoration: (data[index].graphic_type == '2'
                      ? //BoxDecoration(color: Colors.grey)
                  BoxDecoration(image: DecorationImage(image: FileImage(File(imagePath + '/' + data[index].image!)), fit: BoxFit.cover))
                      : BoxDecoration(color: HexColor(data[index].color!))),
                  child: InkWell(
                    splashColor: Colors.blue.withAlpha(30),
                    onTap: () {
                      openProductOrderDialog(data[index], widget.cartModel);
                    },
                    child: Stack(
                      alignment: Alignment.bottomLeft,
                      children: [
                        Container(
                          height: 50,
                          padding: EdgeInsets.fromLTRB(5, 2, 5, 2),
                          color: Colors.black.withOpacity(0.5),
                          width: 200,
                          alignment: Alignment.center,
                          child: Text(
                            data[index].SKU! + ' ' + data[index].name!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            })));
      } else {
        List<Product> data = initProduct.where((item) => item.category_name == categoryList[i]).toList();//specificProduct;
        sortProduct(data);
        categoryTabContent.add(GridView.count(
            shrinkWrap: true,
            padding: const EdgeInsets.all(10),
            crossAxisCount: MediaQuery.of(MyApp.navigatorKey.currentContext!).size.height > 500 && MediaQuery.of(MyApp.navigatorKey.currentContext!).size.width > 900 ? 5 : 3,
            children: List.generate(data.length, (index) {
              return Card(
                child: Container(
                  decoration: (data[index].graphic_type == '2'
                      ? //BoxDecoration(color: Colors.grey)
                  BoxDecoration(image: DecorationImage(image: FileImage(File(imagePath + '/' + data[index].image!)), fit: BoxFit.cover))
                      : BoxDecoration(color: HexColor(data[index].color!))),
                  child: InkWell(
                    splashColor: Colors.blue.withAlpha(30),
                    onTap: () {
                      openProductOrderDialog(data[index], widget.cartModel);
                    },
                    child: Stack(
                      alignment: Alignment.bottomLeft,
                      children: [
                        Container(
                          color: Colors.black.withOpacity(0.5),
                          padding: EdgeInsets.fromLTRB(5, 2, 5, 2),
                          height: 50,
                          width: 200,
                          alignment: Alignment.center,
                          child: Text(
                            data[index].SKU! + ' ' + data[index].name!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            })));
        //sendRequest2(categoryList[i]);
        // Future.delayed(const Duration(seconds: 1), () {
        //
        // });
      }
    }
    _tabController = TabController(length: categoryTab.length, vsync: this);
    refresh();
  }

  sortProduct(List<Product> list){
    list.sort((a, b) {
      final aNumber = a.sequence_number!;
      final bNumber = b.sequence_number!;

      bool isANumeric = int.tryParse(aNumber) != null;
      bool isBNumeric = int.tryParse(bNumber) != null;

      if (isANumeric && isBNumeric) {
        return int.parse(aNumber).compareTo(int.parse(bNumber));
      } else if (isANumeric) {
        return -1; // Numeric before alphanumeric
      } else if (isBNumeric) {
        return 1; // Alphanumeric before numeric
      } else {
        // Custom alphanumeric sorting logic
        return compareNatural(aNumber, bNumber);
      }
    });
    return list;
  }

  sortCategory(List<Categories> list){
    list.sort((a, b) {
      final aNumber = a.sequence!;
      final bNumber = b.sequence!;

      bool isANumeric = int.tryParse(aNumber) != null;
      bool isBNumeric = int.tryParse(bNumber) != null;

      if (isANumeric && isBNumeric) {
        return int.parse(aNumber).compareTo(int.parse(bNumber));
      } else if (isANumeric) {
        return -1; // Numeric before alphanumeric
      } else if (isBNumeric) {
        return 1; // Alphanumeric before numeric
      } else if (!isANumeric && !isBNumeric) {
        return compareNatural(a.name!, b.name!);
      } else {
        // Custom alphanumeric sorting logic
        return compareNatural(aNumber, bNumber);
      }
    });
    return list;
  }

  // getPreferences() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final String? user = prefs.getString('user');
  //   imagePath = prefs.getString('local_path')!;
  //
  //   Map userObject = json.decode(user!);
  //   companyID = userObject['company_id'];
  // }
}
