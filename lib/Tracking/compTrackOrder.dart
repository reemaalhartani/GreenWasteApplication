import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

//stateful used for daynamic data each refesh take the new data and make changes
class comp_tracking_order extends StatefulWidget {
  //tracking_location constractor take these argument when it's called
  const comp_tracking_order(
      {super.key, required this.company_email, required this.sp_name});
  final String company_email;
  final String sp_name;
  @override
  State<comp_tracking_order> createState() => MapState();
}

class MapState extends State<comp_tracking_order> {
  static late LatLng sourceLocation = LatLng(0, 0);
  static late LatLng destination;
  final Completer<GoogleMapController> _controller = Completer();
  //creating a line for to connect the source and the distenation
  List<LatLng> polylineCoordinates = [];

  //return source and destination markers latlong from firebase
  Future locations(comp_emil, sp_name) async {
    //return source from company collection
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    await firestore
        .collection("Company")
        .where("comp_email", isEqualTo: comp_emil)
        .get()
        .then((result) => result.docs.forEach((element) {
      final latitude = element["latitude"];
      final longitude = element["longitude"];
      sourceLocation = LatLng(latitude, longitude);
    }));
    //return
    await firestore
        .collection("serviceProviders")
        .where("SP_name", isEqualTo: sp_name)
        .get()
        .then((result) => result.docs.forEach((element) {
      final latitude = element["latitude"];
      final longitude = element["longitude"];
      destination = LatLng(latitude, longitude);
    }));

    setState(() {});
    getPolypoints();
  } //location funstion

  //get the distance between source and destination markers
  void getPolypoints() async {
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      'AIzaSyALT6SII0CWZHKA9w-iZuaMxK8l7AsB4hc',
      PointLatLng(sourceLocation.latitude, sourceLocation.longitude),
      PointLatLng(destination.latitude, destination.longitude),
      //if current location == destination pop up the btn of conform delivry
    );
    if (result.points.isNotEmpty) {
      result.points.forEach(
            (PointLatLng point) => polylineCoordinates.add(
          LatLng(point.latitude, point.longitude),
        ),
      );
      setState(() {});
    }
  } //end of getPolypoints

  @override
  void initState() {
    //don't forget these
    var comp_em = widget.company_email;
    var sp_name = widget.sp_name;
    locations(comp_em, sp_name); //it takes tow arguments the company email and the servies provider name  values from the orderview class
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightGreen[100],
      appBar: AppBar(
        title: Text('Live Location'),
        backgroundColor: Colors.lightGreen[300],
      ),
      //loading page before diplaying the map
      body:sourceLocation == null || sourceLocation==LatLng(0, 0)
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text('Loading...', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
          ],
        ),
      )
          :GoogleMap(
        initialCameraPosition: CameraPosition(
          zoom: 13.5,
          target: sourceLocation,
        ),
        markers: <Marker>{
          Marker(
            markerId: MarkerId('source'),
            position: LatLng(sourceLocation.latitude, sourceLocation.longitude),
            infoWindow: InfoWindow(
              title: "Source",
            ),
          ),
          Marker(
            markerId: MarkerId("Destination"),
            position: LatLng(destination.latitude, destination.longitude),
            infoWindow: InfoWindow(
              title: "Destination",
            ),
          ),
        },
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        polylines: Set<Polyline>.of(
          <Polyline>[
            Polyline(
              polylineId: PolylineId("Route_Polylines"),
              visible: true,
              points: polylineCoordinates,
              width: 5,
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }
}