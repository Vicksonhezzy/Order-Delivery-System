import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:firebase_storage/firebase_storage.dart';

class SendPushNotifications {
  static final postUrl = 'https://api.rnfirebase.io/messaging/send';

  static Future<bool> sendNotifications(token, msg) async {
    String constructPayload(String token) {
      return jsonEncode({
        'token': token,
        'data': {
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'id': '1',
          'status': 'done',
        },
        'notification': {
          'title': '${msg['title']}',
          'body': '${msg['body']}',
        },
      });
    }

    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };

    try {
      http.Response response = await http.post(
        Uri.parse('https://api.rnfirebase.io/messaging/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: constructPayload(token),
      );

      print('message = $msg');
      print(json.decode(response.body));
      print('Push Notification Success');
      return true;
    } on HttpException catch (e) {
      print('push error= ${e.message}');
      return false;
    }
  }
}

class Users {
  final String id;
  final String userType;
  final String email;
  final dynamic password;
  final String number;
  final String token;

  Users({
    @required this.id,
    @required this.token,
    @required this.userType,
    @required this.email,
    this.password,
    this.number,
  });
}

class AllPendingOrders {
  final String orderRef;
  final int rating;
  final String comment;
  final bool pending;
  final bool canceled;
  final String token;
  final String id;
  final String documentCollectionId;

  AllPendingOrders({
    this.orderRef,
    this.id,
    this.rating,
    this.comment,
    this.pending,
    this.canceled,
    this.token,
    this.documentCollectionId,
  });
}

class AllConfirmedOrders {
  final String orderRef;
  final int rating;
  final String comment;
  final bool pending;
  final bool canceled;
  final String token;
  final String id;
  final String documentCollectionId;

  AllConfirmedOrders({
    this.orderRef,
    this.id,
    this.rating,
    this.comment,
    this.pending,
    this.canceled,
    this.token,
    this.documentCollectionId,
  });
}

class Models extends Model {
  bool _isLoading;
  Users _authentication;
  List<AllPendingOrders> _allPendingOrders = [];
  List<AllConfirmedOrders> _allConfirmedOrders = [];
  String _profileImageUrl;
  bool _postUploading;
  File _image;

  bool get isLoading {
    return _isLoading;
  }

  bool get postUploading {
    return _postUploading;
  }

  Users get authentication {
    return _authentication;
  }

  File get image {
    return _image;
  }

  setImage(File image) async {
    _image = image;
    notifyListeners();
  }

  Future<Stream<QuerySnapshot<Map<String, dynamic>>>> pendingOrders(
      bool pending) async {
    return FirebaseFirestore.instance
        .collection('pendingOrders')
        .doc(_authentication.id)
        .collection('myPendingOrders')
        .where('pending', isEqualTo: pending)
        .snapshots();
  }

  List<AllPendingOrders> get viewAllPendingOrders {
    return List.from(_allPendingOrders);
  }

  List<AllConfirmedOrders> get allConfirmedOrders {
    return List.from(_allConfirmedOrders);
  }

  deleteOrders(String collectionId, String id) async {
    CollectionReference reference = FirebaseFirestore.instance
        .collection('pendingOrders')
        .doc(collectionId)
        .collection('myPendingOrders');
    await reference.doc(id).delete();
    notifyListeners();
  }

