import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoder/geocoder.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lads_mapbox/Model/WeatherModel.dart';
import 'package:marquee/marquee.dart';
import 'package:weather/weather.dart';

class WeatherDetail extends StatefulWidget {
  double latitude;
  double longitude;
  WeatherDetail(this.latitude, this.longitude);
  @override
  _WeatherDetailState createState() => _WeatherDetailState();
}

class _WeatherDetailState extends State<WeatherDetail> {
  var height, width;
  WeatherFactory wf;
  Weather wather;
  List<Weather> forecast = [];
  WeatherModel weatherModel;
  int hour = 0;
  int tempreture = 0;
  int currentDate = DateTime.now().weekday;
  int day = 0;
  List<String> weekDay = ['Mon', 'Tue', 'Wen', 'Thr', 'Fri', 'Sat', 'Sun'];
  bool isInternetConnection = true;
  String degreeSymbol = '\u2109';
  String weatherPlaceName;

  @override
  void initState() {
    reverseGeoCoding(widget.latitude, widget.longitude);
    getWeather();
    checkNetworkConnectivity();
    super.initState();
  }

  reverseGeoCoding(double latitude, double longitude) async {
    final coordinates = new Coordinates(latitude, longitude);
    var addresses =
        await Geocoder.local.findAddressesFromCoordinates(coordinates);
    weatherPlaceName = addresses.first.subLocality;
  }

