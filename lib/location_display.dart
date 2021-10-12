import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:test_project/model.dart';

class MyLocation extends StatefulWidget {
  final GeoPoint geoPoint;
  final bool isDispatcher;
  final Models model;
  final String collectionId;
  final String id;

  MyLocation({
    this.geoPoint,
    this.collectionId,
    this.id,
    this.model,
    this.isDispatcher,
  });

  @override
  _MyLocationState createState() => _MyLocationState();
}

class _MyLocationState extends State<MyLocation> {
  Location location = Location();
  LatLng _initialCameraPosition = LatLng(42.747932, -71.167889);

  LocationData currentLocation;
  double bearing = 30;
  double tilt = 80;
  double zoom = 16;

  Set<Marker> markers = Set<Marker>();
  Set<Polyline> polyline = Set<Polyline>();
  PolylinePoints polylinePoints;
  List<LatLng> polylineCoordinate = [];
  Completer<GoogleMapController> _controller = Completer();
  StreamSubscription streamSubscription;
  LocationData destinationLocation;

  getLoc() {
    location.onLocationChanged.listen((event) {
      currentLocation = event;
      updatePinOnMap();
    });
  }

  updatePinOnMap() async {
    CameraPosition position = CameraPosition(
        target: LatLng(currentLocation.latitude, currentLocation.longitude),
        zoom: zoom,
        tilt: tilt,
        bearing: bearing);
    GoogleMapController _googleMapController = await _controller.future;
    _googleMapController
        .animateCamera(CameraUpdate.newCameraPosition(position))
        .onError((error, stackTrace) {
      _googleMapController.dispose();
      return null;
    });
    LatLng pinPosition =
        LatLng(currentLocation.latitude, currentLocation.longitude);
    markers.removeWhere((element) => element.markerId.value == 'sourcePin');
    markers.add(Marker(
      markerId: MarkerId('sourcePin'),
      position: pinPosition,
    ));
  }

  Future setInitialLocation() async {
    currentLocation = await location.getLocation();
    setState(() {});
    print('currentLocation = $currentLocation');
    setState(() {
      destinationLocation = LocationData.fromMap({
        "latitude": widget.geoPoint.latitude,
        "longitude": widget.geoPoint.longitude
      });
    });
    print('destinationLocation1 = $destinationLocation');
  }

  final LatLng initialCameraPosition =
      LatLng(37.42796133580664, -122.085749655962);
  final String googleAPIKey = 'API_KEY';

  showPinsOnMap() {
    LatLng pinPosition =
        LatLng(currentLocation.latitude, currentLocation.longitude);
    LatLng desPosition =
        LatLng(destinationLocation.latitude, destinationLocation.longitude);
    markers.add(Marker(
      markerId: MarkerId('sourcePin'),
      position: pinPosition,
    ));
    markers.add(Marker(
      markerId: MarkerId('desPin'),
      position: desPosition,
    ));
    setPolyLines();
  }

  void setPolyLines() async {
    PointLatLng pointOrigin =
        PointLatLng(currentLocation.latitude, currentLocation.longitude);
    PointLatLng pointDestination = PointLatLng(
        destinationLocation.latitude, destinationLocation.longitude);
    print('pointOrigin = $pointOrigin');
    print('pointDestination = $pointDestination');
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleAPIKey, pointOrigin, pointDestination);
    print('result = ${result.points}');
    if (result.errorMessage.isEmpty) {
      result.points.forEach((element) {
        polylineCoordinate.add(LatLng(element.latitude, element.longitude));
      });
      print('set polys');
      setState(() {
        polyline.add(Polyline(
            width: 5,
            polylineId: PolylineId("poly"),
            color: Color.fromARGB(255, 40, 122, 198),
            points: polylineCoordinate));
      });
      print('poly added');
    } else {
      print('errorMessage = ${result.errorMessage}');
    }
  }

  @override
  void initState() {
    super.initState();
    polylinePoints = PolylinePoints();
    location.onLocationChanged.listen((event) {
      currentLocation = event;
      updatePinOnMap();
      if (widget.isDispatcher == true) {
        LatLng currentPosition = LatLng(event.latitude, event.longitude);
        widget.model.sendTrackOrderLocation(
            collectionGroupId: widget.collectionId,
            docId: widget.id,
            latLng: currentPosition);
      }
    });
    setInitialLocation();
  }

  @override
  void dispose() {
    if (streamSubscription != null) {
      streamSubscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    CameraPosition initialCameraPosition = CameraPosition(
        target: _initialCameraPosition,
        zoom: zoom,
        tilt: tilt,
        bearing: bearing);

    if (currentLocation != null) {
      initialCameraPosition = CameraPosition(
          target: LatLng(currentLocation.latitude, currentLocation.longitude),
          bearing: bearing,
          tilt: tilt,
          zoom: zoom);
    }

    return WillPopScope(
      onWillPop: () async {
        print('will pop was called');
        return true;
      },
      child: Container(
        padding: EdgeInsets.all(5),
        color: Colors.blueGrey,
        height: MediaQuery.of(context).size.height / 2.5,
        width: MediaQuery.of(context).size.width,
        child: GoogleMap(
          initialCameraPosition: initialCameraPosition,
          mapType: MapType.normal,
          markers: markers,
          tiltGesturesEnabled: true,
          zoomGesturesEnabled: true,
          zoomControlsEnabled: true,
          rotateGesturesEnabled: true,
          compassEnabled: true,
          myLocationButtonEnabled: true,
          scrollGesturesEnabled: true,
          polylines: polyline,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
            if (currentLocation != null) {
              print('not null');
              showPinsOnMap();
            }
          },
          myLocationEnabled: true,
        ),
      ),
    );
  }
}