  allPendingOrders() async {
    List<AllPendingOrders> pendingOrders = [];
    List<AllConfirmedOrders> getAllConfirmedOrders = [];
    CollectionReference reference =
        FirebaseFirestore.instance.collection('pendingOrders');
    await reference
        .doc()
        .firestore
        .collectionGroup('myPendingOrders')
        .snapshots()
        .forEach((element) {
      element.docs.forEach((element) {
        if (element['pending'] == true) {
          final _pendingOrders = AllPendingOrders(
            rating: element['rating'],
            id: element.id,
            comment: element['comment'],
            canceled: element['canceled'],
            documentCollectionId: element['documentCollectionId'],
            orderRef: element['orderRef'],
            pending: element['pending'],
            token: element['token'],
          );
          pendingOrders.add(_pendingOrders);
          _allPendingOrders = pendingOrders;
          notifyListeners();
        } else {
          final _getAllConfirmedOrders = AllConfirmedOrders(
            rating: element['rating'],
            id: element.id,
            comment: element['comment'],
            canceled: element['canceled'],
            documentCollectionId: element['documentCollectionId'],
            orderRef: element['orderRef'],
            pending: element['pending'],
            token: element['token'],
          );
          getAllConfirmedOrders.add(_getAllConfirmedOrders);
          _allConfirmedOrders = getAllConfirmedOrders;
          notifyListeners();
        }
      });
    });
  }

  Future<Map<String, dynamic>> sendTrackOrderLocation(
      {String collectionGroupId, String docId, LatLng latLng}) async {
    _isLoading = true;
    String message =
        'Error occurred. Check your internet connection and try again';
    notifyListeners();
    try {
      GeoPoint geoPoint = GeoPoint(latLng.latitude, latLng.longitude);
      CollectionReference ref =
          FirebaseFirestore.instance.collection('pendingOrders');
      await ref
          .doc(collectionGroupId)
          .collection('myPendingOrders')
          .doc(docId)
          .update({'dispatcherLocation': geoPoint});
      _isLoading = false;
      message =
          'Order status has been updated. Customer can now track this order progress';
      notifyListeners();
      return {'message': message};
    } on FirebaseException catch (e) {
      _isLoading = false;
      notifyListeners();
      print('error = ${e.code}');
      return {'message': message};
    }
  }

  Future<Map<String, dynamic>> confirmPendingOrders(
      String orderRef, String collectionId) async {
    _isLoading = true;
    String customerToken;
    String message =
        'Error occurred. Check your internet connection and try again';
    notifyListeners();
    Map<String, dynamic> msg = {
      'title': 'Confirmed',
      'body': 'Order has been confirmed'
    };
    try {
      CollectionReference ref = FirebaseFirestore.instance
          .collection('pendingOrders')
          .doc(collectionId)
          .collection('myPendingOrders');
      await ref
          .where('orderRef', isEqualTo: orderRef)
          .get()
          .then((value) async {
        value.docs.forEach((element) async {
          String id = element.id;
          customerToken = element['token'];
          notifyListeners();

          return await FirebaseFirestore.instance
              .collection('pendingOrders')
              .doc(element['documentCollectionId'])
              .collection('myPendingOrders')
              .doc(id)
              .update({'pending': false});
        });
      });
      _isLoading = false;
      message = 'Order Confirmed';
      notifyListeners();
      await SendPushNotifications.sendNotifications(customerToken, msg);
      return {'message': message};
    } on FirebaseException catch (e) {
      print(e.code);
      _isLoading = false;
      notifyListeners();
      return {'message': message};
    }
  }

  Future<Stream<QuerySnapshot>> searchOrder(
      String orderRef, String collectionId) async {
    CollectionReference ref =
        FirebaseFirestore.instance.collection('pendingOrders');
    CollectionReference reference =
        ref.doc(collectionId).collection('myPendingOrders');

    return reference
        .where('orderRef', isEqualTo: '$orderRef')
        .snapshots(includeMetadataChanges: true);
  }

