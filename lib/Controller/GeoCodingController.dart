import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lads_mapbox/SearchBar.dart';
import 'package:mapbox_search/mapbox_search.dart';

class GeoCodingController extends StatefulWidget {
  const GeoCodingController({Key key}) : super(key: key);

  @override
  _GeoCodingControllerState createState() => _GeoCodingControllerState();
}

class _GeoCodingControllerState extends State<GeoCodingController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MaterialButton(
              child: Container(
                child: Text('Get Place'),
              ),
              onPressed: ()async{
                print("press");

                var placesSearch = PlacesSearch(
                  apiKey: 'pk.eyJ1IjoiemFraXIxMTIyIiwiYSI6ImNrbjl3OTliazBhZTkycG8wZ2F6c3B4ZTgifQ.8ia0GyNWiqCKpo14DmWhvQ',
                  limit: 5,
                );

                print("press response complete");

                var placeslist = await placesSearch.getPlaces("karachi");
                print("${placeslist.length}");

                print("show result");


              },
            ),
          ],
        ),
      ),
    );
  }
  Future getPlaces() async{
    PlacesSearch placesSearch = PlacesSearch(
      apiKey: 'pk.eyJ1IjoiemFraXIxMTIyIiwiYSI6ImNrbmgzMjlsNTJ2aHoycXRhMDJ0dTVsdnYifQ.yLH6Fcdstf0LB6Jb3W7cjw',
      limit: 5,
    );

    var placeslist = await placesSearch.getPlaces("New York");

    print("${placeslist.length}");
  }



}
