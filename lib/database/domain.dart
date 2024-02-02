import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

class Domain {
  static var domain = 'https://pos.lkmng.com/';
  //static var domain = 'https://pos.optimy.com.my/';
  static Uri login = Uri.parse('${domain}mobile-api/login/index.php');
  static Uri device = Uri.parse('${domain}mobile-api/device/index.php');
  static Uri branch = Uri.parse('${domain}mobile-api/branch/index.php');

  /*
  * login
  * */
  userlogin(email, password) async {
    try {
      var response = await http.post(Domain.login, body: {
        'login': '1',
        'password': password,
        'email': email,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * Forget Password
  * */
  forgetPassword(email) async {
    try {
      var response = await http.post(Domain.login, body: {
        'resetPassword': '1',
        'email': email,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get company branch
  * */
  getCompanyBranch(company_id) async {
    try {
      var response = await http.post(Domain.branch, body: {
        'getAllCompanyBranch': '1',
        'company_id': company_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get branch device
  * */
  getBranchDevice(branch_id) async {
    try {
      var response = await http.post(Domain.device, body: {
        'getBranchDevice': '1',
        'branch_id': branch_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  isHostReachable() async {
    try {
      await http.get(Uri.parse('https://pos.optimy.com.my/login/index.php'));
      return true;
    } catch (e) {
      return false;
    }
  }
}