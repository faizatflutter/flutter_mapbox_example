class GetDistanceModel {
  List<Routes> routes;
  List<Waypoints> waypoints;
  String code;
  String uuid;

  GetDistanceModel({this.routes, this.waypoints, this.code, this.uuid});

  GetDistanceModel.fromJson(Map<String, dynamic> json) {
    if (json['routes'] != null) {
      routes = <Routes>[];
      json['routes'].forEach((v) {
        routes.add(new Routes.fromJson(v));
      });
    }
    if (json['waypoints'] != null) {
      waypoints = <Waypoints>[];
      json['waypoints'].forEach((v) {
        waypoints.add(new Waypoints.fromJson(v));
      });
    }
    code = json['code'];
    uuid = json['uuid'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.routes != null) {
      data['routes'] = this.routes.map((v) => v.toJson()).toList();
    }
    if (this.waypoints != null) {
      data['waypoints'] = this.waypoints.map((v) => v.toJson()).toList();
    }
    data['code'] = this.code;
    data['uuid'] = this.uuid;
    return data;
  }
}

class Routes {
  String geometry;
  List<Legs> legs;
  String weightName;
  double weight;
  double duration;
  double distance;

  Routes(
      {this.geometry,
        this.legs,
        this.weightName,
        this.weight,
        this.duration,
        this.distance});

  Routes.fromJson(Map<String, dynamic> json) {
    geometry = json['geometry'];
    if (json['legs'] != null) {
      legs = <Legs>[];
      json['legs'].forEach((v) {
        legs.add(new Legs.fromJson(v));
      });
    }
    weightName = json['weight_name'];
    weight = json['weight'];
    duration = json['duration'];
    distance = json['distance'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['geometry'] = this.geometry;
    if (this.legs != null) {
      data['legs'] = this.legs.map((v) => v.toJson()).toList();
    }
    data['weight_name'] = this.weightName;
    data['weight'] = this.weight;
    data['duration'] = this.duration;
    data['distance'] = this.distance;
    return data;
  }
}

class Legs {
  Annotation annotation;
  String summary;
  double weight;
  double duration;
  //List<Null> steps;
  double distance;

  Legs(
      {this.annotation,
        this.summary,
        this.weight,
        this.duration,
      //  this.steps,
        this.distance});

  Legs.fromJson(Map<String, dynamic> json) {
    annotation = json['annotation'] != null
        ? new Annotation.fromJson(json['annotation'])
        : null;
    summary = json['summary'];
    weight = json['weight'];
    duration = json['duration'];
   // if (json['steps'] != null) {
     // steps = new List<Null>();
     // json['steps'].forEach((v) {
      //  steps.add(new Null.fromJson(v));
     // });
    //}
    distance = json['distance'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.annotation != null) {
      data['annotation'] = this.annotation.toJson();
    }
    data['summary'] = this.summary;
    data['weight'] = this.weight;
    data['duration'] = this.duration;
   // if (this.steps != null) {
   //   data['steps'] = this.steps.map((v) => v.toJson()).toList();
    //}
    data['distance'] = this.distance;
    return data;
  }
}

class Annotation {
  List<double> distance;
  List<double> duration;

  Annotation({this.distance, this.duration});

  Annotation.fromJson(Map<String, dynamic> json) {
    distance = json['distance'].cast<double>();
    duration = json['duration'].cast<double>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['distance'] = this.distance;
    data['duration'] = this.duration;
    return data;
  }
}

class Waypoints {
  double distance;
  String name;
  List<double> location;

  Waypoints({this.distance, this.name, this.location});

  Waypoints.fromJson(Map<String, dynamic> json) {
    distance = json['distance'];
    name = json['name'];
    location = json['location'].cast<double>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['distance'] = this.distance;
    data['name'] = this.name;
    data['location'] = this.location;
    return data;
  }
}
