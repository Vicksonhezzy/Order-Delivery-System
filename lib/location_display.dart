
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MyLocation extends StatelessWidget {
  final StreamSubscription streamSubscription;
  final Completer<GoogleMapController> controller;
  final LocationData currentLocation;
  final Set<Marker> markers;
  final LocationData destinationLocation;

  MyLocation({this.markers, this.destinationLocation, this.streamSubscription, this.currentLocation, this.controller});

  final LatLng _initialCameraPosition = LatLng(37.42796133580664, -122.085749655962);
  final double bearing = 30;
  final double tilt = 80;
  final double zoom = 16;

  void _onMapCreated(GoogleMapController _cntlr) async {
    if (streamSubscription != null) {
      streamSubscription.cancel();
    }
    // _initialCameraPosition =
    //     LatLng(widget.geoPoint.latitude, widget.geoPoint.longitude);
    controller.complete(_cntlr);
    showPinsOnMap();
    // final GoogleMapController controller = await _controller.future;
    // _streamSubscription = location.onLocationChanged.listen((l) {
    //   controller.animateCamera(
    //     CameraUpdate.newCameraPosition(
    //       CameraPosition(
    //           target: LatLng(l.latitude, l.longitude), zoom: 14.4746),
    //     ),
    //   );
    // });
  }

  showPinsOnMap() {
    LatLng pinPosition =
    LatLng(currentLocation.latitude, currentLocation.longitude);
    LatLng desPosition =
    LatLng(destinationLocation.latitude, destinationLocation.longitude);
    markers
        .add(Marker(markerId: MarkerId('sourcePin'), position: pinPosition));
    markers.add(Marker(markerId: MarkerId('desPin'), position: desPosition));
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

    return Container(
      color: Colors.blueGrey.withOpacity(.8),
      height: MediaQuery.of(context).size.height / 2.5,
      width: MediaQuery.of(context).size.width,
      child: GoogleMap(
        initialCameraPosition: initialCameraPosition,
        mapType: MapType.normal,
        markers: markers,
        onMapCreated: _onMapCreated,
        myLocationEnabled: true,
      ),
    );
  }
}
