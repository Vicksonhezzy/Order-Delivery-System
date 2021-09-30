import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:test_project/location_display.dart';
import 'package:test_project/model.dart';
import 'package:test_project/view_product_page.dart';

class MyOrderDetails extends StatefulWidget {
  final String orderRef;
  final String title;
  final String documentCollectionId;
  final String orderId;
  final Models models;
  final bool pending;

  const MyOrderDetails(
      {this.orderRef,
      this.pending,
      this.documentCollectionId,
      this.orderId,
      this.title,
      this.models});

  @override
  _MyOrderDetailsState createState() => _MyOrderDetailsState();
}

class _MyOrderDetailsState extends State<MyOrderDetails> {
  Stream<QuerySnapshot> stream;
  Location location = Location();
  LocationData _currentPosition;
  LatLng _initialCameraPosition;

  GeoPoint geoPoint;

  String searchValue;
  Widget createMap = Container();

  LocationData currentLocation;
  StreamSubscription _streamSubscription;

  getStream([String search]) {
    print('order ref = ${widget.orderRef}');
    print('order ref = $search');
    int index = widget.models.viewAllPendingOrders
        .indexWhere((element) => element.orderRef == search);
    if (widget.orderRef == null) {
      print('index = $index');
      if (index != -1) {
        widget.models
            .searchOrder(search,
                widget.models.viewAllPendingOrders[index].documentCollectionId)
            .then((value) {
          setState(() {
            stream = value;
          });
        });
      }
      setState(() {
        stream = null;
      });
    } else {
      widget.models
          .searchOrder(widget.orderRef, widget.documentCollectionId)
          .then((value) {
        setState(() {
          stream = value;
        });
        print('stream length = ${value.length} 2');
      });
    }
  }

