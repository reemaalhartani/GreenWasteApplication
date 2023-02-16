import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

//stateful used for daynamic data each refesh take the new data and make changes
class tracking_location extends StatefulWidget {
  //tracking_location constractor take these argument when it's called
  const tracking_location({super.key,required this.company_email, required this.sp_name,required this.docId});
  final String company_email;//return the company email that made the order
  final String sp_name;//return the
  final String docId ;
  @override
  State<tracking_location> createState() => MapState();
}

class MapState extends State<tracking_location> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  static  late LatLng sourceLocation=LatLng(0, 0);
  static late LatLng distenationLocation;
  static late bool showbtn=true;
  late final Completer<GoogleMapController> _controller = Completer();
  //creating a line for to connect the source and the distenation
  List<LatLng> polylineCoordinates = [];

  Future locations(orderid, sp_name) async {
    //return source
    await firestore
        .collection("Company")
        .where("comp_email", isEqualTo: orderid)
        .get()
        .then((result) => result.docs.forEach((element) {
      final latitude = element["latitude"];
      final longitude = element["longitude"];
      sourceLocation = LatLng(latitude, longitude);
    }));
    await firestore
        .collection("serviceProviders")
        .where("SP_name", isEqualTo: sp_name)
        .get()
        .then((result) => result.docs.forEach((element) {
      final latitude = element["latitude"];
      final longitude = element["longitude"];
      distenationLocation = LatLng(latitude, longitude);
    }));
    setState(() {});
    getPolypoints();
  } //location funstion

  //get the distance between points
  void getPolypoints() async {
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      'AIzaSyALT6SII0CWZHKA9w-iZuaMxK8l7AsB4hc',
      PointLatLng(sourceLocation.latitude, sourceLocation.longitude),
      PointLatLng(distenationLocation.latitude, distenationLocation.longitude),
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
    var comp_em = widget.company_email;
    var sp_name = widget.sp_name;
    locations(comp_em, sp_name); //it takes tow arguments the sompany email and the sp_name from the orderview class
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var docID = widget.docId;
    return Scaffold(
      floatingActionButton: showbtn? Container(
        margin: EdgeInsets.only(bottom: 20.0),
        height: 50,
        width: 130,
        child: FloatingActionButton(
          backgroundColor: Colors.lightGreen[800],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onPressed: () async{
            setState(() {
              showbtn = false;
            });
            await firestore
                .collection("order")
                .doc(docID)
                .update({
              'order_status': 'In Progress'
            })
                .then(
                    (value) => print("DocumentSnapshot successfully updated!"),
                onError: (e) => print("Error updating document $e")
            );
          },
          child: Text(
            "Confirm Pickup",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold
            ),
          ),
        ),
      ):SizedBox.shrink(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      backgroundColor: Colors.lightGreen[100],
      appBar: AppBar(
        title: Text('Live Location'),
        backgroundColor: Colors.lightGreen[300],
      ),
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
            zoom: 8,
            target:sourceLocation
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
            position: LatLng(distenationLocation.latitude, distenationLocation.longitude),
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
//flutter real time update current location marker on the map using location package and listener and manager
