import 'dart:io';

import 'package:flutter/material.dart';
import 'package:optimy_second_device/object/product.dart';

import '../product/product_order_dialog.dart';
import '../translation/AppLocalizations.dart';
import 'colorCode.dart';

class ProductSearchDelegate extends SearchDelegate{
  String? imagePath;
  List<Product>? productList;

  ProductSearchDelegate({
    this.productList,
    this.imagePath
  });

  @override
  List<Widget>? buildActions(BuildContext context) {
    // TODO: implement buildActions
    return [
      IconButton(
        onPressed: () {
          if(query.isEmpty){
            close(context, null);
          } else {
            query = '';
          }
        },
        icon: Icon(Icons.clear),
      ),
    ];
    //throw UnimplementedError();
  }

  @override
  Widget? buildLeading(BuildContext context) {
    // TODO: implement buildLeading
    return IconButton(
      onPressed: (){
        close(context, null);
      },
      icon: Icon(Icons.arrow_back),);
    //throw UnimplementedError();
  }

  Future<Future<Object?>> openProductOrderDialog(Product product, BuildContext context) async {
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

  @override
  Widget buildResults(BuildContext context) {
    // TODO: implement buildResults
    List<Product> matchQuery = [];
    for (int i = 0; i < productList!.length; i++) {
      if (productList![i].name!.toLowerCase().contains(query.toLowerCase())) {
        matchQuery.add(productList![i]);
      } else if (productList![i].SKU!.toLowerCase().contains(query.toLowerCase())){
        matchQuery.add(productList![i]);
      }
    }
    if(matchQuery.isNotEmpty){
      return ListView.builder(
        itemCount: matchQuery.length,
        itemBuilder: (context, index) {
          var result = matchQuery[index].SKU! + ' ' + matchQuery[index].name!;
          return ListTile(
            title: Text(result),
            leading: matchQuery[index].graphic_type == '2' ?
            CircleAvatar(
                backgroundColor: Colors.grey.shade200,
                foregroundImage: FileImage(File(imagePath! + '/' + matchQuery[index].image!),
                ),
            ) :
            CircleAvatar(
              backgroundColor: HexColor(matchQuery[index].color!),
            ),
            onTap: () {
              close(context, null);
              openProductOrderDialog(matchQuery[index], context);
            },
          );
        },
      );
    } else {
      return Center(
        child: Text(AppLocalizations.of(context)!.translate('no_record_found')),
      );
    }
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // TODO: implement buildSuggestions
    List<Product> matchQuery = [];
    for (int i = 0; i < productList!.length; i++) {
      if (productList![i].name!.toLowerCase().contains(query.toLowerCase())) {
        matchQuery.add(productList![i]);
      } else if (productList![i].SKU!.toLowerCase().contains(query.toLowerCase())){
        matchQuery.add(productList![i]);
      }
    }
    if(matchQuery.isNotEmpty){
      return ListView.builder(
        itemCount: matchQuery.length,
        itemBuilder: (context, index) {
          var result = matchQuery[index].SKU! + ' ' + matchQuery[index].name!;
          return ListTile(
            title: Text(result),
            leading: matchQuery[index].graphic_type == '2' ?
            CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              foregroundImage: FileImage(File(imagePath! + '/' + matchQuery[index].image!),
              ),
            ):
            CircleAvatar(
                backgroundColor: HexColor(matchQuery[index].color!),
            ),
            onTap: () {
              close(context, null);
              openProductOrderDialog(matchQuery[index], context);
            },
          );
        },
      );
    } else {
      return Center(
        child: Text(AppLocalizations.of(context)!.translate('no_record_found')),
      );
    }
  }

}