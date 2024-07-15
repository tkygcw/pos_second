
import 'package:optimy_second_device/object/app_setting.dart';

import '../object/branch_link_dining_option.dart';
import '../object/branch_link_product.dart';
import '../object/product.dart';
import '../object/user.dart';

class MockData {
  static final MockData instance = MockData.init();
  MockData.init();
  AppSetting mockAppSetting = AppSetting(
    show_sku: 1
  );

  List<Product> productMockData = [
    Product(
      product_sqlite_id: 1,
      product_id: 1,
      category_sqlite_id: '0',
      category_id: '0',
      company_id: '3',
      name: 'Product 1',
      price: '5.00',
      description: 'test product',
      SKU: '001',
      image: '',
      has_variant: 0,
      stock_type: 3,
      stock_quantity: '0',
      available: 1,
      graphic_type: '1',
      color: '#E0E0E0',
      daily_limit: '0',
      daily_limit_amount: '0',
      unit: 'each',
      per_quantity_unit: '',
      sequence_number: '',
      allow_ticket: 0,
      soft_delete: ''
    )
  ];

  List<User> userMockData = [
    User(
      user_id: 1,
      name: 'Amin1',
      role: 0,
      status: 0,
      pos_pin: '000000',
      soft_delete: ''
    )
  ];

  List<BranchLinkDining> branchLinkDiningMockData = [
    BranchLinkDining(
      branch_link_dining_id: 1,
      name: 'Take Away',
      dining_id: '1',
      soft_delete: ''
    )
  ];

  List<BranchLinkProduct> branchLinkProductMockData = [
    BranchLinkProduct(
      branch_link_product_sqlite_id: 1,
      branch_link_product_id: 1,
      branch_id: '3',
      product_sqlite_id: '1',
      product_id: '1',
      has_variant: '0',
      product_variant_sqlite_id: '0',
      product_variant_id: '',
      b_SKU: '001',
      price: '5.00',
      stock_type: '3',
      soft_delete: ''
    )
  ];
}