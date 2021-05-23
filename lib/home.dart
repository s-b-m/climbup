import 'dart:async';
import 'dart:typed_data';
import 'dart:math';
import 'dart:core';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'authentication_service.dart';
import 'package:firebase_database/firebase_database.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ClimbUp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'ClimbUp'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  StreamSubscription _locationSubscription;
  final Location _locationTracker = Location();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final database = FirebaseDatabase.instance.reference().child('users');
  Marker marker;
  Circle circle;
  GoogleMapController _controller;
  bool trackingEnabled = false;
  List locations = [];
  Icon floatb = Icon(Icons.location_searching);

  static final CameraPosition initialLocation = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  Future<Uint8List> getMarker() async {
    var byteData =
        await DefaultAssetBundle.of(context).load('assets/newarrow2.png');
    return byteData.buffer.asUint8List();
  }

  double getScore() {
    double currentScore;
    currentScore = 0;
    for (var i = 0; i < locations.length - 1; i++) {
      currentScore +=
          (pow((locations[i + 1].latitude - locations[i].latitude).abs(), 2) +
                  pow(
                      (locations[i + 1].longitude - locations[i].longitude)
                          .abs(),
                      2)) *
              100000000;
    }
    return sqrt(currentScore);
  }

  void updateMarkerAndCircle(LocationData newLocalData, Uint8List imageData) {
    var latlng = LatLng(newLocalData.latitude, newLocalData.longitude);
    if (trackingEnabled) {
      locations.add(latlng);
    }
    setState(() {
      marker = Marker(
          markerId: MarkerId('home'),
          position: latlng,
          rotation: newLocalData.heading,
          draggable: false,
          zIndex: 2,
          flat: true,
          anchor: Offset(0.5, 0.5),
          icon: BitmapDescriptor.fromBytes(imageData));
      circle = Circle(
          circleId: CircleId('car'),
          radius: newLocalData.accuracy,
          zIndex: 1,
          strokeColor: Colors.blue,
          center: latlng,
          fillColor: Colors.blue.withAlpha(70));
    });
  }

  void getCurrentLocation() async {
    try {
      var imageData = await getMarker();
      var location = await _locationTracker.getLocation();
      updateMarkerAndCircle(location, imageData);

      if (_locationSubscription != null) {
        await _locationSubscription.cancel();
      }

      _locationSubscription =
          _locationTracker.onLocationChanged.listen((newLocalData) {
        if (_controller != null) {
          _controller.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(
                  bearing: 192.8334901395799,
                  target: LatLng(newLocalData.latitude, newLocalData.longitude),
                  tilt: 0,
                  zoom: 18.00)));
          updateMarkerAndCircle(newLocalData, imageData);
        }
      });
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        debugPrint('Permission Denied');
      }
    }
  }

  @override
  void dispose() {
    if (_locationSubscription != null) {
      _locationSubscription.cancel();
    }
    super.dispose();
  }

  Future<double> getData() async {
    final user = _auth.currentUser.uid;
    var totalscore;
    await database.child(user).once().then((DataSnapshot snapshot) {
      totalscore = snapshot.value;
    });
    if (totalscore == 0) {
      return 0.0;
    }
    return totalscore;
  }

  void writeData() async {
    final user = _auth.currentUser;
    final uid = user.uid;
    var temp = await getData();
    if (temp != null) {
      await database.child(uid).set(getScore() + temp);
    } else {
      await database.child(uid).set(getScore());
    }
    locations.clear();
  }

  Future<void> handleClick(String value) async {
    switch (value) {
      case 'Logout':
        AuthenticationService(_auth);
        await _auth.signOut();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text((trackingEnabled)
            ? 'Current Score: ' + getScore().toStringAsFixed(2)
            : 'Press the button to start tracking!'),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: handleClick,
            itemBuilder: (BuildContext context) {
              return {'Logout', 'Settings'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: GoogleMap(
        mapType: MapType.hybrid,
        initialCameraPosition: initialLocation,
        markers: Set.of((marker != null) ? [marker] : []),
        circles: Set.of((circle != null) ? [circle] : []),
        onMapCreated: (GoogleMapController controller) {
          _controller = controller;
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: floatb,
        onPressed: () => setState(() {
          getCurrentLocation();
          if (trackingEnabled) {
            floatb = Icon(Icons.location_searching);
            trackingEnabled = false;
            getCurrentLocation();
          } else {
            floatb = Icon(Icons.stop);
            trackingEnabled = true;
            writeData();
          }
        }),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text(_auth.currentUser.email),
              accountEmail: FutureBuilder(
                future: database.once(),
                builder: (BuildContext context,
                    AsyncSnapshot<DataSnapshot> snapshot) {
                  if (snapshot.data != null) {
                    return Text(
                        'Your total score: ${snapshot.data.value[_auth.currentUser.uid].toStringAsFixed(2)}');
                  } else {
                    return Text('Retrieving score...');
                  }
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