  Future addToMyPurchases({
    String recipientName,
    String recipientNumber,
    String address,
    double addressLng,
    String productId,
    double addressLat,
    String time,
  }) async {
    print('order sent');
    print(_authentication.id);
    GeoPoint geoPoint = GeoPoint(addressLat, addressLng);
    String orderRef = DateTime.now().toIso8601String();

    CollectionReference reference =
        FirebaseFirestore.instance.collection('products');

    await reference.doc(productId).snapshots().forEach((element) async {
      String title = element['title'];

      await FirebaseFirestore.instance
          .collection('pendingOrders')
          .doc(_authentication.id)
          .collection('myPendingOrders')
          .add({
        'orderRef': orderRef,
        'rating': 0,
        'comment': '',
        'pending': true,
        'canceled': false,
        'token': _authentication.token,
        'documentCollectionId': _authentication.id,
        'productId': productId,
        'title': title,
        'noOfOrder': 1,
        'address': address,
        'recipientName': recipientName,
        'recipientNumber': recipientNumber,
        'deleted': false,
        'addressLocation': geoPoint,
        'time': time,
        'dispatcherLocation': null,
        'collectionGroupId': _authentication.id,
      });
      print('productId = $productId');
      print('order added 1');

      await FirebaseFirestore.instance
          .collection('users')
          .where('userType', isEqualTo: 'Dispatcher')
          .snapshots()
          .forEach((element) async {
        print('order added 2');
        element.docs.forEach((result) async {
          Map<String, dynamic> msg = {
            'title': 'Order!',
            'body': 'Pending order request from $recipientName',
          };
          String dispatcherToken = result['token'];
          print('token = $dispatcherToken');
          await SendPushNotifications.sendNotifications(dispatcherToken, msg);
        });
      });
      reference.doc(_authentication.id).delete();
      notifyListeners();
    });
  }

  Future<Map<String, dynamic>> updateSells({
    File image,
    String title,
    String description,
    String price,
  }) async {
    _postUploading = true;
    String _postUploadErrorMessage =
        'Upload failed! Check your internet connection and try again';
    notifyListeners();
    try {
      await upLoadPicture(image, 'product Image');
      Map<String, dynamic> goods = {
        'title': title,
        'image': _profileImageUrl,
        'description': description,
        'price': price,
        'disabled': false,
      };
      CollectionReference reference =
          FirebaseFirestore.instance.collection('products');
      await reference.add(goods);
      _postUploading = false;
      _postUploadErrorMessage = 'Upload was successful';
      notifyListeners();
      return {
        'uploadError': _postUploading,
        'success': _postUploadErrorMessage
      };
    } catch (error) {
      print(error);
      _postUploading = false;
      notifyListeners();
      return {
        'uploadError': _postUploading,
        'success': _postUploadErrorMessage
      };
    }
  }

  Future<Stream<DocumentSnapshot>> getProduct(String id) async {
    CollectionReference reference =
        FirebaseFirestore.instance.collection('products');
    return reference.doc(id).snapshots();
  }

  Future<Stream<QuerySnapshot>> fetchProducts() async {
    CollectionReference reference =
        FirebaseFirestore.instance.collection('products');
    return reference.snapshots(includeMetadataChanges: true);
  }

  rating({
    int rate,
    String id,
    String documentCollectionId,
    String comment,
  }) async {
    CollectionReference reference = FirebaseFirestore.instance
        .collection('pendingOrders')
        .doc(documentCollectionId)
        .collection('myPendingOrders');
    await reference.doc(id).update({
      'rating': rate,
      'comment': comment,
    });
    notifyListeners();
  }

  Future upLoadPicture(File uploadedImage, String path) async {
    FirebaseStorage fireBaseStorage = FirebaseStorage.instance;
    final imagePath = File(uploadedImage.path);
    try {
      if (uploadedImage == null) {
        return;
      }
      Reference reference = fireBaseStorage.ref('$path/$imagePath');
      UploadTask uploadTask =
          fireBaseStorage.ref('$path/$imagePath').putFile(imagePath);
      TaskSnapshot taskSnapshot = await uploadTask;
      print('Uploaded ${taskSnapshot.bytesTransferred} bytes.');
      String downloadURL = await reference.getDownloadURL();
      print(downloadURL);
      _profileImageUrl = downloadURL;
      _image = null;
      notifyListeners();
    } on FirebaseException catch (e) {
      print(e);
    }
  }

