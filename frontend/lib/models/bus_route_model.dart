import 'bus_stop.dart';

class BusRouteModel {
  final String routeName;
  final List<BusStop> stops;

  BusRouteModel({
    required this.routeName,
    required this.stops,
  });

  static List<BusRouteModel> getAllRoutes() {
    return [
      // Route 177: Kaduwela - Kollupitiya
      BusRouteModel(
        routeName: 'Route 177: Kaduwela - Kollupitiya',
        stops: [
          BusStop(name: 'Kaduwela Bus Stand', latitude: 6.9442, longitude: 79.9866, keyLandmark: 'Start Terminal / Clock Tower'),
          BusStop(name: 'Kothalawala', latitude: 6.9268, longitude: 79.9701, keyLandmark: 'SLIIT University Area'),
          BusStop(name: 'Malabe Junction', latitude: 6.9045, longitude: 79.9548, keyLandmark: 'Malabe Clock Tower'),
          BusStop(name: 'Thalangama', latitude: 6.9110, longitude: 79.9324, keyLandmark: 'Near ITI / Sludge Treatment'),
          BusStop(name: 'Koswatta', latitude: 6.9071, longitude: 79.9214, keyLandmark: 'Thalangama Police Station'),
          BusStop(name: 'Battaramulla', latitude: 6.8998, longitude: 79.9134, keyLandmark: 'Suhurupaya (Immigration Office)'),
          BusStop(name: 'Rajagiriya', latitude: 6.9092, longitude: 79.8964, keyLandmark: 'Election Commission Office'),
          BusStop(name: 'Ayurveda Junction', latitude: 6.9115, longitude: 79.8863, keyLandmark: 'Ayurveda Hospital'),
          BusStop(name: 'Borella', latitude: 6.9142, longitude: 79.8778, keyLandmark: 'Senanayake Junction'),
          BusStop(name: 'Horton Place', latitude: 6.9103, longitude: 79.8692, keyLandmark: 'Near Nelum Pokuna'),
          BusStop(name: 'Liberty Plaza', latitude: 6.9124, longitude: 79.8516, keyLandmark: 'Liberty Junction'),
          BusStop(name: 'Kollupitiya', latitude: 6.9114, longitude: 79.8488, keyLandmark: 'Station Road / End Terminal'),
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
