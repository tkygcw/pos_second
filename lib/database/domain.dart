import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

class Domain {
  // static var domain = 'https://pos.lkmng.com/';
  static var domain = 'https://pos.optimy.com.my/';
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
      await http.post(Uri.parse("https://www.google.com/")).timeout(Duration(seconds: 3), onTimeout: ()=> throw TimeoutException("Timeout"));
      return true;
    } catch (e) {
      Fluttertoast.showToast(msg: "is host reachable domain: ${Domain.login}", backgroundColor: Colors.red);
      Fluttertoast.showToast(msg: "is host reachable error: ${e}");
      return false;
    }
  }
}