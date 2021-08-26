import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mapbox_navigation/library.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:lads_mapbox/Controller/constants.dart';
import 'package:lads_mapbox/Model/GetDistance.dart';
import 'package:location_permissions/location_permissions.dart';
import 'package:mapbox_search/mapbox_search.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:weather/weather.dart';

import 'WeatherDetail.dart';

class Show_Direction extends StatefulWidget {
  final double lat;
  final double long;
  final String placeName;
  final String tag;
  final String destinationAddress;
  Show_Direction(
      {this.lat,
      this.long,
      this.placeName,
      this.tag,
      this.destinationAddress}) {}
  @override
  _Show_DirectionState createState() => _Show_DirectionState();
}

class _Show_DirectionState extends State<Show_Direction> {
  MapBoxNavigation _directions;

  String accessToken =
      'pk.eyJ1IjoiemFraXIxMTIyIiwiYSI6ImNrbmgzMjlsNTJ2aHoycXRhMDJ0dTVsdnYifQ.yLH6Fcdstf0LB6Jb3W7cjw';
  String weatherApiKey = '02f7b4f2992f05cdf5642ac304bffa84';

  bool _isMultipleStop = false;
  double _distanceRemaining = null;
  double _durationRemaining = null;
  MapBoxNavigationViewController _controller;
  bool _routeBuilt = false;
  bool _isNavigating = false;
  bool _arrived = false;
  String _instruction = "";
  FocusNode focusCurrentLocationField = FocusNode();
  FocusNode focusDestinationLocationField = FocusNode();

  bool isFocusCurrentLocationField = false;
  bool isFocusDestinationLocationField = false;
  List<MapBoxPlace> names = new List();
  List<MapBoxPlace> filteredNames = new List();
  final TextEditingController currentLocationController =
      new TextEditingController();
  final TextEditingController destinationLocationController =
      new TextEditingController();
  String currentLocationSelected = 'User Current Location';
  String destinationLocationSelected = 'Final Destination';
  PlacesSearch placesSearch;
  var _origin = WayPoint();
  var _destination = WayPoint();
  PermissionStatus
      permission; //= await LocationPermissions().requestPermissions();
  int expectedDistance = 0;
  int expectedDuration = 0;

  String buttonName = 'Directions';
  String buttomFirstText = 'Final Destination Name';
  String buttomSecondText = 'Final Destination Full Address Of the User';
  Position postion;
  List<Address> addresses;
  WeatherFactory wf;
  Weather destinationWeather;
  double speedInMps;
  bool isInternetConnection = true;
  bool showSpiner = true;
  StreamSubscription<Position> positionStream;
  var phoneNumber = TextEditingController(text: '000');
  String phoneNoLimitError = null;
  bool isScreenTaped = false;
  double zooom = 10;

  @override
  void initState() {
    _getCurrentLocation();
    checkNetworkConnectivity();
    if (widget.tag == 'bySearch') {
      _destination.latitude = widget.lat;
      _destination.longitude = widget.long;
      _destination.name = "${widget.placeName}";
      destinationLocationController.text = widget.placeName;
      buttomFirstText = widget.placeName;
      buttomSecondText = widget.destinationAddress;
    }
    placesSearch = PlacesSearch(
      apiKey: accessToken,
      limit: 5,
    );

    wf = WeatherFactory(weatherApiKey);

    currentLocationController.addListener(() {
      setState(() {});
    });

    ///////////////////  For destination ///////////

    destinationLocationController.addListener(() {
      setState(() {});
    });

    getLocationPermission();
    initialize();
    super.initState();
  }

  getLocationPermission() async {
    permission = await LocationPermissions().requestPermissions();
  }

  @override
  void dispose() {
    currentLocationController.dispose();
    destinationLocationController.dispose();
    focusDestinationLocationField.dispose();
    focusCurrentLocationField.dispose();
    positionStream.cancel();
    _controller.finishNavigation();
    super.dispose();
  }

