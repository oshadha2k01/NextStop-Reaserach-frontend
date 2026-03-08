import 'bus_stop.dart';

class BusRouteModel {
  final String? id;
  final String routeName;
  final String? routeNumber;
  final List<BusStop> stops;

  BusRouteModel({
    this.id,
    required this.routeName,
    this.routeNumber,
    required this.stops,
  });

  factory BusRouteModel.fromJson(Map<String, dynamic> json) {
    List<BusStop> stops = [];
    if (json['stops'] != null) {
      stops = (json['stops'] as List)
          .map((s) => BusStop.fromJson(s as Map<String, dynamic>))
          .toList();
    }
    return BusRouteModel(
      id: json['_id']?.toString(),
      routeName: json['routeName'] ?? json['name'] ?? '',
      routeNumber: json['routeNumber']?.toString(),
      stops: stops,
    );
  }

  Map<String, dynamic> toJson() => {
    'routeName': routeName,
    if (routeNumber != null) 'routeNumber': routeNumber,
    'stops': stops.map((s) => s.toJson()).toList(),
  };

  static List<BusRouteModel> getAllRoutes() {
    return [
      // Route 177: Kaduwela - Kollupitiya
      BusRouteModel(
        routeName: 'Route 177: Kaduwela - Kollupitiya',
        stops: [
          BusStop(name: 'Kaduwela Bus Stand', latitude: 6.9351, longitude: 79.9841),
          BusStop(name: 'Kothalawala', latitude: 6.9195, longitude: 79.9705),
          BusStop(name: 'SLIIT Campus', latitude: 6.9147, longitude: 79.9729),
          BusStop(name: 'Pittugala', latitude: 6.9201, longitude: 79.9662),
          BusStop(name: 'Chandrika Kumaratunga Mw', latitude: 6.9146, longitude: 79.9733),
          BusStop(name: 'Malabe Junction', latitude: 6.9036, longitude: 79.9547),
          BusStop(name: 'Thalahena', latitude: 6.9015, longitude: 79.9402),
          BusStop(name: 'Koswatta', latitude: 6.9042, longitude: 79.9323),
          BusStop(name: 'Battaramulla Junction', latitude: 6.8995, longitude: 79.9229),
          BusStop(name: 'Ethul Kotte', latitude: 6.9014, longitude: 79.9081),
          BusStop(name: 'Diyatha Uyana / Waters Edge', latitude: 6.9008, longitude: 79.9105),
          BusStop(name: 'Rajagiriya (Welikada)', latitude: 6.9091, longitude: 79.8961),
          BusStop(name: 'Ayurveda Junction', latitude: 6.9118, longitude: 79.8885),
          BusStop(name: 'Castle Street (Hospital)', latitude: 6.9135, longitude: 79.8821),
          BusStop(name: 'Devi Balika Junction', latitude: 6.9142, longitude: 79.8800),
          BusStop(name: 'Borella (Senanayake Junction)', latitude: 6.9158, longitude: 79.8766),
          BusStop(name: 'St. Bridgets', latitude: 6.9196, longitude: 79.8641),
          BusStop(name: 'Horton Place (Wijerama Mw)', latitude: 6.9125, longitude: 79.8685),
          BusStop(name: 'Liberty Junction', latitude: 6.9094, longitude: 79.8530),
          BusStop(name: 'Kollupitiya (Station Road)', latitude: 6.9082, longitude: 79.8504),
        ],
      ),

      // Route 190: Meegoda - Pettah
      BusRouteModel(
        routeName: 'Route 190: Meegoda - Pettah',
        stops: [
          BusStop(name: 'Meegoda', latitude: 6.8398, longitude: 80.0475),
          BusStop(name: 'Godagama', latitude: 6.8519, longitude: 80.0097),
          BusStop(name: 'Athurugiriya', latitude: 6.8774, longitude: 79.9897),
          BusStop(name: 'Malabe', latitude: 6.9045, longitude: 79.9548),
          BusStop(name: 'Battaramulla', latitude: 6.8998, longitude: 79.9134),
          BusStop(name: 'Rajagiriya', latitude: 6.9092, longitude: 79.8964),
          BusStop(name: 'Pettah (Fort)', latitude: 6.9344, longitude: 79.8499),
        ],
      ),

      // Route 138: Homagama - Pettah
      BusRouteModel(
        routeName: 'Route 138: Homagama - Pettah',
        stops: [
          BusStop(name: 'Homagama', latitude: 6.8412, longitude: 79.9981),
          BusStop(name: 'Kottawa Junction', latitude: 6.8436, longitude: 79.9641),
          BusStop(name: 'Pannipitiya', latitude: 6.8500, longitude: 79.9500),
          BusStop(name: 'Maharagama', latitude: 6.8494, longitude: 79.9236),
          BusStop(name: 'Nugegoda', latitude: 6.8744, longitude: 79.8863),
          BusStop(name: 'Kirulapone', latitude: 6.8845, longitude: 79.8774),
          BusStop(name: 'Thummulla', latitude: 6.9034, longitude: 79.8614),
          BusStop(name: 'Town Hall', latitude: 6.9147, longitude: 79.8601),
          BusStop(name: 'Pettah (Main Stand)', latitude: 6.9361, longitude: 79.8523),
        ],
      ),

      // Route 17: Panadura - Kandy
      BusRouteModel(
        routeName: 'Route 17: Panadura - Kandy',
        stops: [
          BusStop(name: 'Panadura Bus Stand', latitude: 6.7111, longitude: 79.9074),
          BusStop(name: 'Dehiwala Junction', latitude: 6.8502, longitude: 79.8635),
          BusStop(name: 'Nugegoda', latitude: 6.8744, longitude: 79.8863),
          BusStop(name: 'Battaramulla', latitude: 6.8998, longitude: 79.9134),
          BusStop(name: 'Malabe', latitude: 6.9045, longitude: 79.9548),
          BusStop(name: 'Kaduwela', latitude: 6.9442, longitude: 79.9866),
          BusStop(name: 'Biyagama', latitude: 6.9322, longitude: 80.0041),
          BusStop(name: 'Nittambuwa', latitude: 7.1444, longitude: 80.0954),
          BusStop(name: 'Kandy (Goods Shed)', latitude: 7.2912, longitude: 80.6331),
        ],
      ),
    ];
  }

