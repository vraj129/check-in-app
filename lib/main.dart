import 'dart:io';

import 'package:app_via_demo/screens/checkedIn_screen.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as loc;
import 'package:path/path.dart' as path;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:platform_device_id/platform_device_id.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CheckIn Log In',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Check In Log app'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<CameraDescription>? cameras;
  CameraController? controller;
  XFile? image;
  late Position _currentPosition;
  Placemark? _currentAddress;
  String dateTime="";
  final CollectionReference _userDetails =
  FirebaseFirestore.instance.collection('users');

  @override
  void initState() {
    loadCamera();
    checkGPS();
    super.initState();
  }

  checkGPS() async {
    loc.Location location = loc.Location();
    bool ison = await location.serviceEnabled();
    if (!ison) {
      bool isturnedon = await location.requestService();
      if (isturnedon) {
        print("GPS device is turned ON");
        if((await Permission.location.request().isGranted)){
          print("GPS device Permission given");
          return true;
        }
        else{
          SystemChannels.platform.invokeMethod<void>('SystemNavigator.pop');
        }
      } else {
        SystemChannels.platform.invokeMethod<void>('SystemNavigator.pop');
      }
    }
    return true;
  }

  loadCamera() async {
    cameras = await availableCameras();
    if(cameras != null){
      controller = CameraController(cameras![1], ResolutionPreset.max);
      controller!.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});
      });
    }else{
      print("NO any camera found");
    }
  }
  /*Checking if your App has been Given Permission*/


  Future<void> _requestPermission() async {

  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio *
        (controller!.value.aspectRatio);
    if (scale < 1) scale = 1 / scale;
     return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Stack(
            children: [
              Transform.scale(
                scale: scale,
                  child: controller == null?
                  const Center(child:Text("Loading Camera...")):
                  !controller!.value.isInitialized?
                  const Center(
                    child: CircularProgressIndicator(),
                  )
                      :
                  CameraPreview(controller!)
              ),
              Align(
                alignment: Alignment.center,
                child: ElevatedButton(
                  onPressed: () async {
                   bool check =  await checkGPS();
                   if(check){
                     apiCallDialogBox();
                     try {
                       if(controller != null){
                         if(controller!.value.isInitialized){
                           image = await controller!.takePicture();
                           await _getCurrentLocation();

                           await uploadFile();
                           String? deviceId = await PlatformDeviceId.getDeviceId;
                           if(!mounted) {
                             return;
                           }

                           Navigator.pop(context);
                           Navigator.pushAndRemoveUntil(
                             context,
                             MaterialPageRoute(builder: (context) =>  CheckedInScreen(
                               country: _currentAddress!.country!,
                               dateTime: dateTime,
                               district: _currentAddress!.locality!,
                               image_url: image!.path,
                               lat: _currentPosition.latitude.toString(),
                               long: _currentPosition.longitude.toString(),
                               postal_code: _currentAddress!.postalCode!,
                               deviceId: deviceId!,
                             )),
                                 (route) => false,
                           );
                           print("done");
                         }
                       }
                     } catch (e) {
                       Navigator.pop(context);
                       print(e); //show error
                     }
                   }

                  },
                  child: const Text("Check In"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  _getCurrentLocation()  async {
     await Geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) async {
        _currentPosition = position;
        print(_currentPosition.latitude.toString());
        print(_currentPosition.longitude.toString());
        await _getAddressFromLatLng();
    }).catchError((e) {
      print(e);
    });
  }
  _getAddressFromLatLng() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          _currentPosition.latitude,
          _currentPosition.longitude
      );

      Placemark place = placemarks[0];
        _currentAddress = place;
        print(place.locality);
        print(place.postalCode);
        print(place.country);

    } catch (e) {
      print(e);
    }
  }

  Future uploadFile() async {
    FirebaseStorage storageReference = FirebaseStorage.instance;
    final task = await storageReference.ref(path.basename(image!.path)).putFile(
      File(image!.path),
    );
    final urlString = await task.ref.getDownloadURL();
    String? deviceID = await PlatformDeviceId.getDeviceId;
    print(DateTime.now());
    dateTime = DateTime.now().toString();
    await FirebaseFirestore.instance.collection("$deviceID").doc(dateTime).set({
      'checkin_timestamp':dateTime,
      'country':_currentAddress!.country,
      'district':_currentAddress!.locality,
      'image_url':urlString,
      'lat':_currentPosition.latitude.toString(),
      'long':_currentPosition.longitude.toString(),
      'postal_code':_currentAddress!.postalCode,
    });
    print(urlString.toString());
  }

  apiCallDialogBox() async {
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return WillPopScope(
            onWillPop: () async {
              return false;
            },
            child: const Dialog(
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: SizedBox(
                  height: 100,
                  width: 100,
                  child: Center(child: CircularProgressIndicator())),
            ),
          );
        });
  }
}
