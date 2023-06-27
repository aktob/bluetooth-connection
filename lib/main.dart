// import 'dart:async' show Future;
// import 'dart:convert';

// ignore_for_file: avoid_print, prefer_const_constructors, non_constant_identifier_names, prefer_typing_uninitialized_variables

import 'dart:typed_data';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Bluetooth Demo',
      home: Test(),
    );
  }
}

class Test extends StatefulWidget {
  const Test({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TestState createState() => _TestState();
}

class _TestState extends State<Test> {
  BluetoothConnection? _connection;
  bool _isConnecting = true;
  bool _connected = false;
  int _dataBuffer = 0;
  var lat = 29.321078;
  var long = 30.835542;
  var state = false;
  var cl;

  void _initBluetooth() async {
    try {
      List<BluetoothDevice> devices =
          await FlutterBluetoothSerial.instance.getBondedDevices();
      BluetoothDevice device =
          devices.firstWhere((device) => device.name == "HC-05");
      BluetoothConnection connection =
          await BluetoothConnection.toAddress(device.address);
      setState(() {
        _connection = connection;
        _isConnecting = false;
        _connected = true;
      });
      _connection?.input
          ?.listen(_handleData as void Function(Uint8List event)?);
    } on Exception catch (e) {
      print(e.toString());
    }
  }

  void _handleData(int data) {
    // String text = AsciiDecoder().convert(data);
    setState(() {
      _dataBuffer = data;
      DocumentReference add =
          FirebaseFirestore.instance.collection('earthquake-B').doc('estate');
      if (_dataBuffer == 1) {
        state = true;
      } else {
        state = false;
      }
      add.update({
        "lat": lat,
        'long': long,
        'state': state,
      });
    });
  }

  @override
  void dispose() {
    _connection?.dispose();
    super.dispose();
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    print(lat);
    return cl = await Geolocator.getCurrentPosition();
  }

  Future getlatlong() async {
    cl = await Geolocator.getCurrentPosition().then((value) => value);
    setState(() {
      lat = cl.latitude;
      long = cl.longitude;
    });
  }

  // update_data() async {
  //   CollectionReference update =
  //       FirebaseFirestore.instance.collection("earthquake-B");
  //   if (_dataBuffer == 1) {
  //     state = true;
  //   } else {
  //     state = false;
  //   }
  //   update.doc("estate").set({
  //     "state": state,
  //     "lat": lat,
  //     "long": long,
  //   }, SetOptions(merge: true));
  // }

  @override
  void initState() {
    super.initState();
    _initBluetooth();
    _determinePosition();
    // update_data();
    // print(cl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Demo'),
      ),
      body: Center(
        child: _connected
            ? Text('Received data: $_dataBuffer')
            : _isConnecting
                ? Text('Connecting...')
                : Text('Not connected'),
      ),
    );
  }
}
