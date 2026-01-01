import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Removes the "Debug" banner
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
  // Coordinates for Colombo, Sri Lanka (matching your image)
  static const LatLng _colomboLocation = LatLng(6.9271, 79.8612);

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
              
              // ---------------- SECTION 1: HEADER ----------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Little Bus Icon/Logo
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.directions_bus, color: Colors.orange),
                  ),
                  // Greeting Text
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("Hi User", 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Greetings!", 
                        style: TextStyle(color: Colors.grey)),
                    ],
                  )
                ],
              ),
              
              const SizedBox(height: 20),

              // ---------------- SECTION 2: SEARCH BAR ----------------
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5), // Light purple background
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

              // ---------------- SECTION 3: TOP SQUARES (ICONS) ----------------
              // I used a GridView to make 6 squares (2 rows of 3)
              GridView.count(
                shrinkWrap: true, // Important: allows grid inside a Column
                physics: const NeverScrollableScrollPhysics(), // Disables internal scrolling
                crossAxisCount: 3,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                // These are your 6 grey squares
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

              // ---------------- SECTION 4: THE GOOGLE MAP ----------------
              // This is the large square/rectangle in the middle
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.grey.shade300, // Placeholder color while loading
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: GoogleMap(
                      initialCameraPosition: const CameraPosition(
                        target: _colomboLocation,
                        zoom: 12,
                      ),
                      myLocationEnabled: true, // Shows the blue dot
                      zoomControlsEnabled: false, // Hides +/- buttons for cleaner look
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ---------------- SECTION 5: BOTTOM BAR ----------------
              // Settings, Account, etc.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBottomCircle(Icons.home, true), // Active item
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

  // Helper widget to build the grey squares at the top
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
          // You can uncomment the line below if you want text labels inside the squares
          // Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  // Helper widget to build the bottom circular buttons
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