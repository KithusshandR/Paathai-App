import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Maps',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PaathaiMap(),
    );
  }
}

class PaathaiMap extends StatefulWidget {
  @override
  _PaathaiMapState createState() => _PaathaiMapState();
}

class _PaathaiMapState extends State<PaathaiMap> {
  late BitmapDescriptor busIcon;
  // BitmapDescriptor? destinationIcon;

  //Custom icon for bus stops(MARKER)
  void setSourceAndDestinationIcons() async {
    busIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.5), 'assets/driving_pin.png');
    // destinationIcon = await BitmapDescriptor.fromAssetImage(
    //     ImageConfiguration(devicePixelRatio: 2.5),
    //     'assets/destination_map_marker.png');
  }

  Future<void> addUser() {
    // Call the user's CollectionReference to add a new user
    return FirebaseFirestore.instance
        .collection('users')
        .add({
          'busId': 100, // John Doe
          'latitude': 9.66845, // Stokes and Sons
          'longitude': 80.00742 // 42
        })
        .then((value) => print("User Added"))
        .catchError((error) => print("Failed to add user: $error"));
  }

  fetchAllContact() async {
    // List contactList = [];
    await FirebaseFirestore.instance
        .collection("users")
        .get()
        .then((querySnapshot) {
      querySnapshot.docs.forEach((result) {
        print(result.data());
        listnew.add(result.data());
        markers.add(
          Marker(
              markerId: MarkerId(result.data()['busId'].toString()),
              position:
                  LatLng(result.data()['latitude'], result.data()['longitude']),
              icon: busIcon),
        );
      });
    });
    print(listnew);
    // return contactList;
  }

  CameraPosition _initialLocation =
      CameraPosition(target: LatLng(9.66845, 80.00742));

  late GoogleMapController mapController;

  late Position _currentPosition;
  String _currentAddress = '';

  _getCurrentLocation() async {
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) async {
      setState(() {
        _currentPosition = position;
        print('CURRENT POS: $_currentPosition');
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 18.0,
            ),
          ),
        );
      });
      await _getAddress();
    }).catchError((e) {
      print(e);
    });
  }

  late DocumentSnapshot snapshot;
  var data;
  bool _loader = false;
  Future<dynamic> getData() async {
    setState(() {
      _loader = true;
    });
    final document = FirebaseFirestore.instance
        .collection("arrayroutes")
        .get();

  String startLatString= 9.66159.toString();
  String startLonString = 80.02541.toString();
  String StartlatlanString = startLatString +', '+startLonString ;
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('newroutes')
            .where('points', arrayContains: {"lon": StartlatlanString}).get();

    // Get data from docs and convert map to List
    final allData = querySnapshot.docs.map((doc) => doc.data()).toList();
    //for a specific field
    // final allData =
    //         querySnapshot.docs.map((doc) => doc.get('points')).toList();
    // listnew.add(allData[0]);
    // print(listnew);
    listnew.clear();
    print(listnew.length == 0 ? "1" : "2");
    for (var allitem in allData) {
      listnew.add(allitem);
    }
    for (var item in listnew) {
      print("---item----");
      // print(item['points']);
      for (var subItem in item['points']) {
        print(subItem);
      }
      print("----item---");
    }
    // listnew.map((name) {
    //   print("---item----");
    // print(name);
    // print("---item----");
    // }).toList();
    print("-------");
    print(allData);
    print("-------");

    // QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('arrayroutes').get();
    // final allData = querySnapshot.docs.map((doc) => doc.data()).toList();
    // print(allData);
    // print("-------");
    setState(() {
      _loader = false;
    });
  }

  receiveData() {
    print(listnew.map((doc) => doc.data()).toList());
  }

  @override
  void initState() {
    super.initState();
    // _getCurrentLocation();
    // setSourceAndDestinationIcons();
    // fetchAllContact();
    // getData();
    print("-----------");
    // print(_startAddress);
  }

  final startAddressController = TextEditingController();
  String _startAddress = '';

  _getAddress() async {
    try {
      List<Placemark> p = await placemarkFromCoordinates(
          _currentPosition.latitude, _currentPosition.longitude);

      Placemark place = p[0];

      setState(() {
        _currentAddress =
            "${place.name}, ${place.locality}, ${place.postalCode}, ${place.country}";
        startAddressController.text = _currentAddress;
        _startAddress = _currentAddress;
      });
    } catch (e) {
      print(e);
    }
  }

  final destinationAddressController = TextEditingController();
  String _destinationAddress = '';
  Set<Marker> markers = {};
  List listnew = [];

  final startAddressFocusNode = FocusNode();
  final desrinationAddressFocusNode = FocusNode();

  Future<bool> _calculateDistance() async {
    try {
      List<Location> startPlacemark = await locationFromAddress(_startAddress);
      List<Location> destinationPlacemark =
          await locationFromAddress(_destinationAddress);

          print("startPlacemark");
          print(startPlacemark);
          print("startPlacemark");
        
      // startLatitude, startLongitude are the root lat,lan. everything start from here
      double startLatitude = _startAddress == _currentAddress
          ? _currentPosition.latitude
          : startPlacemark[0].latitude;

      double startLongitude = _startAddress == _currentAddress
          ? _currentPosition.longitude
          : startPlacemark[0].longitude;

      double destinationLatitude = destinationPlacemark[0].latitude;
      double destinationLongitude = destinationPlacemark[0].longitude;

      String startCoordinatesString = '($startLatitude, $startLongitude)';
      String destinationCoordinatesString =
          '($destinationLatitude, $destinationLongitude)';

      Marker startMarker = Marker(
        markerId: MarkerId(startCoordinatesString),
        position: LatLng(startLatitude, startLongitude),
        infoWindow: InfoWindow(
          title: 'Start $startCoordinatesString',
          snippet: _startAddress,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );

      Marker destinationMarker = Marker(
        markerId: MarkerId(destinationCoordinatesString),
        position: LatLng(destinationLatitude, destinationLongitude),
        infoWindow: InfoWindow(
          title: 'Destination $destinationCoordinatesString',
          snippet: _destinationAddress,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      );

      // markers.add(Marker(
      //       markerId: MarkerId('sourcePin'),
      //       position: LatLng(9.680429, 80.015852),
      //       icon: BitmapDescriptor.defaultMarker));

      markers.add(startMarker);
      markers.add(destinationMarker);
      // fetchAllContact();

      print(
        'START COORDINATES: ($startLatitude, $startLongitude)',
      );
      print(
        'DESTINATION COORDINATES: ($destinationLatitude, $destinationLongitude)',
      );

      double miny = (startLatitude <= destinationLatitude)
          ? startLatitude
          : destinationLatitude;
      double minx = (startLongitude <= destinationLongitude)
          ? startLongitude
          : destinationLongitude;
      double maxy = (startLatitude <= destinationLatitude)
          ? destinationLatitude
          : startLatitude;
      double maxx = (startLongitude <= destinationLongitude)
          ? destinationLongitude
          : startLongitude;

      double southWestLatitude = miny;
      double southWestLongitude = minx;

      double northEastLatitude = maxy;
      double northEastLongitude = maxx;

      mapController.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            northeast: LatLng(northEastLatitude, northEastLongitude),
            southwest: LatLng(southWestLatitude, southWestLongitude),
          ),
          100.0,
        ),
      );
      // print("object $northEastLatitude, $northEastLongitude");
      // print( "$startLatitude, $startLongitude, $destinationLatitude, $destinationLongitude");

      await _createPolylines(startLatitude, startLongitude, destinationLatitude,
          destinationLongitude);

      double totalDistance = 0.0;

      for (int i = 0; i < polylineCoordinates.length - 1; i++) {
        totalDistance += _coordinateDistance(
          polylineCoordinates[i].latitude,
          polylineCoordinates[i].longitude,
          polylineCoordinates[i + 1].latitude,
          polylineCoordinates[i + 1].longitude,
        );
      }

      setState(() {
        _placeDistance = totalDistance.toStringAsFixed(2);
        print('DISTANCE: $_placeDistance km');
      });

      return true;
    } catch (e) {
      print(e);
    }
    return false;
  }

  late PolylinePoints polylinePoints;
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];

  _createPolylines(
    double startLatitude,
    double startLongitude,
    double destinationLatitude,
    double destinationLongitude,
  ) async {
    polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      "AIzaSyDM8U1e_9FPJqaCu4Vv0YrMxj6vqEyWyiA",
      PointLatLng(startLatitude, startLongitude),
      PointLatLng(destinationLatitude, destinationLongitude),
      travelMode: TravelMode.driving,
    );

    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        // polylineCoordinates.add(LatLng(9.67812, 80.01704));
        // polylineCoordinates.add(LatLng(9.66159, 80.02541));
        // polylineCoordinates.add(LatLng(9.677436, 80.013657));
        // polylineCoordinates.add(LatLng(9.678043, 80.012775));
        // polylineCoordinates.add(LatLng(9.678304, 80.011699));
        // polylineCoordinates.add(LatLng(9.679795, 80.012294));
        print("------------------------");