  static List<BusRouteModel> searchRoutes(String from, String to) {
    final allRoutes = getAllRoutes();
    final results = <BusRouteModel>[];
    
    // Step 2: Normalize user input to lowercase and remove extra spaces
    // Example: "Kaduwela " → "kaduwela"
    final fromLower = from.toLowerCase().trim();
    final toLower = to.toLowerCase().trim();

    // Step 3: Loop through each route to find matches
    for (var route in allRoutes) {
      int fromIndex = -1;  // Position of "from" stop (-1 means not found)
      int toIndex = -1;    // Position of "to" stop (-1 means not found)

      // Step 4: Search through all stops in this route
      for (int i = 0; i < route.stops.length; i++) {
        final stopName = route.stops[i].name.toLowerCase();
        
        // Step 5: Check if stop matches "from" location
        // Uses contains() so "Kaduwela" matches "Kaduwela Bus Stand"
        if (fromIndex == -1 && stopName.contains(fromLower)) {
          fromIndex = i;  // Remember position of first match
        }
        
        // Step 6: Check if stop matches "to" location
        if (stopName.contains(toLower)) {
          toIndex = i;  // Keep updating until last match
        }
      }

      // Step 7: Validate the route
      // - Both stops must exist (not -1)
      // - "from" must come before "to" in the route
      if (fromIndex != -1 && toIndex != -1 && fromIndex < toIndex) {
        // Step 8: Extract only the relevant portion of the route
        // sublist(fromIndex, toIndex + 1) gets stops between from and to
        final relevantStops = route.stops.sublist(fromIndex, toIndex + 1);
        
        // Step 9: Create a new route with only these stops
        results.add(BusRouteModel(
          routeName: route.routeName,
          stops: relevantStops,
        ));
      }
    }

    // Step 10: Return all matching routes
    return results;
  }
}
