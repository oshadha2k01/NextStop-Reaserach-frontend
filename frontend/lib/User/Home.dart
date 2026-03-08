import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const LatLng _colomboLocation = LatLng(6.9271, 79.8612);
  
  // --- Live Tracking Variables ---
  final Completer<GoogleMapController> _mapController = Completer();
  IO.Socket? socket;
  LatLng? liveBusLocation;
  Map<String, dynamic>? busData;

  @override
  void initState() {
    super.initState();
    initSocketConnection();
  }

  void initSocketConnection() {
    // ⚠️ CRITICAL: Replace with your laptop's IPv4 address!
    // If using a physical phone: Use your Wi-Fi IP (e.g., 'http://192.168.8.118:5000')
    // If using Android Studio Emulator: Use 'http://10.0.2.2:5000'
    String serverUrl = 'http://192.168.8.118:5000'; 

    socket = IO.io(serverUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build()
    );

    socket!.connect();

    socket!.onConnect((_) {
      print('🟢 Connected to Node.js Live Tracking Server');
    });

    // Listen for the ESP32 data coming from Node.js
    socket!.on('bus_location_update', (data) {
      print('🚌 Live Bus Update Received: $data');
      
      if (mounted) {
        setState(() {
          liveBusLocation = LatLng(data['lat'], data['lng']);
          busData = data;
        });
        
        // Move the map camera to follow the bus automatically!
        _moveCameraToBus(liveBusLocation!);
      }
    });

    socket!.onDisconnect((_) {
      print('🔴 Disconnected from Server');
    });
  }

  Future<void> _moveCameraToBus(LatLng position) async {
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newLatLng(position));
  }

  @override
  void dispose() {
    socket?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------- HEADER ----------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.directions_bus, color: Colors.orange),
                  ),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("Hi User", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Greetings!", style: TextStyle(color: Colors.grey)),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 20),

              // ---------------- SEARCH BAR ----------------
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.menu, color: Colors.black54),
                    SizedBox(width: 10),
                    Text("where to go?", style: TextStyle(color: Colors.black45)),
                    Spacer(),
                    Icon(Icons.search, color: Colors.black54),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ---------------- TOP ICONS ----------------
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  _buildMenuSquare(Icons.directions_bus, "Bus"),
                  _buildMenuSquare(Icons.train, "Train"),
                  _buildMenuSquare(Icons.local_taxi, "Taxi"),
                  _buildMenuSquare(Icons.schedule, "Schedule"),
                  _buildMenuSquare(Icons.confirmation_number, "Tickets"),
                  _buildMenuSquare(Icons.map, "Routes"),
                ],
              ),
              const SizedBox(height: 20),

              // ---------------- GOOGLE MAP ----------------
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.grey.shade300,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: GoogleMap(
                      onMapCreated: (GoogleMapController controller) {
                        _mapController.complete(controller);
                      },
                      initialCameraPosition: const CameraPosition(
                        target: _colomboLocation,
                        zoom: 14,
                      ),
                      myLocationEnabled: true,
                      zoomControlsEnabled: false,
                      // Put the marker on the map if we have data!
                      markers: liveBusLocation == null ? {} : {
                        Marker(
                          markerId: const MarkerId('live_bus'),
                          position: liveBusLocation!,
                          infoWindow: InfoWindow(
                            title: 'Bus: ${busData?['bus_id'] ?? "Unknown"}',
                            snippet: 'Speed: ${busData?['speed'] ?? 0} km/h | Status: ${busData?['status'] ?? "N/A"}',
                          ),
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                        )
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ---------------- BOTTOM BAR ----------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBottomCircle(Icons.home, true),
                  _buildBottomCircle(Icons.settings, false),
                  _buildBottomCircle(Icons.person, false),
                  _buildBottomCircle(Icons.notifications, false),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSquare(IconData icon, String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey.shade700, size: 30),
        ],
      ),
    );
  }

  Widget _buildBottomCircle(IconData icon, bool isActive) {
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        color: isActive ? Colors.grey.shade400 : Colors.grey.shade200,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.black54),
    );
  }
}