//         print({point.latitude, point.longitude});
//         //print(polylineCoordinates);
// print(double.parse((9.661607564989831).toStringAsFixed(5)));
// print(double.parse((80.02541339235292).toStringAsFixed(5)));
//         print(double.parse((startLatitude).toStringAsFixed(5)).toString() + " " + startLongitude.toString());
//         print(double.parse((startLongitude).toStringAsFixed(5)).toString() + " " + startLongitude.toString());
//         print(startLatitude.toString() + " " + startLongitude.toString());
        // print(destinationLatitude.toString() + " " + destinationLongitude.toString());
        print("------------------------");
      });
    }

    PolylineId id = PolylineId('poly');
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.red,
      points: polylineCoordinates,
      width: 3,
    );
    polylines[id] = polyline;
  }

  String? _placeDistance;

  double _coordinateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;

    return Container(
      height: height,
      width: width,
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            GoogleMap(
              markers: Set<Marker>.from(markers),
              initialCameraPosition: _initialLocation,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapType: MapType.normal,
              trafficEnabled: true,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: false,
              mapToolbarEnabled: true,
              polylines: Set<Polyline>.of(polylines.values),
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
            ),
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                    top: height * 9.5 / 20, left: 10, right: 10),
                child: Column(
                  // mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Text("data"),
                    Container(
                      // height: height * 13.5/20,
                      decoration: new BoxDecoration(
                        borderRadius: new BorderRadius.circular(16.0),
                        // color: Colors.green.withOpacity(0.5),
                      ),
                      child: SingleChildScrollView(
                        child: _loader == true ? Center(child: CupertinoActivityIndicator()) : Container(
                          child: listnew.length == 0 ? Text("data") : ListView.builder(
                            shrinkWrap: true,
                            itemCount: listnew.length,
                            itemBuilder: (BuildContext context, int index) {
                              return GestureDetector(
                                onTap: (){
                                  print("object $index");
                                  // startAddressFocusNode.unfocus();
                                  // desrinationAddressFocusNode.unfocus();
                                  // setState(() {
                                  //   if (markers.isNotEmpty) markers.clear();
                                  //   if (polylines.isNotEmpty) polylines.clear();
                                  //   if (polylineCoordinates.isNotEmpty)
                                  //     polylineCoordinates.clear();
                                  //   _placeDistance = null;
                                  // });
                                  _calculateDistance().then((isCalculated) {
                                    if (isCalculated) {
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Invalid Place'),
                                        ),
                                      );
                                    }
                                  });
                                },
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(18.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        Text(listnew[index]['busNo'].toString()),
                                        // Text(listnew[index]['points'][1].toString())
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.all(
                        Radius.circular(20.0),
                      ),
                    ),
                    width: width * 0.9,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Start(width),
                          SizedBox(height: 10),
                          End(width, context),
                          SizedBox(height: 10),
                          Distance(),
                          SizedBox(height: 5),
                          TextButton(
                              onPressed: () {
                                getData();
                                // receiveData();
                              },
                              child: Text("Getdata")),
                          TextButton(
                              onPressed: () {

                                FirebaseFirestore.instance
                                    .collection('newroutes')
                                    .add({
                                      'busNo': 769,
                                      'points': [
                                        {"lon": "31,21"},
                                        {"lon": "22,11"}
                                      ]
                                    })
                                    .then((value) => print("routes Added"))
                                    .catchError((error) =>
                                        print("Failed to add user: $error"));

                                print("object");
                                print(listnew);
                                print("-------");
                              },
                              child: Text("adddata"))
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(
                    bottom: 50,
                    right: 20,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Material(
                      color: Colors.white,
                      child: InkWell(
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(Icons.my_location),
                        ),
                        onTap: () {
                          print('CURRENT Address: $_currentAddress');
                          mapController.animateCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(
                                target: LatLng(
                                  _currentPosition.latitude,
                                  _currentPosition.longitude,
                                ),
                                zoom: 16.0,
                              ),
                            ),
                          );
                        },
                        onDoubleTap: () {
                          mapController.animateCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(
                                target: LatLng(
                                  _currentPosition.latitude,
                                  _currentPosition.longitude,
                                ),
                                zoom: 8.0,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(
                    bottom: 20,
                    right: 20,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(10),
                          topLeft: Radius.circular(10),
                        ),
                        child: Material(
                          color: Colors.white,
                          child: InkWell(
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: Icon(Icons.add),
                            ),
                            onTap: () {
                              mapController.animateCamera(
                                CameraUpdate.zoomIn(),
                              );
                            },
                          ),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(10),
                          bottomLeft: Radius.circular(10),
                        ),
                        child: Material(
                          color: Colors.white,
                          child: InkWell(
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: Icon(Icons.remove),
                            ),
                            onTap: () {
                              mapController.animateCamera(
                                CameraUpdate.zoomOut(),
                              );
                            },
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Visibility Distance() {
    return Visibility(
      visible: _placeDistance == null ? false : true,
      child: Text(
        'DISTANCE: $_placeDistance km',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Container Start(double width) {
    return Container(
      width: width * 0.8,
      child: TextField(
        onChanged: (value) {
          setState(() {
            _startAddress = value;
          });
        },
        decoration: new InputDecoration(
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(10.0),
            ),
            borderSide: BorderSide(
              color: Colors.grey.shade400,
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(10.0),
            ),
            borderSide: BorderSide(
              color: Colors.blue.shade300,
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.all(15),
          hintText: 'Start',
          suffixIcon: IconButton(
            icon: Icon(Icons.my_location),
            onPressed: () {
              _getAddress();
              startAddressController.text = _currentAddress;
              _startAddress = _currentAddress;
            },
          ),
        ),
        controller: startAddressController,
        focusNode: startAddressFocusNode,
      ),
    );
  }

  Container End(double width, BuildContext context) {
    return Container(
      width: width * 0.8,
      child: TextField(
        onChanged: (value) {
          setState(() {
            _destinationAddress = value;
          });
        },
        decoration: new InputDecoration(
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(10.0),
            ),
            borderSide: BorderSide(
              color: Colors.grey.shade400,
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(10.0),
            ),
            borderSide: BorderSide(
              color: Colors.blue.shade300,
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.all(15),
          hintText: 'End',
          suffixIcon: ConstrainedBox(
            constraints: BoxConstraints.tightFor(width: 20, height: 20),
            child: ElevatedButton(
              onPressed: (_startAddress != '' && _destinationAddress != '')
                  ? () async {
                      startAddressFocusNode.unfocus();
                      desrinationAddressFocusNode.unfocus();
                      setState(() {
                        if (markers.isNotEmpty) markers.clear();
                        if (polylines.isNotEmpty) polylines.clear();
                        if (polylineCoordinates.isNotEmpty)
                          polylineCoordinates.clear();
                        _placeDistance = null;
                      });
                      _calculateDistance().then((isCalculated) {
                        if (isCalculated) {
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Invalid Place'),
                            ),
                          );
                        }
                      });
                    }
                  : null,
              child: Text(
                'Go'.toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                primary: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ),
        ),
        controller: destinationAddressController,
        focusNode: desrinationAddressFocusNode,
      ),
    );
  }
}
