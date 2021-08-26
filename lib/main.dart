import 'package:flutter/material.dart';
import 'package:lads_mapbox/Controller/GeoCodingController.dart';
import 'package:lads_mapbox/SearchBar.dart';
import 'package:lads_mapbox/View/Direction_page.dart';

import 'View/Start Page.dart';
import 'View/WeatherDetail.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
          body: StartedPage()),
    );
  }
}




