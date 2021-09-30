import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:flutter_paystack/flutter_paystack.dart';
import 'package:geocoder/geocoder.dart';
import 'package:location/location.dart';
import 'package:test_project/model.dart';
import 'package:test_project/payment_widget.dart';
import 'package:scoped_model/scoped_model.dart';

import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_maps_webservice/places.dart' as mapServices;

const String publicKey = "FLWPUBK-4837c9ced334002ae4ca39607fa95643-X";
const String encryptionKey = "d74fee9aabaaf84234b018e4";

class OrderDetails extends StatefulWidget {
  final int amount;
  final String productId;

  OrderDetails({this.productId, this.amount});

  @override
  _OrderDetailsState createState() => _OrderDetailsState();
}

class _OrderDetailsState extends State<OrderDetails> {
  Location location = Location();
  LocationData _currentPosition;
  FocusNode focus = FocusNode();

  String recipientNumber = '';
  double addressLng;
  double addressLat;
  String address = '';
  String time = '';
  String recipientName = '';

  final formKey = GlobalKey<FormState>();

  final homeScaffoldKey = GlobalKey<ScaffoldState>();
  Mode _mode = Mode.overlay;
  final plugin = PaystackPlugin();

  // String kGoogleApiKey = "AIzaSyAUapqaUPAZV1XpHyxXZlsdzCAY2jKr0ds";
  String kGoogleApiKey = "AIzaSyA0cxVu_vA4i-GE-I6EB0EcOdGHMomb5VQ";

  bool _serviceEnabled;

  @override
  initState() {
    plugin.initialize(
        publicKey: 'pk_live_b09f6b969c2ada70f3232547e8d0e5330abba0e6');
    super.initState();
  }

  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  requestPermission() async {
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

  Future<List<Address>> _getAddress(double lat, double lang) async {
    final coordinates = new Coordinates(lat, lang);
    List<Address> add =
        await Geocoder.local.findAddressesFromCoordinates(coordinates);
    return add;
  }

  Future<void> _handlePressButton() async {
    // show input autocomplete with selected mode
    // then get the Prediction selected
    mapServices.Prediction p = await PlacesAutocomplete.show(
      context: context,
      apiKey: kGoogleApiKey,
      onError: onError,
      mode: _mode,
      language: "ng",
      strictbounds: false,
      types: [''],
      decoration: InputDecoration(
        hintText: 'Search',
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: Colors.white,
          ),
        ),
      ),
      components: [mapServices.Component(mapServices.Component.country, "ng")],
    );

