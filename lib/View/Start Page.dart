import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lads_mapbox/Model/GetDistance.dart';
import 'homescreen.dart';
import 'package:http/http.dart' as http;


class StartedPage extends StatefulWidget {
  @override
  _StartedPageState createState() => _StartedPageState();
}

class _StartedPageState extends State<StartedPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SvgPicture.asset(
            'assets/bg/splashscreenbg.svg',
            fit: BoxFit.fill,
          ),
          Center(
            child: Column( mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/illustration/splashillustration.svg',
                  height: 250,
                ),
                Text(
                  "Mapbox",
                  style: TextStyle(
                    color: Color(0xffFFA025),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),
              ],
            ),
          ),
          Container(
            alignment: Alignment.bottomCenter,
            padding:
                EdgeInsets.only(left: 0.0, right: 0.0, top: 0.0, bottom: 15.0),
            child: MaterialButton(
              padding: EdgeInsets.zero,
              onPressed: () async{

                Navigator.pushReplacement(context,
                   MaterialPageRoute(builder: (context) => HomeScreen()));
              },
              child: Container(
                width: 230,
                height: 45,
                margin: EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Color(0xff5E53FF),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    "Get Started",
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
