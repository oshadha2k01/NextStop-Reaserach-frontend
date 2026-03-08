import 'package:flutter/material.dart';
import 'models/bus_stop.dart';
import 'screens/prediction_modal.dart';

void main() {
  runApp(const TestPredictionApp());
}

class TestPredictionApp extends StatelessWidget {
  const TestPredictionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Route 177 - Prediction Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFFF6B35),
        useMaterial3: true,
      ),
      home: const TestHomePage(),
    );
  }
}

class TestHomePage extends StatelessWidget {
  const TestHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Route 177: Kaduwela - Kollupitiya
    final route177Stops = [
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
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Route 177 Test'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Route 177',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Kaduwela - Kollupitiya',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              '${route177Stops.length} stops',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => PredictionModal(
                    busId: '177',
                    allStops: route177Stops,
                    currentLocation: 'Kaduwela Bus Stand',
                  ),
                );
              },
              icon: const Icon(Icons.psychology),
              label: const Text('Open Prediction Modal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