    displayPrediction(p, homeScaffoldKey.currentState);
  }

  Future<Null> displayPrediction(
      mapServices.Prediction p, ScaffoldState scaffold) async {
    if (p != null) {
      // get detail (lat/lng)
      mapServices.GoogleMapsPlaces _places = mapServices.GoogleMapsPlaces(
        apiKey: kGoogleApiKey,
        apiHeaders: await GoogleApiHeaders().getHeaders(),
      );
      mapServices.PlacesDetailsResponse detail =
          await _places.getDetailsByPlaceId(p.placeId);
      double lat = detail.result.geometry.location.lat;
      double lng = detail.result.geometry.location.lng;
      _getAddress(lat, lng).then((value) {
        setState(() {
          addressLng = lng;
          addressLat = lat;
          address = '${value.first.addressLine}';
        });
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${p.description} - $lat/$lng")),
      );
    }
  }

  void onError(mapServices.PlacesAutocompleteResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response.errorMessage)),
    );
  }

  Widget errorText = Container();

  setErrorText() {
    if (pmOrAm == null && _hr != null && _hr < 13) {
      errorText = Text(
        'Choose a day time',
        style: TextStyle(color: Colors.red, fontSize: 12),
      );
    } else if (pmOrAm != null && (hr == null || min == null)) {
      errorText = Text(
        'Enter a valid time',
        style: TextStyle(color: Colors.red, fontSize: 12),
      );
    } else {
      errorText = Container();
    }
  }

  makePayment(Models model) {
    setState(() {
      setErrorText();
    });
    if (formKey.currentState.validate()) {
      if (pmOrAm == null && _hr != null && _hr < 13) {
        return null;
      } else if (pmOrAm != null && (hr == null || min == null)) {
        return null;
      } else {
        int amount = widget.amount * 100;
        print('amount = $amount');

        formKey.currentState.save();
        PaymentWidget.handlePaymentInitialization(
          amount: amount,
          setLoading: setLoading,
          plugin: plugin,
          context: context,
          email: model.authentication.email,
          model: model,
          addressLng: addressLng,
          addressLat: addressLat,
          time: '$hr:$min $pmOrAm',
          number: recipientNumber,
          isCart: true,
          address: address,
          productId: widget.productId,
          recipientName: recipientName,
        );
      }
    }
  }

  dialog(Models model) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        elevation: 10,
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
        title: Text('Sorry!'),
        content: Text(
            'Delivery currently not available in your specified address. We currently deliver to areas within ${locations.toString().replaceAll('[', '').replaceAll(']', '')}.\nIf your address is within one of these areas, please try specifying it in the address field'),
      ),
    );
  }

  int i = 0;
  List<String> locations = [];

  bool isLoading = false;

  setLoading(bool set) {
    setState(() {
      isLoading = set;
    });
  }

  Padding dropArrow() {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Icon(Icons.arrow_drop_down, color: Colors.black),
    );
  }

  String pmOrAm;
  String hr;
  String min;
  int _min;
  int _hr;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: homeScaffoldKey,
      appBar: AppBar(
        title: Text('Enter Order Details'),
      ),
      body: ScopedModelDescendant<Models>(
          builder: (context, child, Models model) {
        return SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(10),
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  SizedBox(height: 30),
                  Column(
                    children: [
                      Row(
                        children: [
                          address.isEmpty
                              ? Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: TextFormField(
                                      initialValue: address,
                                      onTap: () => _handlePressButton(),
                                      decoration: InputDecoration(
                                        hintText: 'Enter recipient address',
                                      ),
                                      onChanged: (value) {
                                        if (address.isNotEmpty) {
                                          setState(() {
                                            value = address;
                                          });
                                        }
                                      },
                                      validator: (value) => value.isEmpty
                                          ? 'enter address'
                                          : null,
                                    ),
                                  ),
                                )
                              : Expanded(
                                  child: Container(
                                    margin: EdgeInsets.only(left: 5, right: 5),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Location:',
                                          style:
                                              TextStyle(color: Colors.black54),
                                        ),
                                        SingleChildScrollView(
                                          child: Text('$address'),
                                          scrollDirection: Axis.horizontal,
                                        ),
                                        Divider(color: Colors.black87),
                                      ],
                                    ),
                                  ),
                                ),
                          address.isNotEmpty
                              ? Container()
                              : Row(
                                  children: [
                                    Text('OR'),
                                    Container(
                                      child: TextButton(
                                        child: Text('Send current location'),
                                        onPressed: () async {
                                          requestPermission();
                                          _currentPosition =
                                              await location.getLocation();
                                          setState(() {});
                                          if (_serviceEnabled == true) {
                                            print(
                                                '_currentPosition = $_currentPosition');
                                            double lat =
                                                _currentPosition.latitude;
                                            double lng =
                                                _currentPosition.longitude;
                                            _getAddress(lat, lng).then((value) {
                                              setState(() {
                                                addressLng = lng;
                                                addressLat = lat;
                                                address =
                                                    '${value.first.addressLine}';
                                                print('address = $address');
                                              });
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          decoration: InputDecoration(
                            hintText: 'Enter name',
                          ),
                          onChanged: (value) {
                            setState(() {
                              recipientName = value;
                            });
                          },
                          validator: (value) =>
                              value.isEmpty ? 'enter name' : null,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          validator: (value) => value.isEmpty
                              ? 'enter your contact number'
                              : null,
                          decoration: InputDecoration(
                            hintText: 'Enter contact number',
                          ),
                          onChanged: (value) {
                            setState(() {
                              recipientNumber = value;
                            });
                          },
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(left: 8),
                        child: Row(
                          children: [
                            Text(
                              'Enter delivery time',
                              style: TextStyle(
                                  fontSize: 17, color: Colors.black54),
                            ),
                            SizedBox(width: 8),
                            Row(
                              children: [
                                Container(
                                  width: 30,
                                  child: Column(
                                    children: [
                                      Text(
                                        'Hr',
                                        style: TextStyle(
                                            fontSize: 17,
                                            color: Colors.black54),
                                      ),
                                      TextFormField(
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value.contains(',') ||
                                              value.contains('.') ||
                                              value.contains('-') ||
                                              value.contains(' ') ||
                                              value.isEmpty ||
                                              _hr > 23) {
                                            return 'hr';
                                          } else {
                                            return null;
                                          }
                                        },
                                        onChanged: (value) {
                                          setState(() {
                                            _hr = int.tryParse(value);
                                            hr = value;
                                            if (value.length == 2) {
                                              focus.requestFocus();
                                            }
                                          });
                                        },
                                      )
                                    ],
                                  ),
                                ),
                                Text(':'),
                                Container(
                                  width: 30,
                                  child: Column(
                                    children: [
                                      Text(
                                        'Min',
                                        style: TextStyle(
                                            fontSize: 17,
                                            color: Colors.black54),
                                      ),
                                      TextFormField(
                                        focusNode: focus,
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value.contains(',') ||
                                              value.contains('.') ||
                                              value.contains('-') ||
                                              value.contains(' ') ||
                                              value.isEmpty ||
                                              _min > 59) {
                                            return 'min';
                                          } else {
                                            return null;
                                          }
                                        },
                                        onChanged: (value) {
                                          setState(() {
                                            _min = int.tryParse(value);
                                            min = value;
                                          });
                                        },
                                      )
                                    ],
                                  ),
                                ),
                                pmOrAm == null
                                    ? Container(width: 8)
                                    : Container(
                                        width: 30,
                                        margin: EdgeInsets.only(right: 8),
                                        child: Text(pmOrAm),
                                      ),
                                Column(
                                  children: [
                                    Row(
                                      children: [
                                        GestureDetector(
                                          child: Container(
                                            padding: EdgeInsets.all(5),
                                            margin: EdgeInsets.only(right: 8),
                                            color: Colors.grey,
                                            child: Text(
                                              'AM',
                                            ),
                                          ),
                                          onTap: () {
                                            setState(() {
                                              pmOrAm = 'AM';
                                            });
                                          },
                                        ),
                                        GestureDetector(
                                          child: Container(
                                            padding: EdgeInsets.all(5),
                                            color: Colors.grey,
                                            child: Text(
                                              'PM',
                                            ),
                                          ),
                                          onTap: () {
                                            setState(() {
                                              pmOrAm = 'PM';
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      errorText,
                      SizedBox(height: 30),
                      Container(
                        margin: EdgeInsets.only(top: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Theme.of(context).primaryColor,
                        ),
                        width: double.infinity,
                        child: MaterialButton(
                          height: 50,
                          child: isLoading == true
                              ? Padding(
                                  padding: const EdgeInsets.all(5.0),
                                  child: CircularProgressIndicator(),
                                )
                              : Text('Make Payment'),
                          onPressed: () {
                            makePayment(model);
                          },
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
