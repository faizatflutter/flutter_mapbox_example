import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/library.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geocoder/model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lads_mapbox/View/WeatherDetail.dart';
import 'package:mapbox_search/mapbox_search.dart';
import 'Direction_page.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController destinationLocationController = TextEditingController();
  Position postion;
  List<Address> addresses;
  var focusDestinationLocationField = FocusNode();
  var _destination = WayPoint();
  PlacesSearch placesSearch;
  List<MapBoxPlace> names = new List();
  List<MapBoxPlace> filteredNames = new List();
  double destinationLatitude;
  double destinationLongitude;
  String destinationPlaceName;
  double currentLatitude;
  double currentLongitude;
  var height, width;


  @override
  void initState() {
   _getCurrentLocation();

   placesSearch = PlacesSearch(
     apiKey: 'pk.eyJ1IjoiemFraXIxMTIyIiwiYSI6ImNrbjl3OTliazBhZTkycG8wZ2F6c3B4ZTgifQ.8ia0GyNWiqCKpo14DmWhvQ',
     limit: 5,


   );
   super.initState();
  }


  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 40.0,left: 10,right: 10),
            margin: EdgeInsets.symmetric(horizontal: 10),
            width: 368,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Center(
                    child: Text(
                      "Find Your Route",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontStyle: FontStyle.normal,
                       // fontWeight: FontWeight.normal,
                        fontSize: 26,
                      ),
                    ),
                  ),
                ),
                Flexible(
                  fit: FlexFit.loose,
                  child: Container(
                    width: 368,
                    height: 387,
                    child: TextField(
                      controller: destinationLocationController,
                        focusNode: focusDestinationLocationField,

                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.only(left:20),
                      hintText: "Search Your Route",
                      hintStyle: TextStyle(
                        color: Color(0xffC1C1C1),
                        letterSpacing: 0.6,
                      ),
                      suffixIcon: Icon(
                        Icons.search,
                        size: 30,
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(
                              30,
                            ),
                          ),
                          borderSide: BorderSide(
                            color: Colors.black,
                          ),
                      ),
                          isDense: true
                    ),
                      onChanged: (textInput){
                        _getPlacesNames(textInput);
                        setState(() {

                        });
                      },
                    ),
                  ),
                ),

                SvgPicture.asset(
                  'assets/illustration/homescreenillustrationcard.svg',
                  width: width,
                ),

                Flexible(
                  //flex: 1,
                  fit: FlexFit.tight,
                  child: Container(
                    margin: EdgeInsets.only(top: 6),
                    child: Text(
                      "Categories",
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          fontSize: 18,
                          color: Colors.black,
                      ),
                    ),
                  ),
                ),


                Container(
                  margin: EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: MaterialButton(
                          padding: EdgeInsets.only(left: 0,right: 10),
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Show_Direction()));
                          },
                          child: Container(
                              width: 368,
                              height: 113,
                              decoration: BoxDecoration(
                                color: Color(0xff5E53FF),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  SvgPicture.asset(
                                    'assets/Icons/location.svg',
                                    width: width * 0.1,
                                    color: Colors.white,
                                  ),
                                  Text(
                                    "Location",
                                    style: TextStyle(
                                        fontFamily: 'Poppins',
                                        letterSpacing: 1.0,
                                        color: Colors.white),
                                  )
                                ],
                              )),
                        ),
                      ),
                      Expanded(
                        child: MaterialButton(
                          padding: EdgeInsets.only(right: 0,left: 10),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context)=>WeatherDetail(currentLatitude,currentLongitude)));

                          },
                          child: Container(
                            width: 368,
                            height: 113,
                            decoration: BoxDecoration(
                              color: Color(0xffFFA025),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                SvgPicture.asset(
                                  'assets/Icons/weathergrey.svg',
                                  width: width * 0.1,
                                  color: Colors.white,
                                ),
                                Text(
                                  "Weather",
                                  style: TextStyle(
                                      fontFamily: 'Poppins',
                                      letterSpacing: 1.0,
                                      color: Colors.white),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          Positioned(
            top: 140,
              child: destinationLocationController.text.isNotEmpty && focusDestinationLocationField.hasFocus ? showDropDownNameList():Container(),
          ),
        ],
      ),
    );
  }


  _getCurrentLocation() async {
    postion = await Geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    reverseGeoCoding(postion.latitude, postion.longitude);
    currentLatitude = postion.latitude;
    currentLongitude = postion.longitude;
    return postion;


  }

  //////////////  convert coordinates to place Name

  reverseGeoCoding(double latitude, double longitude) async {
    final coordinates = new Coordinates(latitude, longitude);
    addresses = await Geocoder.local.findAddressesFromCoordinates(coordinates);
    destinationPlaceName = addresses.first.subLocality;

  }
  Widget showDropDownNameList()
  {

    return Container(
      width: MediaQuery.of(context).size.width,
      alignment: Alignment.topCenter,
      padding: EdgeInsets.only(
          //left: 15
      ),
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(15),

        child: Container(
          //padding: EdgeInsets.only(left: 10),
          //margin: EdgeInsets.only(left: 20),
          decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(15)
          ),
          height: 300,
          width: 270,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                focusColor: Colors.red,
                title: Text("Current Location"),
                leading: Icon(Icons.location_searching),
                onTap: (){
                  _setCurrentLocation();
                },
              ),
              Expanded(
                flex: 9,
                child: ListView.builder(
                  padding: EdgeInsets.only(top: 0),
                  itemCount: names.isEmpty? 0 : filteredNames.length,
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
                              color:Colors.black12,
                              thickness: 2,
                            ),
                          ),
                        ],
                      ),

                      onTap: () {
                        setState(() {
                            destinationLocationController.text = '${filteredNames[index].text}';
                            _destination.name = filteredNames[index].text;
                            focusDestinationLocationField.unfocus();

                            destinationLatitude = filteredNames[index].geometry.coordinates.last;
                            destinationLongitude = filteredNames[index].geometry.coordinates.first;

                            Navigator.push(context,
                                MaterialPageRoute(
                                    builder: (context)=>Show_Direction(
                                      lat: destinationLatitude,
                                      long:destinationLongitude,
                                      placeName: destinationLocationController.text,
                                      destinationAddress: filteredNames[index].placeName,
                                      tag: 'bySearch',
                                    ),
                                ),
                            );
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
  _setCurrentLocation(){
    setState(() {

        destinationLatitude = postion.latitude;
        destinationLongitude = postion.longitude ;
        _destination.name = "nn";
        destinationLocationController.text = "${addresses.first.subLocality}";
        focusDestinationLocationField.unfocus();

    });
  }

  void _getPlacesNames(String searchLocation) async {

    //List<MapBoxPlace> tempList  = [MapBoxPlace(placeName: 'isamabad'),MapBoxPlace(placeName: 'isamabad'),MapBoxPlace(placeName: 'isamabad'),] ;
    var tempList = await placesSearch.getPlaces(searchLocation);
    // print('cordinates : ${tempList[0].geometry.coordinates.first}');
    // print('cordinates : ${tempList[0].geometry.coordinates.last}');

    names.clear();
    filteredNames.clear();

    for(int i=0;i<tempList.length;i++)
    {
      names.add(tempList[i]);
    }

    //names.shuffle();
    for(int j=0;j<names.length;j++)
      filteredNames.add(names[j]);
  }

}