  Future<void> initialize() async {
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    _directions = MapBoxNavigation(onRouteEvent: _onEmbeddedRouteEvent);
    MapBoxOptions(
      initialLatitude: _origin.latitude,
      initialLongitude: _origin.longitude,
      zoom: 15.0,
      tilt: 90.0,
      bearing: 0.0,
      enableRefresh: true,
      alternatives: true,
      voiceInstructionsEnabled: true,
      bannerInstructionsEnabled: true,
      allowsUTurnAtWayPoints: true,
      mode: MapBoxNavigationMode.drivingWithTraffic,
      units: VoiceUnits.imperial,
      simulateRoute: false,
      animateBuildRoute: true,
      longPressDestinationEnabled: true,
      language: "en",
    );

    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await _directions.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    setState(() {
      var _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: Connectivity().onConnectivityChanged,
        builder:
            (BuildContext ctxt, AsyncSnapshot<ConnectivityResult> snapShot) {
          if (!snapShot.hasData) return CircularProgressIndicator();
          var result = snapShot.data;

          switch (result) {
            case ConnectivityResult.none:
              return Scaffold(
                resizeToAvoidBottomInset: true,
                body: Center(
                  child: Text('No Internet'),
                ),
              );
              break;
            case ConnectivityResult.mobile:
            case ConnectivityResult.wifi:
              return WillPopScope(
                onWillPop: () async {
                  if (!isInternetConnection)
                    Navigator.pop(context);
                  else {
                    _distanceRemaining = null;
                    _durationRemaining = null;
                    _controller.clearRoute();
                    _controller.finishNavigation();
                    setState(() {});
                    Navigator.pop(context);
                  }
                  return;
                },
                child: Scaffold(
                  //backgroundColor: Colors.transparent,
                  resizeToAvoidBottomInset: false,

                  body: GestureDetector(
                    onDoubleTap: () {
                      isScreenTaped = !isScreenTaped;
                      zooom = zooom + 10;
                      setState(() {});
                    },
                    child: ModalProgressHUD(
                      inAsyncCall: showSpiner,
                      progressIndicator: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                        child: Stack(
                          children: [
                            showMapBoxNavigationView(),
                            isScreenTaped == false
                                ? showTopOrangeContainer(context)
                                : Container(),
                            isScreenTaped == false
                                ? showTextfieldsContainer(context)
                                : Container(),
                            Positioned(
                              top: 180,
                              child: focusCurrentLocationField.hasFocus &&
                                      currentLocationController.text.isNotEmpty
                                  ? showDropDownNameList()
                                  : Container(),
                            ),
                            Positioned(
                              top: 260,
                              child: focusDestinationLocationField.hasFocus &&
                                      destinationLocationController
                                          .text.isNotEmpty
                                  ? showDropDownNameList()
                                  : Container(),
                            ),
                            isScreenTaped == false
                                ? BottomWhiteContainer()
                                : Container(),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Container(
                                margin: EdgeInsets.only(bottom: 110, right: 30),
                                child: buttonName == 'weather'
                                    ? FloatingActionButton(
                                        backgroundColor: Colors.green,
                                        child: Container(
                                          width: 50,
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: IconButton(
                                                icon: Icon(Icons.phone_sharp),
                                                color: Colors.white,
                                                onPressed: () async {
                                                  String url = 'tel:' +
                                                      "${phoneNumber.text}";
                                                  if (await canLaunch(url)) {
                                                    await launch(url);
                                                  } else {
                                                    throw 'Could not launch $url';
                                                  }
                                                }),
                                          ),
                                        ),
                                      )
                                    : Container(),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
              break;
          }
          return Container();
        });
  }

  Align BottomWhiteContainer() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: buttonName == 'weather' ? weather_Layout() : direction_Layout(),
    );
  }

  Positioned showTextfieldsContainer(BuildContext context) {
    return Positioned(
      top: 110,
      child: Container(
        width: MediaQuery.of(context).size.width,
        alignment: Alignment.topCenter,
        child: Material(
          borderRadius: BorderRadius.circular(40.0),
          elevation: 5,
          child: Container(
            height: 190,
            width: whiteContainerWidth,
            padding: EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
                color: whiteContainerColor,
                borderRadius: BorderRadius.circular(40.0)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.only(
                        right: 10,
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            child: SvgPicture.asset(
                                'assets/Icons/location_orange.svg'),
                          ),
                          SizedBox(
                            child:
                                SvgPicture.asset('assets/Icons/dotedLine.svg'),
                          ),
                          SizedBox(
                            child:
                                SvgPicture.asset('assets/Icons/toLocation.svg'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: Container(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: currentLocationController,
                              focusNode: focusCurrentLocationField,
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.only(left: 20),
                                hintText: 'User Current Location',
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                ),
                                suffixIcon: Icon(Icons.search, size: 30),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                fillColor: Colors.white,
                                filled: true,
                                isDense: true,
                              ),
                              onChanged: (inputText) {
                                _getPlacesNames(inputText);
                                setState(() {});
                              },
                            ),
                            SizedBox(height: 30),
                            TextField(
                              controller: destinationLocationController,
                              focusNode: focusDestinationLocationField,
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.only(left: 20),
                                hintText: 'Final Destination',
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                ),
                                suffixIcon: Icon(Icons.search, size: 30),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                fillColor: Colors.white,
                                filled: true,
                                isDense: true,
                              ),
                              onChanged: (inputText) {
                                _getPlacesNames(inputText);
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Align showTopOrangeContainer(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 23),
        alignment: Alignment.topLeft,
        height: orangeContainerHeitht,
        width: orangeContainerWidth,
        decoration: BoxDecoration(
            color: orangeContainerColor,
            borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(30.0),
              bottomLeft: Radius.circular(30.0),
            )),
        child: Container(
          margin: EdgeInsets.only(top: 12),
          child: ListTile(
            leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_outlined,
                  size: 18,
                ),
                color: Colors.white,
                onPressed: () {
                  buttonName = 'Directions';
                  buttomFirstText = 'Final Destination Name';
                  buttomSecondText =
                      'Final Destination Full Address Of the User';
                  buttonNamePath = 'assets/Icons/direction.svg';
                  _distanceRemaining = null;
                  _durationRemaining = null;

                  Navigator.pop(context);
                }),
            title: Container(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Find Your Route',
                style: TextStyle(
                    color: Colors.white,
                    //fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    fontStyle: FontStyle.normal,
                    fontSize: 22),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Column showMapBoxNavigationView() {
    return Column(
      children: [
        // Expanded(
        //   // ignore: missing_return, missing_return
        //   flex: 3,
        //   child: Container(),
        // ),
        Expanded(
          flex: 7,
          child: MapBoxNavigationView(
              options: MapBoxOptions(
                initialLatitude: _origin.latitude,
                initialLongitude: _origin.longitude,
                zoom: 13,
                tilt: 90.0,
                bearing: 0.0,
                enableRefresh: true,
                alternatives: true,
                voiceInstructionsEnabled: true,
                bannerInstructionsEnabled: true,
                allowsUTurnAtWayPoints: true,
                mode: MapBoxNavigationMode.drivingWithTraffic,
                units: VoiceUnits.imperial,
                simulateRoute: false,
                animateBuildRoute: false,
                longPressDestinationEnabled: true,
                language: "en",
                padding: EdgeInsets.symmetric(
                  vertical: 200,
                  horizontal: 150,
                ),
                isOptimized: true,
              ),
              onRouteEvent: _onEmbeddedRouteEvent,
              onCreated: (MapBoxNavigationViewController controller) async {
                _controller = controller;
                _controller.initialize();
              }),
        ),
      ],
    );
  }

  Widget direction_Layout() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
          color: buttomSheetColor,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30), topRight: Radius.circular(30))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.only(left: 30, top: 10),
            child: Text(
              "${buttomFirstText}",
              style: TextStyle(
                  color: Color(0xFF5E53ff),
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            padding: EdgeInsets.only(left: 30),
            child: Text(
              "${buttomSecondText}",
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          Center(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: MaterialButton(
                padding: EdgeInsets.only(bottom: 10),
                child: Container(
                  width: 230,
                  height: 45,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: buttonColor),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: SvgPicture.asset('$buttonNamePath'),
                        ),
                        Text(
                          '${buttonName}',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                onPressed: () async {
                  if (currentLocationController.text.isNotEmpty &&
                      destinationLocationController.text.isNotEmpty) {
                    if (buttonName == 'Directions') {
                      getDistancAndTime();

                      buttonName = 'Start';
                      buttonNamePath = 'assets/Icons/start.svg';
                      //  buttomFirstText = '${expectedDuration} Min (${expectedDistance} km)';
                      buttomSecondText = 'Fastest Route';

                      getWeather();
                      buildRoute();
                      var phNomber = await showCustomDialog();
                      phoneNumber.text = phNomber;
                    } else {
                      buttonName = 'weather';

                      _controller.startNavigation(
                          options: MapBoxOptions(
                              initialLatitude: _origin.latitude,
                              initialLongitude: _origin.longitude,
                              zoom: 13,
                              tilt: 0.0,
                              enableFreeDriveMode: true,
                              mode: MapBoxNavigationMode.driving,
                              isOptimized: true,

                              //  simulateRoute: true,
                              alternatives: true));
                    }
                  } else {
                    //show snackbar
                    ScaffoldMessenger.of(context).showSnackBar(ShowSnackBar());
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  SnackBar ShowSnackBar() {
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Container(
        height: 30,
        width: MediaQuery.of(context).size.width,
        child: Center(
          child: Text(
            'Please Set Locations',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w200),
          ),
        ),
      ),
      backgroundColor: Colors.orange,
    );
  }

  Widget weather_Layout() {
    return Container(
        height: 100,
        padding: EdgeInsets.only(top: 40),
        decoration: BoxDecoration(
            color: buttomSheetColor,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30), topRight: Radius.circular(30))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Flexible(
              flex: 2,
              child: Container(
                alignment: Alignment.center,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SvgPicture.asset('assets/Icons/speedometer.svg'),
                    Text('${(speedInMps).toStringAsFixed(0)} mph'),
                  ],
                ),
              ),
            ),
            Flexible(
              flex: 3,
              child: Container(
                alignment: Alignment.center,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: Text("${_instruction}")),
                    Text(
                      _durationRemaining != null
                          ? "${(_durationRemaining / 60) < 60 ? '${(_durationRemaining / 60).toStringAsFixed(0)} Min' : '${durationToString((_durationRemaining / 60).toInt())} hr'} " //durationToString((_durationRemaining/60).toInt())  convert min int hours
                          : "Routing...",
                      style: TextStyle(
                          color: Colors.blue,
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _distanceRemaining != null
                          ? "(${(_distanceRemaining / 1000).toStringAsFixed(1)} Km)"
                          : ".",
                      style: TextStyle(
                          color: Colors.blue,
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            Flexible(
              flex: 2,
              child: Container(
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(left: 20),
                child: MaterialButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => WeatherDetail(
                                _origin.latitude, _origin.longitude)));
                  },
                  //padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SvgPicture.asset('assets/Icons/weathergrey.svg'),
                      FutureBuilder(
                        future: getWeather(),
                        builder: (context, snapshot) => snapshot.hasData
                            ? Text(
                                '${(destinationWeather.temperature.celsius).toStringAsFixed(0)}')
                            : Text("loading..."),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ));
  }

  Future<void> _onEmbeddedRouteEvent(e) async {
    _distanceRemaining = await _controller.distanceRemaining;
    _durationRemaining = await _controller.durationRemaining;

    switch (e.eventType) {
      case MapBoxEvent.progress_change:
        var progressEvent = e.data as RouteProgressEvent;
        _arrived = progressEvent.arrived;
        if (progressEvent.currentStepInstruction != null)
          _instruction = progressEvent.currentStepInstruction;
        break;
      case MapBoxEvent.route_building:
      case MapBoxEvent.route_built:
        setState(() {
          _routeBuilt = true;
        });
        break;
      case MapBoxEvent.route_build_failed:
        setState(() {
          _routeBuilt = false;
        });
        break;
      case MapBoxEvent.navigation_running:
        setState(() {
          _isNavigating = true;
        });
        break;
      case MapBoxEvent.on_arrival:
        _arrived = true;
        if (!_isMultipleStop) {
          await Future.delayed(Duration(seconds: 3));
          await _controller.finishNavigation();
        } else {}
        break;
      case MapBoxEvent.navigation_finished:
      case MapBoxEvent.navigation_cancelled:
        setState(() {
          _routeBuilt = false;
          _isNavigating = false;
        });
        break;
      //case MapBoxEvent.speech_announcement:
      default:
        break;
    }
    setState(() {});
  }

  void _getPlacesNames(String searchLocation) async {
    var tempList = await placesSearch.getPlaces(searchLocation);

    names.clear();
    filteredNames.clear();

    for (int i = 0; i < tempList.length; i++) {
      names.add(tempList[i]);
    }

    //names.shuffle();
    for (int j = 0; j < names.length; j++) filteredNames.add(names[j]);
  }

  Widget showDropDownNameList() {
    return Container(
      width: MediaQuery.of(context).size.width,
      alignment: Alignment.topCenter,
      padding: EdgeInsets.only(left: 25),
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          //padding: EdgeInsets.only(left: 10),
          //margin: EdgeInsets.only(left: 20),
          decoration: BoxDecoration(
              color: focusCurrentLocationField.hasFocus
                  ? Colors.orange[100]
                  : Colors.blue[100],
              borderRadius: BorderRadius.circular(15)),
          height: 280,
          width: 230,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                focusColor: Colors.red,
                title: Text("Current Location"),
                leading: Icon(Icons.location_searching),
                onTap: () {
                  _setCurrentLocation();
                },
              ),
              Expanded(
                flex: 9,
                child: ListView.builder(
                  padding: EdgeInsets.only(top: 0),
                  itemCount: names.isEmpty ? 0 : filteredNames.length,
                  itemBuilder: (BuildContext context, int index) {
                    return new ListTile(
                      title: Text(filteredNames[index].text),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(filteredNames[index].placeName),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 0),
                            child: Divider(
                              color: Colors.black12,
                              thickness: 2,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          if (focusCurrentLocationField.hasFocus) {
                            currentLocationController.text =
                                '${filteredNames[index].text}';
                            focusCurrentLocationField.unfocus();
                            _origin.name = filteredNames[index].text;

                            _origin.latitude =
                                filteredNames[index].geometry.coordinates.last;
                            _origin.longitude =
                                filteredNames[index].geometry.coordinates.first;
                          } else {
                            destinationLocationController.text =
                                '${filteredNames[index].text}';
                            _destination.name = filteredNames[index].text;
                            focusDestinationLocationField.unfocus();

                            _destination.latitude =
                                filteredNames[index].geometry.coordinates.last;
                            _destination.longitude =
                                filteredNames[index].geometry.coordinates.first;

                            buttomFirstText = filteredNames[index].text;
                            buttomSecondText = filteredNames[index].placeName;
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  buildRoute() async {
    _controller.buildRoute(
        options: MapBoxOptions(), wayPoints: [_origin, _destination]);
  }

  String durationToString(int minutes) {
    var d = Duration(minutes: minutes);
    List<String> parts = d.toString().split(':');
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }

  Future getDistancAndTime() async {
    var responce = await http.get(Uri.parse(
        'https://api.mapbox.com/directions/v5/mapbox/driving/${_origin.longitude},${_origin.latitude};${_destination.longitude},${_destination.latitude}?access_token=$accessToken&annotations=distance,duration'));
    var data = jsonDecode(responce.body);

    if (responce.statusCode == 200) {
      GetDistanceModel model = GetDistanceModel.fromJson(data);

      expectedDistance = (model.routes[0].distance).toInt();
      expectedDuration = (model.routes[0].duration).toInt();
      buttomFirstText =
          '${(expectedDuration / 60) < 60 ? '${(expectedDuration / 60).toStringAsFixed(0)} Min' : '${durationToString((expectedDuration / 60).toInt())} hr'}  (${(expectedDistance / 1000).toStringAsFixed(1)} km)';
    }
  }

  _getCurrentLocation() async {
    postion = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    //reverseGeoCoding(postion.latitude, postion.longitude);
    addresses = await Geocoder.local.findAddressesFromCoordinates(
        Coordinates(postion.latitude, postion.longitude));
    currentLocationController.text = '${addresses.first.subLocality}';
    //
    // _origin.latitude = postion.latitude;
    // _origin.longitude = postion.longitude;
    // _origin.name = "nnn";

    positionStream = await Geolocator.getPositionStream(
      desiredAccuracy: LocationAccuracy.high,
    ).listen((event) {
      _origin.latitude = event.latitude;
      _origin.longitude = event.longitude;
      _origin.name = "nnn";

      speedInMps = event.speed * 2.237;
    });

    showSpiner = false;

    return postion;
  }

  //////////////  convert coordinates to place Name

  reverseGeoCoding(double latitude, double longitude) async {
    final coordinates = new Coordinates(latitude, longitude);
    var placeName =
        await Geocoder.local.findAddressesFromCoordinates(coordinates);
    destinationLocationController.text =
        '${placeName.first.subLocality}, ${placeName.first.subAdminArea}';

    // return addresses;
  }

  _setCurrentLocation() {
    setState(() {
      if (focusCurrentLocationField.hasFocus) {
        _origin.latitude = postion.latitude;
        _origin.longitude = postion.longitude;
        _origin.name = "nnn";
        currentLocationController.text = "${addresses.first.subLocality}";
        focusCurrentLocationField.unfocus();
      } else {
        _destination.latitude = postion.latitude;
        _destination.longitude = postion.longitude;
        _destination.name = "nn";
        destinationLocationController.text = "${addresses.first.subLocality}";

        buttomFirstText = '${addresses.first.subLocality}';
        buttomSecondText = '${addresses.first.addressLine}';
        focusDestinationLocationField.unfocus();
      }
    });
  }

  getWeather() async {
    destinationWeather = await wf.currentWeatherByLocation(
        _destination.latitude, _destination.longitude);
    return destinationWeather;
  }

  Future<bool> checkNetworkConnectivity() async {
    bool connect;
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        connect = true;
        isInternetConnection = true;
      }
    } on SocketException catch (_) {
      connect = false;
      isInternetConnection = false;
    }
    setState(() {});
    return connect;
  }

  showCustomDialog() {
    return showDialog(context: context, builder: (context) => CustomDialog());
  }
}

class CustomDialog extends StatefulWidget {
  const CustomDialog({Key key}) : super(key: key);

  @override
  _CustomDialogState createState() => _CustomDialogState();
}

class _CustomDialogState extends State<CustomDialog> {
  var phNo = TextEditingController(text: '03');
  String errorText;
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(60.0),
      ),
      child: Container(
        //height: 500,
        //width: 200,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(30.0)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: SvgPicture.asset(
                    'assets/illustration/popupillustration.svg')),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                controller: phNo,
                style: TextStyle(
                  //height: 3,
                  fontSize: 20,
                ),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  contentPadding:
                      EdgeInsets.only(bottom: 12, left: 10, top: 12),
                  hintText: 'Enter Mobile Number',
                  errorText: errorText,
                  hintStyle: TextStyle(
                    color: Colors.grey,
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.black)),
                  fillColor: Colors.white,
                  filled: true,
                  isDense: true,
                ),
                onChanged: (text) {
                  if (text.length > 11) {
                    setState(() {
                      errorText = 'Error: Phone No Greater then 11 Character';
                    });
                  } else {
                    setState(() {
                      errorText = null;
                    });
                  }
                },
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(vertical: 20),
              child: MaterialButton(
                child: Container(
                  width: 150,
                  height: 50,
                  decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(15.0)),
                  child: Center(
                    child: Text(
                      "Done",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20),
                    ),
                  ),
                ),
                onPressed: () {
                  if (phNo.text.length <= 11)
                    Navigator.of(context).pop(phNo.text);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