  bool successful = false;

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    Users(
      id: '',
      email: '',
      userType: '',
      token: '',
    );
    _isLoading = true;
    notifyListeners();

    CollectionReference users = FirebaseFirestore.instance.collection('users');
    FirebaseAuth fireBaseAuth = FirebaseAuth.instance;
    FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
    String message =
        'Something went wrong, invalid password or Phone number/email';
    notifyListeners();
    try {
      if (email.contains('@')) {
        await fireBaseAuth.signInWithEmailAndPassword(
            email: email.toString().trim(), password: password);
        fireBaseAuth.authStateChanges().listen((user) async {
          Future<DocumentSnapshot> future = users.doc(user.uid).get();
          future.asStream().listen((event) async {
            String userType = event['userType'];
            print('userType1 = $userType');
            String fcmToken = await firebaseMessaging.getToken();
            _authentication = Users(
              id: user.uid,
              email: user.email,
              number: user.phoneNumber,
              userType: userType,
              token: fcmToken,
            );
            print(user.phoneNumber);
            print(user.email);
          });
        });
        successful = true;
        notifyListeners();
      } else {
        if (users.path.isNotEmpty) {
          await users
              .where('number', isEqualTo: email)
              .get()
              .then((value) async {
            if (value.size > 0) {
              successful = true;
              print('$successful 1');
              value.docs.forEach((element) async {
                if (password == element['password']) {
                  String userType = element['userType'];
                  String email = element['email'];
                  String number = element['number'];
                  print('userType1 = $userType');
                  String fcmToken = await firebaseMessaging.getToken();
                  _authentication = Users(
                    id: element.id,
                    email: email,
                    number: number,
                    userType: userType,
                    token: fcmToken,
                  );
                  await users.doc(element.id).update({
                    'token': fcmToken,
                  });
                  print('userType2 = $userType');
                } else {
                  message = 'Incorrect password';
                  successful = false;
                }
                return successful;
              });
              notifyListeners();
            } else {
              message = 'Phone number not found';
              successful = false;
              notifyListeners();
            }
          });
        } else {
          message = 'Phone number not found';
          successful = false;
          notifyListeners();
        }
      }
      _isLoading = false;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        message = 'Email not found';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      } else if (e.code == 'network-request-failed') {
        message = 'Poor or no data connection! Check your internet connection and try again';
      } else {
        print('error= ${e.code}');
        message = 'something went wrong';
      }
      successful = false;
      _isLoading = false;
      notifyListeners();
    }
    return {'success': successful, 'message': message};
  }

  Future<Map<String, dynamic>> signUp(
      {String userType,
      String email,
      String password,
      String number,
      User user}) async {
    FirebaseAuth fireBaseAuth = FirebaseAuth.instance;
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    _isLoading = true;
    // bool successful = false;
    String message = 'Something went wrong';
    notifyListeners();
    try {
      if (user != null) {
        AuthCredential emailAuthProvider =
            EmailAuthProvider.credential(email: email, password: password);
        user.linkWithCredential(emailAuthProvider);
      } else {
        await fireBaseAuth.createUserWithEmailAndPassword(
            email: '$email', password: '$password');
      }
      fireBaseAuth.authStateChanges().listen((user) async {
        Map<String, dynamic> userData = {
          'userId': user.uid,
          'userType': userType,
          'email': email,
          'password': password,
          'number': number,
        };
        users.doc(user.uid).set(userData);
      });
      successful = true;
      _isLoading = false;
      message = 'Sign up was successful';
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      if (user != null) {
        user.delete();
      }
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak';
      } else if (e.code == 'email-already-in-use') {
        message = 'Email already exist, try sign-in';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      } else {
        print(e.code.toString());
      }
    }
    _isLoading = false;
    notifyListeners();
    return {'success': successful, 'message': message};
  }
}
