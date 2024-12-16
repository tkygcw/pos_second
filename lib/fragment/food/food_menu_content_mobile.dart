import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:optimy_second_device/page/progress_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';
import '../../notifier/theme_color.dart';
import '../../object/categories.dart';
import '../../object/colorCode.dart';
import '../../object/product.dart';
import '../../object/search_delegate.dart';
import '../../product/product_order_dialog.dart';
import '../../translation/AppLocalizations.dart';

class FoodMenuContentMobile extends StatefulWidget {
  final ThemeColor color;
  const FoodMenuContentMobile({super.key, required this.color});

  @override
  State<FoodMenuContentMobile> createState() => _FoodMenuContentMobileState();
}

class _FoodMenuContentMobileState extends State<FoodMenuContentMobile> with TickerProviderStateMixin{
  List<Tab> categoryTab = [];
  List<Widget> categoryTabContent = [];
  List<String> categoryList = [];
  late TabController _tabController;
  late String companyID;
  List<Product> initProduct = decodeAction.decodedProductList!.toList();
  bool loaded = false;
  String imagePath = '';

  @override
  void initState() {
    // TODO: implement initState
    readAllCategories();
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThemeColor color = widget.color;
    if(loaded == true){
      return Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TabBar(
                        isScrollable: true,
                        unselectedLabelColor: Colors.black,
                        labelColor: color.buttonColor,
                        indicatorColor: color.buttonColor,
                        tabs: categoryTab,
                        controller: _tabController,
                        indicatorSize: TabBarIndicatorSize.tab,
                      ),
                    ),
                    IconButton(
                      color: color.buttonColor,
                      onPressed: (){
                        showSearch(context: context, delegate: ProductSearchDelegate(productList: initProduct, imagePath: imagePath));
                      },
                      icon: Icon(Icons.search),
                    )
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(controller: _tabController, children: categoryTabContent),
              ),
            ]),
      );
    } else {
      return CustomProgressBar();
    }
  }

  getPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if(prefs.getString('local_path') != null){
      imagePath = prefs.getString('local_path')!;
    }
  }

  readAllCategories() async {
    categoryList.clear();
    categoryTab.clear();
    categoryTabContent.clear();
    await getPreferences();
    List<Categories> initCategory = decodeAction.decodedCategoryList!.toList();
    sortCategory(initCategory);
    categoryTab.add(Tab(
      text: AppLocalizations.of(context)!.translate('all_category'),
    ));
    categoryList.add(AppLocalizations.of(context)!.translate('all_category'));
    for (int i = 0; i < initCategory.length; i++) {
      categoryTab.add(Tab(
        text: initCategory[i].name!,
      ));
      categoryList.add(initCategory[i].name!);
    }
    for (int i = 0; i < categoryList.length; i++) {
      if (categoryList[i] == AppLocalizations.of(context)!.translate('all_category')) {
        List<Product> data = sortProduct(initProduct.toList());
        categoryTabContent.add(GridView.count(
            shrinkWrap: true,
            crossAxisCount: MediaQuery.of(context).size.height > 500 && MediaQuery.of(context!).size.width > 500 ? 4 : 3,
            children: List.generate(data.length, (index) {
              return Card(
                child: Container(
                  decoration: (data[index].graphic_type == '2'
                      ?
                  BoxDecoration(image: DecorationImage(image: FileImage(File(imagePath + '/' + data[index].image!)), fit: BoxFit.cover))
                      : BoxDecoration(color: HexColor(data[index].color!))),
                  child: InkWell(
                    splashColor: Colors.blue.withAlpha(30),
                    onTap: () {
                      openProductOrderDialog(data[index]);
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
                            '${getSKU(data[index].SKU!)} ${data[index].name!}',
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
        data = sortProduct(data);
        categoryTabContent.add(GridView.count(
            shrinkWrap: true,
            crossAxisCount: MediaQuery.of(context).size.height > 500 && MediaQuery.of(context!).size.width > 500 ? 4 : 3,
            children: List.generate(data.length, (index) {
              return Card(
                child: Container(
                  decoration: (data[index].graphic_type == '2' ?
                  BoxDecoration(image: DecorationImage(image: FileImage(File(imagePath + '/' + data[index].image!)), fit: BoxFit.cover))
                      : BoxDecoration(color: HexColor(data[index].color!))),
                  child: InkWell(
                    splashColor: Colors.blue.withAlpha(30),
                    onTap: () {
                      openProductOrderDialog(data[index]);
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
                            '${getSKU(data[index].SKU!)} ${data[index].name!}',
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
      }
    }
    _tabController = TabController(length: categoryTab.length, vsync: this);
    if(!mounted) return;
    refresh();
    print("init product length: ${initProduct.length}");
  }

  Future<Future<Object?>> openProductOrderDialog(Product product) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
                opacity: a1.value,
                child: ProductOrderDialog(
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
    setState(() {
      loaded = true;
    });
  }

  String getSKU(String sku){
    if(decodeAction.decodedAppSetting!.show_sku == 1){
      return sku;
    }else {
      return '';
    }
  }

  sortProduct(List<Product> list){
    List<Product> hasSequenceProduct = list.where((e) => e.sequence_number != null && e.sequence_number != '').toList();
    hasSequenceProduct.sort((a, b) {
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
    list.removeWhere((e) => e.sequence_number != null && e.sequence_number != '');
    List<Product> sortedList2 = getSortedList(list);
    return hasSequenceProduct + sortedList2;
  }

  List<Product> getSortedList(List<Product> noSequenceProduct){
    switch(decodeAction.decodedAppSetting!.product_sort_by){
      case 1 :{
        return sortByProductName(noSequenceProduct);
      }
      case 2: {
        return sortByProductSKU(noSequenceProduct);
      }
      case 3: {
        return sortByProductPrice(noSequenceProduct);
      }
      case 4: {
        return sortByProductName(noSequenceProduct, isDESC: true);
      }
      case 5: {
        return sortByProductSKU(noSequenceProduct, isDESC: true);
      }
      case 6: {
        return sortByProductPrice(noSequenceProduct, isDESC: true);
      }
      default: {
        return noSequenceProduct;
      }
    }
  }

  sortByProductName(List<Product> sortedList, {isDESC}){
    sortedList.sort((a, b){
      return compareNatural(a.name!, b.name!);
    });
    return isDESC == null ? sortedList : sortedList.reversed.toList();
  }

  sortByProductSKU(List<Product> sortedList, {bool? isDESC}){
    sortedList.sort((a, b){
      return compareNatural(a.SKU!, b.SKU!);
    });
    return isDESC == null ? sortedList : sortedList.reversed.toList();
  }

  sortByProductPrice(List<Product> sortedList, {bool? isDESC}){
    sortedList.sort((a, b){
      return compareNatural(a.price!, b.price!);
    });
    return isDESC == null ? sortedList : sortedList.reversed.toList();
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
}