  requestPermission() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return Navigator.pop(context);
      }
    }
  }

  @override
  initState() {
    super.initState();
    requestPermission();
    getStream();
  }

  @override
  void dispose() {
    if (_streamSubscription != null) {
      _streamSubscription.cancel();
    }
    super.dispose();
  }

  _buildListTile(int index, QuerySnapshot data, Models model) {
    return Container(
      margin: EdgeInsets.all(5),
      child: ListTile(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewProductPage(
                productId: data.docs[index]['productId'],
                model: model,
                view: true,
              ),
            )),
        title: Text(
          '${data.docs[index]['title']}',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          children: [
            Text(
              data.docs[index]['noOfOrder'] < 2
                  ? '${data.docs[index]['noOfOrder']}' + ' order'
                  : '${data.docs[index]['noOfOrder']}' + 'orders',
              style: TextStyle(fontWeight: FontWeight.w400),
            ),
            Text('Tap for more details'),
          ],
        ),
      ),
    );
  }

  Widget _addItemInfo(int index, QuerySnapshot data, Models model) {
    return Column(
      children: [
        _buildListTile(index, data, model),
        Divider(),
      ],
    );
  }

  GeoPoint dispatcherLocation;

  Widget _listBuilder(
      AsyncSnapshot<QuerySnapshot> snapshot, int index, Models model) {
    GeoPoint start = snapshot.data.docs[index]['addressLocation'];
    dispatcherLocation = snapshot.data.docs[index]['dispatcherLocation'];
    double distance = dispatcherLocation == null
        ? null
        : Geolocator.distanceBetween(start.latitude, start.longitude,
            dispatcherLocation.latitude, dispatcherLocation.longitude);
    return snapshot.data.docs.isEmpty
        ? widget.orderRef == null
            ? Container(
                child: Center(
                  child: Text('Enter a valid Order Code'),
                ),
              )
            : Container(
                child: Center(
                  child: Text('This order has been confirmed'),
                ),
              )
        : Container(
            margin: EdgeInsets.only(left: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Text(
                        'Name: ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${snapshot.data.docs[index]['recipientName']}',
                        style: TextStyle(
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Text(
                        'Number: ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${snapshot.data.docs[index]['recipientNumber']}',
                        style: TextStyle(
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Text(
                          'Address: ',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${snapshot.data.docs[index]['address']}',
                          style: TextStyle(
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                dispatcherLocation == null || widget.pending != true
                    ? Container()
                    : Container(
                        margin: EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Distance: ',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$distance' + ' meters',
                              style: TextStyle(
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                Container(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemBuilder: (BuildContext context, index) {
                      return _addItemInfo(index, snapshot.data, model);
                    },
                    itemCount: snapshot.data.docs.length,
                  ),
                ),
              ],
            ),
          );
  }

  TextEditingController _textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: ScopedModelDescendant<Models>(
          builder: (context, child, Models model) {
        return StreamBuilder<QuerySnapshot>(
            stream: stream,
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    widget.orderRef == null
                        ? Container(
                            padding: EdgeInsets.all(5),
                            alignment: Alignment.topCenter,
                            width: double.infinity,
                            margin: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: Colors.white,
                            ),
                            child: TextField(
                              controller: _textEditingController,
                              onChanged: (value) {
                                if (value.length > 20) {
                                  getStream(value);
                                  searchValue = value;
                                }
                              },
                              onSubmitted: (value) {
                                setState(() {
                                  getStream(value);
                                  searchValue = value;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Enter Order Reference Code...',
                                hintStyle: TextStyle(color: Colors.grey),
                                border: InputBorder.none,
                                suffixIcon: _textEditingController.text.isEmpty
                                    ? null
                                    : IconButton(
                                        icon: Icon(Icons.clear,
                                            color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            searchValue = null;
                                            _textEditingController.clear();
                                          });
                                        },
                                      ),
                                icon: Icon(
                                  Icons.search,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          )
                        : Container(),
                    snapshot.connectionState == ConnectionState.waiting
                        ? Center(
                            child: CircularProgressIndicator(),
                          )
                        : snapshot.hasData != true
                            ? Center(
                                child: Text('No Order'),
                              )
                            : ListView.builder(
                                itemCount: snapshot.data.docs.length,
                                shrinkWrap: true,
                                itemBuilder: (context, index) {
                                  return Column(
                                    children: [
                                      Container(
                                        alignment: Alignment.topCenter,
                                        margin: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          color: Colors.grey,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.info,
                                              color: Colors.blueGrey,
                                            ),
                                            Text('Order ref Code: '),
                                            SelectableText(
                                              widget.orderRef == null
                                                  ? '${snapshot.data.docs[index]['orderRef']}'
                                                  : '${widget.orderRef}',
                                              toolbarOptions: ToolbarOptions(
                                                copy: true,
                                                cut: false,
                                                paste: false,
                                                selectAll: true,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      model.authentication.userType ==
                                                  'Dispatcher' &&
                                              widget.orderRef == null
                                          ? Container(
                                              alignment: Alignment.center,
                                              child: textButton(
                                                text: 'CONFIRM ORDER',
                                                data: snapshot.data.docs[index],
                                                model: model,
                                                isConfirm: true,
                                                color: Colors.green,
                                              ),
                                            )
                                          : model.authentication.userType ==
                                                      'Dispatcher' &&
                                                  (widget.pending == true ||
                                                      widget.pending == null)
                                              ? Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    snapshot.data.docs[index][
                                                                'dispatcherLocation'] ==
                                                            null
                                                        ? textButton(
                                                            text: 'TAKE ORDER',
                                                            data: snapshot.data
                                                                .docs[index],
                                                            model: model,
                                                            color:
                                                                Colors.orange,
                                                          )
                                                        : Container(),
                                                  ],
                                                )
                                              : Container(),
                                      Container(
                                        padding:
                                            EdgeInsets.symmetric(horizontal: 8),
                                        child: averageRating(model, snapshot),
                                      ),
                                      widget.orderRef == null
                                          ? SizedBox(height: 15)
                                          : Container(),
                                      bodyBuilder(model, snapshot, index),
                                      // createMap,
                                    ],
                                  );
                                }),
                  ],
                ),
              );
            });
      }),
    );
  }

  final formKey = GlobalKey<FormState>();

  String comment;
  int noOfStar;

  IconButton iconButton(
      {Models model, int rate, AsyncSnapshot<QuerySnapshot> snapshot}) {
    return IconButton(
      icon: Icon(
        Icons.star_border,
        color: Colors.grey,
      ),
      onPressed: () {
        setState(() {
          noOfStar = rate;
        });
        commentDialog(model, snapshot);
      },
    );
  }

  submit({Models model, String collectionId, String id}) {
    if (formKey.currentState.validate()) {
      formKey.currentState.save();
      editRating(
        model: model,
        collectionId: collectionId,
        id: id,
        rate: noOfStar,
        comment: comment,
      );
      Navigator.pop(context);
    }
    return null;
  }

  commentDialog(Models model, AsyncSnapshot<QuerySnapshot> snapshot) {
    if (snapshot.data.docs[0]['rating'] > 0) {
      setState(() {
        comment = snapshot.data.docs[0]['comment'];
      });
    } else {
      setState(() {
        comment = '';
      });
    }
    showDialog(
      useSafeArea: true,
      context: context,
      builder: (context) => Center(
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.white,
            ),
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  Container(
                    // margin: EdgeInsets.symmetric(vertical: 5),
                    alignment: Alignment.topCenter,
                    child: showStarDialog(noOfStar),
                  ),
                  Container(
                    // margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Material(
                      elevation: 2,
                      borderRadius: BorderRadius.circular(15),
                      child: TextFormField(
                        initialValue: comment,
                        maxLines: 5,
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'enter comment';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.edit),
                            hintText: 'Comment...'),
                        onChanged: (value) {
                          setState(() {
                            comment = value;
                          });
                        },
                        onSaved: (newValue) {
                          setState(() {
                            comment = newValue;
                          });
                        },
                        onFieldSubmitted: (newValue) {
                          setState(() {
                            comment = newValue;
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Material(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(30),
                    child: TextButton(
                      child: Text(
                        'POST',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () => submit(
                          model: model,
                          id: snapshot.data.docs[0].id,
                          collectionId: snapshot.data.docs[0]
                              ['documentCollectionId']),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Icon rateIcon(int whole, double half, AsyncSnapshot<QuerySnapshot> snapshot) {
    double num =
        double.parse(snapshot.data.docs[0]['rating'].toStringAsFixed(1));
    return Icon(
      num >= whole
          ? Icons.star
          : num < whole && num >= half
              ? Icons.star_half
              : Icons.star_border,
      color: Colors.orange,
    );
  }

  Container showStarDialog(int index, [bool noSpace]) {
    return Container(
      // width: 80,
      padding: noSpace == true ? EdgeInsets.only(right: 250) : null,
      child: GridView.builder(
        itemCount: index,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate:
            SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
        itemBuilder: (context, index) => Icon(
          Icons.star,
          color: Colors.orange,
          size: noSpace == true ? 12 : null,
        ),
      ),
    );
  }

  showCommentsDialog(AsyncSnapshot<QuerySnapshot> snapshot) {
    showDialog(
      useSafeArea: true,
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 100),
        margin: EdgeInsets.symmetric(vertical: 100),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.white70,
          ),
          padding: EdgeInsets.all(10),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(bottom: 8),
                alignment: Alignment.topLeft,
                child: Text(
                  'Comments:',
                  style: TextStyle(
                    fontSize: 15,
                    decoration: TextDecoration.none,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              Container(
                child: ListView.builder(
                  itemCount: 1,
                  shrinkWrap: true,
                  itemBuilder: (context, index) => Container(
                    margin: EdgeInsets.only(bottom: 10),
                    child: Material(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      elevation: 8,
                      child: Container(
                        padding: EdgeInsets.all(10),
                        child: Column(
                          children: [
                            Container(
                              alignment: Alignment.topLeft,
                              child: showStarDialog(
                                  snapshot.data.docs[index]['rating'], true),
                            ),
                            Container(
                              alignment: Alignment.topLeft,
                              child: Text(
                                  '${snapshot.data.docs[index]['comment']}'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Row rateRow(Models model, AsyncSnapshot<QuerySnapshot> snapshot, int index) {
    double num =
        double.parse((snapshot.data.docs[index]['rating']).toStringAsFixed(1));
    return Row(
      children: [
        Text(
          'Delivery Rating: ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        rateIcon(1, 0.5, snapshot),
        rateIcon(2, 1.5, snapshot),
        rateIcon(3, 2.5, snapshot),
        rateIcon(4, 3.5, snapshot),
        rateIcon(5, 4.5, snapshot),
        Text(' ($num)'),
        TextButton(
          onPressed: () {
            if (snapshot.data.docs[0]['rating'] < 1) {
              return null;
            } else {
              showCommentsDialog(snapshot);
            }
          },
          child: Text(
            'Comment',
            style: TextStyle(color: Colors.blueAccent),
          ),
        )
      ],
    );
  }

  editRating({
    Models model,
    int rate,
    String comment,
    String id,
    String collectionId,
  }) {
    setState(() {
      model.rating(
        rate: rate,
        documentCollectionId: collectionId,
        id: id,
        comment: comment,
      );
    });
  }

  Widget averageRating(Models model, AsyncSnapshot<QuerySnapshot> snapshot) {
    return ListView.builder(
      itemCount: snapshot.data.docs.length,
      shrinkWrap: true,
      itemBuilder: (context, index) => rateRow(model, snapshot, index),
    );
  }

  Container rateBox(Models model, AsyncSnapshot<QuerySnapshot> snapshot) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          Text(
            'Rate: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              iconButton(model: model, rate: 1, snapshot: snapshot),
              iconButton(model: model, rate: 2, snapshot: snapshot),
              iconButton(model: model, rate: 3, snapshot: snapshot),
              iconButton(model: model, rate: 4, snapshot: snapshot),
              iconButton(model: model, rate: 5, snapshot: snapshot),
            ],
          )
        ],
      ),
    );
  }

  bool loading = false;

  Container textButton(
      {String text,
      Color color,
      bool isConfirm,
      Models model,
      QueryDocumentSnapshot<Object> data}) {
    return Container(
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(15)),
      child: loading == true
          ? CircularProgressIndicator()
          : TextButton(
              child: Text(
                text,
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                setState(() {
                  loading = true;
                });
                if (isConfirm == true) {
                  model
                      .confirmPendingOrders(
                          searchValue, data['documentCollectionId'])
                      .then(
                        (value) => alertDialog(value),
                      );
                } else {
                  _currentPosition = await location.getLocation();
                  _initialCameraPosition = LatLng(
                      _currentPosition.latitude, _currentPosition.longitude);
                  setState(() {
                    loading = false;
                  });
                  alertDialog({
                    'message':
                        "This will send the dispatcher's current location to the customer to enable real-time order tracking",
                    'collectionId': data['collectionGroupId'],
                    'id': data.id,
                  }, model);
                }
              },
            ),
    );
  }

  Widget bodyBuilder(
      Models model, AsyncSnapshot<QuerySnapshot> snapshot, int index) {
    if (snapshot.hasData == true) {
      return Column(
        children: [
          _listBuilder(snapshot, index, model),
          widget.orderRef == null ? Container() : rateBox(model, snapshot),
          widget.pending != true || widget.orderRef == null
              ? Container()
              : Container(
                  child: TextButton(
                      child: Text('Track Order'),
                      onPressed: () async {
                        if (widget.orderRef != null &&
                            snapshot.data.docs[index]['dispatcherLocation'] ==
                                null) {
                          return null;
                        } else {
                          setState(() {
                            geoPoint = widget.orderRef == null
                                ? snapshot.data.docs[index]['addressLocation']
                                : snapshot.data.docs[index]
                                    ['dispatcherLocation'];
                          });
                          setState(() {
                            createMap = MyLocation(
                              geoPoint: geoPoint,
                              model: model,
                              id: snapshot.data.docs[index].id,
                              collectionId: snapshot.data.docs[index]
                                  ['collectionGroupId'],
                              isDispatcher: widget.orderRef == null,
                            );
                          });
                          mapDialog();
                        }
                      }),
                ),
        ],
      );
    } else {
      return Center(child: Text('No Order'));
    }
  }

  mapDialog() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text('Track Delivery'),
              content: Container(
                child: createMap,
              ),
            ));
  }

  alertDialog(Map<String, dynamic> value, [Models model]) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Message'),
        content: Text(value['message']),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () {
              if (value.containsKey('collectionId')) {
                model
                    .sendTrackOrderLocation(
                        collectionGroupId: value['collectionId'],
                        docId: value['id'],
                        latLng: _initialCameraPosition)
                    .then((value) {
                  alertDialog(value);
                });
                Navigator.pop(context);
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
}