  getWeather() async {
    var responce = await http.get(Uri.parse(
        'https://api.openweathermap.org/data/2.5/onecall?lat=${widget.latitude}&lon=${widget.longitude}&exclude=alerts,minutely&appid=02f7b4f2992f05cdf5642ac304bffa84'));
    var data = jsonDecode(responce.body);
    if (responce.statusCode == 200) {
      print("Respince Error = ${responce.statusCode}");
      weatherModel = WeatherModel.fromJson(data);
      return weatherModel;
    } else {
      print("Respince Error = ${responce.statusCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: isInternetConnection
          ? FutureBuilder(
              future: getWeather(),
              builder: (context, snapshot) {
                print("snapshot = ${snapshot.hasError}");
                print("snapshot error= ${snapshot.error}");

                // if(snapshot.hasError)
                //   return Container(child: Center(child: Text("${snapshot.error}")),);
                // else
                if (snapshot.hasData)
                  return Stack(
                    children: [
                      Container(
                        height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width,
                        color: Colors.white,
                      ),
                      Positioned(
                        top: 240,
                        // bottom: 250,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height,
                          color: Colors.white,
                          child: ListView(
                            //mainAxisAlignment: MainAxisAlignment.center,
                            scrollDirection: Axis.vertical,
                            children: [
                              Container(
                                padding: const EdgeInsets.only(bottom: 25),
                                margin: EdgeInsets.only(top: 5),
                                child: Text(
                                  ' Today',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Color(0XFF000000),
                                  ),
                                ),
                              ),
                              Container(
                                height: 100,
                                width: 400,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: 24,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      width: 80,
                                      height: 100,
                                      margin:
                                          EdgeInsets.symmetric(horizontal: 5),
                                      padding:
                                          EdgeInsets.symmetric(vertical: 5),
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.only(
                                              bottomRight: Radius.circular(10),
                                              bottomLeft: Radius.circular(10),
                                              topLeft: Radius.circular(10),
                                              topRight: Radius.circular(10)),
                                          color: Colors.white,
                                          border: Border.all(
                                              color: Colors.black, width: .5)),
                                      child: Column(
                                        //mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          Expanded(
                                            child: Container(
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    "${((weatherModel.hourly[index].temp.toInt()) - 273.15).round()}",
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xff707070),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: EdgeInsets.only(
                                                        bottom: 10),
                                                    child: Text(
                                                      '\u2109',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Color(0xff707070),
                                                          fontSize: 14),
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: SvgPicture.asset(
                                                '${getHourlyWeatherIcon(weatherModel.hourly[index].weather.first.description, index)}',
                                                width: 40,
                                                height: 40,
                                                //color: Colors.red,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                              child: Text(
                                            (index + 1) <= 12
                                                ? '${index + 1}:00 Am'
                                                : "${index - 11}:00 Pm",
                                            style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xff707070)),
                                          ))
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              Container(
                                height: 340,
                                width: 400,

                                // color: Colors.green[200],
                                child: ListView.builder(
                                  scrollDirection: Axis.vertical,
                                  itemCount: weatherModel.daily.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 15),
                                      child: Container(
                                        height: 40,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                '${DateFormat.EEEE().format(DateTime.now().add(Duration(days: index + 1)))}',
                                                style: TextStyle(
                                                    fontSize: 20,
                                                    color: Color(0xff707070)),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: SvgPicture.asset(
                                                  '${getDailyWeatherIcon(weatherModel.daily[index].weather.first.description, index)}'),
                                            ),
                                            Flexible(
                                              fit: FlexFit.loose,
                                              flex: 2,
                                              child: Container(
                                                width: double.maxFinite,
                                                child: Container(
                                                  alignment: Alignment.topRight,
                                                  width: 50,
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      Container(
                                                        margin: EdgeInsets.zero,
                                                        child: Text(
                                                          '${((weatherModel.daily[index].temp.min) - 273).round()}~${((weatherModel.daily[index].temp.max) - 273).round()} ',
                                                          style: TextStyle(
                                                              fontSize: 20,
                                                              color: Color(
                                                                  0xff707070)),
                                                        ),
                                                      ),
                                                      Container(
                                                          padding:
                                                              EdgeInsets.only(
                                                                  bottom: 5),
                                                          child: Text(
                                                            '\u2109',
                                                            style: TextStyle(
                                                                fontSize: 12,
                                                                color: Color(
                                                                    0xff707070),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ))
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        child: Column(
                          children: [
                            SizedBox(
                              height: 30,
                            ),
                            ListTile(
                              contentPadding: EdgeInsets.only(top: 8),
                              leading: IconButton(
                                padding: EdgeInsets.symmetric(horizontal: 0),
                                icon: Icon(
                                  Icons.arrow_back_ios_outlined,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                              title: Container(
                                padding: EdgeInsets.only(left: 60),
                                child: Text(
                                  'Weather',
                                  style: TextStyle(
                                      fontSize: 25,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                        width: 400,
                        height: 170,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(30),
                                bottomLeft: Radius.circular(30)),
                            color: Color(0XFFFFA025)),
                      ),
                      Positioned(
                        top: 100,
                        left: 20,
                        child: Container(
                          child: Row(
                            children: [
                              Expanded(
                                flex: 6,
                                child: Container(
                                  height: height * 0.8,
                                  width: width * 0.2,
                                  padding: EdgeInsets.zero,
                                  decoration: BoxDecoration(
                                      color: Color(0xffdfdfdf),
                                      borderRadius: BorderRadius.only(
                                          topRight: Radius.elliptical(100, 140),
                                          bottomRight:
                                              Radius.elliptical(100, 140),
                                          topLeft: Radius.elliptical(60, 60),
                                          bottomLeft:
                                              Radius.elliptical(57, 60))),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        fit: FlexFit.tight,
                                        flex: 5,
                                        child: Container(
                                          padding: const EdgeInsets.all(10.0),
                                          child: SvgPicture.asset(
                                            '${getCurrentWeatherIcon(weatherModel.current.weather.first.description)}', //
                                            //fit: BoxFit.fill,
                                          ),
                                        ),
                                      ),
                                      Flexible(
                                        fit: FlexFit.loose,
                                        flex: 2,
                                        child: Text(
                                          '${weatherModel.current.weather.first.description}', //'${weatherModel.current.weather.first.description}'
                                          style: TextStyle(
                                              fontSize: 15,
                                              color: Color(0xFF000000)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 6,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                        bottomRight: Radius.circular(30),
                                        bottomLeft: Radius.circular(0),
                                        topLeft: Radius.circular(0),
                                        topRight: Radius.circular(30)),
                                    color: Colors.white,
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(vertical: 15),
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              SvgPicture.asset(
                                                  'assets/Icons/location_orange.svg'),
                                              Flexible(
                                                child: Marquee(
                                                  text:
                                                      '${weatherPlaceName}', //'${weatherModel.current.weather.first.description}'
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    color: Colors.orange,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  scrollAxis: Axis.horizontal,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  blankSpace: 100.0,
                                                  velocity: 50.0,
                                                  pauseAfterRound:
                                                      Duration(seconds: 2),
                                                  startPadding: 10.0,
                                                  accelerationDuration:
                                                      Duration(
                                                          milliseconds: 500),
                                                  accelerationCurve:
                                                      Curves.linear,
                                                  //decelerationDuration: Duration(seconds: 2),
                                                  // decelerationCurve: Curves.easeOutBack,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Container(
                                            width: 100,
                                            padding: const EdgeInsets.all(0),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  '${(weatherModel.current.temp - 273).round()}',
                                                  style: TextStyle(
                                                      fontSize: 50,
                                                      color: Color(0xFF5E53FF)),
                                                ),
                                                Container(
                                                    padding: EdgeInsets.only(
                                                        bottom: 20),
                                                    child: Text(
                                                      '\u2109',
                                                      style: TextStyle(
                                                          fontSize: 25,
                                                          color:
                                                              Color(0xFF5E53FF),
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ))
                                              ],
                                            ),
                                            //'${(weatherModel.current.temp - 273).round()}\u2109',
                                            // style: TextStyle(fontSize: 50,color: Color(0xFF5E53FF)),
                                            //),
                                          ),
                                        ),
                                        Expanded(
                                            child: Text(
                                          '${DateFormat.EEEE().format(DateTime.now())},${DateFormat.MMMM().format(DateTime.now())},${DateTime.now().day} ',
                                          style: TextStyle(
                                              fontSize: 15,
                                              color: Color(0XFF707070),
                                              fontWeight: FontWeight.bold),
                                        )),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          height: height * 0.2,
                          width: width * 0.88,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(30),
                                bottomLeft: Radius.circular(30),
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30)),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.16),
                                offset: Offset(0, 4.0),
                                blurRadius: 6.0,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                else
                  return Center(
                      child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ));
              })
          : noNetwork(),
    );
  }

  getCurrentWeatherIcon(String weatherDescription) {
    String ImagePath = 'assets/Icons/sunandskyorangeblue.svg';
    if (weatherModel.current.weather.first.description == 'overcast clouds')
      ImagePath = 'assets/Icons/cloudandlight.svg';
    else if (weatherModel.current.weather.first.description == 'clear sky')
      ImagePath = 'assets/filledIcons/sun.svg';
    else if (weatherModel.current.weather.first.description == 'few clouds')
      ImagePath = 'assets/filledIcons/fewcloud.svg';
    else if (weatherModel.current.weather.first.description ==
        'scattered clouds')
      ImagePath = 'assets/filledIcons/scattedCloud.svg';
    else if (weatherModel.current.weather.first.description == 'broken clouds')
      ImagePath = 'assets/filledIcons/brokencloud.svg';
    else if (weatherModel.current.weather.first.description == 'shower rain' ||
        weatherModel.current.weather.first.description == 'moderate rain')
      ImagePath = 'assets/filledIcons/showerRain.svg';
    else if (weatherModel.current.weather.first.description == 'rain')
      ImagePath = 'assets/filledIcons/rain.svg';
    else if (weatherModel.current.weather.first.description == 'thunderstorm')
      ImagePath = 'assets/filledIcons/thunderdTorm.svg';
    else if (weatherModel.current.weather.first.description == 'snow')
      ImagePath = 'assets/filledIcons/snow.svg';
    else if (weatherModel.current.weather.first.description == 'mist')
      ImagePath = 'assets/filledIcons/mist.svg';

    return ImagePath;
  }

  getDailyWeatherIcon(String weatherDescription, int index) {
    String ImagePath = 'assets/filledIcons/fewcloud.svg';

    if (weatherModel.daily[index].weather.first.description.characters ==
        'overcast clouds')
      ImagePath = 'assets/filledIcons/fewcloud.svg';
    else if (weatherModel.daily[index].weather.first.description == 'clear sky')
      ImagePath = 'assets/filledIcons/sun.svg';
    else if (weatherModel.daily[index].weather.first.description ==
        'few clouds')
      ImagePath = 'assets/filledIcons/fewcloud.svg';
    else if (weatherModel.daily[index].weather.first.description ==
        'scattered clouds')
      ImagePath = 'assets/filledIcons/scattedCloud.svg';
    else if (weatherModel.daily[index].weather.first.description ==
        'broken clouds')
      ImagePath = 'assets/filledIcons/brokencloud.svg';
    else if (weatherModel.daily[index].weather.first.description ==
            'shower rain' ||
        weatherModel.current.weather.first.description == 'moderate rain')
      ImagePath = 'assets/filledIcons/showerRain.svg';
    else if (weatherModel.daily[index].weather.first.description == 'rain')
      ImagePath = 'assets/filledIcons/rain.svg';
    else if (weatherModel.daily[index].weather.first.description ==
        'thunderstorm')
      ImagePath = 'assets/filledIcons/thunderdTorm.svg';
    else if (weatherModel.daily[index].weather.first.description == 'snow')
      ImagePath = 'assets/filledIcons/snow.svg';
    else if (weatherModel.daily[index].weather.first.description == 'mist')
      ImagePath = 'assets/filledIcons/mist.svg';

    return ImagePath;
  }

  getHourlyWeatherIcon(String weatherDescription, int index) {
    String ImagePath = 'assets/outlineIcons/fewclouds.svg';

    if (weatherModel.hourly[index].weather.first.description.characters ==
        'overcast clouds')
      ImagePath = 'assets/outlineIcons/fewclouds.svg';
    else if (weatherModel.hourly[index].weather.first.description ==
        'clear sky')
      ImagePath = 'assets/outlineIcons/clearsky.svg';
    else if (weatherModel.hourly[index].weather.first.description ==
        'few clouds')
      ImagePath = 'assets/outlineIcons/fewclouds.svg';
    else if (weatherModel.hourly[index].weather.first.description ==
        'scattered clouds')
      ImagePath = 'assets/outlineIcons/scattedcloud.svg';
    else if (weatherModel.hourly[index].weather.first.description ==
        'broken clouds')
      ImagePath = 'assets/outlineIcons/brokencloud.svg';
    else if (weatherModel.hourly[index].weather.first.description ==
            'shower rain' ||
        weatherModel.current.weather.first.description == 'moderate rain')
      ImagePath = 'assets/outlineIcons/showerrain.svg';
    else if (weatherModel.hourly[index].weather.first.description == 'rain')
      ImagePath = 'assets/outlineIcons/rain.svg';
    else if (weatherModel.hourly[index].weather.first.description ==
        'thunderstorm')
      ImagePath = 'assets/filledIcons/thunderdTorm.svg';
    else if (weatherModel.hourly[index].weather.first.description == 'snow')
      ImagePath = 'assets/outlineIcons/snow.svg';
    else if (weatherModel.hourly[index].weather.first.description == 'mist')
      ImagePath = 'assets/outlineIcons/mist.svg';

    return ImagePath;
  }

  Future<bool> checkNetworkConnectivity() async {
    bool connect;
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        connect = true;
        isInternetConnection = true;
        print('networkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk');
      }
    } on SocketException catch (_) {
      connect = false;
      isInternetConnection = false;
      print(
          'no00000000000000000000000000000000000000000000000000000000000000 network');
    }
    setState(() {});
    //return connect;
  }

  noNetwork() {
    return Scaffold(
      body: Container(
        child: Center(
          child: Text(
            "No Internet",
            style: TextStyle(fontSize: 30, color: Colors.red),
          ),
        ),
      ),
    );
  }

  RichText fomateSupperScriptText(
      {String planeText, String superScriptText, Color color}) {
    RichText(
      text: TextSpan(
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
          children: [
            WidgetSpan(
              child: Transform.translate(
                offset: const Offset(0.0,
                    -10.0), //Offset, the x-axis displacement is unchanged, moving to the right is positive, to the left is negative, Y-axis is negative up, and down is positive
                child: Text(
                  '￥',
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
            ),
            TextSpan(
              text: '46~89',
            ),
          ]),
    );
  }
}
