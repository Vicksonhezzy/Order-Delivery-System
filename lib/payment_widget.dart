import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_paystack/flutter_paystack.dart';
import 'package:test_project/model.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;


String paystackPublicKey = 'public_key';
String secKey = 'sec_key';
const String appName = 'Paystack Example';

const postUrl = 'https://api.paystack.co/transaction/initialize';

final headers = {
  'Authorization': 'Bearer $secKey',
  'Content-Type': 'application/json',
};

bool status = false;

class MyLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black,
      ),
      alignment: Alignment.center,
      padding: EdgeInsets.all(10),
      child: Text(
        "ENNOE",
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class PaymentWidget {
  static var currency = utf8.decode([0xE2, 0x82, 0xA6]);
  static String countryCurrency = '';

  static handlePaymentInitialization({
    @required BuildContext context,
    double addressLng,
    double addressLat,
    String time,
    Function setLoading,
    @required int amount,
    @required String email,
    @required String number,
    @required Models model,
    @required PaystackPlugin plugin,
    bool isCart,
    String address,
    String productId,
    String recipientName,
  }) async {
    await model.addToMyPurchases(
        recipientName: recipientName,
        recipientNumber: number,
        address: address,
        addressLat: addressLat,
        addressLng: addressLng,
        productId: productId,
        time: time);
    Future<Map<String, dynamic>> initializePayment() async {
      try {
        final data = {
          'email': '$email',
          'amount': '$amount',
        };
        http.Response response = await http.post(Uri.parse(postUrl),
            headers: headers, body: json.encode(data));
        // Map<String, dynamic> map = json.decode(response.body);
        Map<String, dynamic> result = json.decode(response.body);
        print(json.decode(response.body));
        if (result.containsKey('status') && result['status'] == true) {
          status = true;
        }
        return {'successful': status, 'result': result};
      } on HttpException catch (e) {
        print('push error= ${e.message}');
        return {'successful': status, 'result': 'error initializing payment'};
      }
    }

    setLoading(true);
    await initializePayment().then((value) async {
      print('value = $value');
      setLoading(false);
      Map<String, dynamic> result = value['result'];
      if (value['successful'] != true ||
          (result.containsKey('status') && result['status'] != true)) {
        return showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('ERROR'),
            content: Text(
                'Error occurred during transaction initialization. Check your internet connection and try again'),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
        );
      } else {
        PaymentCard paymentCard = PaymentCard(
          number: null,
          cvc: null,
          expiryMonth: null,
          expiryYear: null,
        );

        Charge charge = Charge()
          ..amount = amount // In base currency
          ..email = email
          ..card = paymentCard;

        String accessCode = value['result']['data']['access_code'];
        charge.accessCode = accessCode;
        print('accessCode = $accessCode');

        try {
          CheckoutResponse response = await plugin.checkout(
            context,
            method: CheckoutMethod.selectable,
            charge: charge,
            fullscreen: false,
            logo: MyLogo(),
          );
          print('Response = $response');
          if (response.status == true) {
            await verifyOnServer(accessCode, context).then((value) {
              model.addToMyPurchases(
                  recipientName: recipientName,
                  recipientNumber: number,
                  address: address,
                  addressLat: addressLat,
                  addressLng: addressLng,
                  time: time);
              dialog('Payment Was Successful!', context);
            });
          } else {
            updateStatus(accessCode, response.message, context);
          }
          updateStatus(response.reference, '$response', context);
        } catch (e) {
          showMessage("Check console for error", context);
          rethrow;
        }
      }
    });
  }

  static Future verifyOnServer(String reference, BuildContext context) async {
    updateStatus(reference, 'Verifying...', context);
    // String url = '$postUrl/verify/$reference';
    String url = 'https://api.paystack.co/transaction/verify/$reference';
    final header = {'Authorization': 'Bearer $secKey'};
    try {
      http.Response response = await http.get(Uri.parse(url), headers: header);
      var body = response.body;
      print('verification = $body');
      updateStatus(reference, body, context);
    } catch (e) {
      updateStatus(
          reference,
          'There was a problem verifying %s on the backend: '
          '$reference $e',
          context);
    }
  }

  static updateStatus(String reference, String message, BuildContext context) {
    showMessage('Reference: $reference \n\ Response: $message', context,
        const Duration(seconds: 7));
  }

  static showMessage(String message, BuildContext context,
      [Duration duration = const Duration(seconds: 4)]) {
    ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
      content: new Text(message),
      duration: duration,
      action: new SnackBarAction(
          label: 'CLOSE',
          onPressed: () =>
              ScaffoldMessenger.of(context).removeCurrentSnackBar()),
    ));
  }

  static dialog(String value, BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        elevation: 2,
        title: Text('FeedBack'),
        content: Text(value),
        actions: [
          Container(
            color: Colors.green,
            padding: EdgeInsets.all(2),
            child: TextButton(
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                }),
          )
        ],
      ),
    );
  }
}
