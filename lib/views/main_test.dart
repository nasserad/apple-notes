// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// void main() async {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: EmergencyTrackingScreen(),
//     );
//   }
// }

// class EmergencyTrackingScreen extends StatefulWidget {
//   @override
//   _EmergencyTrackingScreenState createState() => _EmergencyTrackingScreenState();
// }

// class _EmergencyTrackingScreenState extends State<EmergencyTrackingScreen> {
//   late GoogleMapController _mapController;
//   LatLng _initialLocation = const LatLng(25.276987, 55.296249); // Default location
//   List<String> statusList = [
//     "Alert Created",
//     "Responder Assigned",
//     "Responder En Route",
//     "Responder Onsite",
//     "Case Resolved",
//   ];
//   int currentStatusIndex = 0;

//   void _onMapCreated(GoogleMapController controller) {
//     _mapController = controller;
//     // Simulate real-time updates for demo
//     _simulateStatusUpdates();
//   }

//   void _simulateStatusUpdates() {
//     Future.delayed(const Duration(seconds: 5), () {
//       if (currentStatusIndex < statusList.length - 1) {
//         setState(() {
//           currentStatusIndex++;
//         });
//         _simulateStatusUpdates();
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           // Google Map
//           GoogleMap(
//             onMapCreated: _onMapCreated,
//             initialCameraPosition: CameraPosition(
//               target: _initialLocation,
//               zoom: 14.0,
//             ),
//             markers: {
//               Marker(
//                 markerId: const MarkerId('responder'),
//                 position: _initialLocation, // Example location
//                 infoWindow: const InfoWindow(title: 'Responder Location'),
//               )
//             },
//           ),
//           // UI Overlay
//           Align(
//             alignment: Alignment.bottomCenter,
//             child: Container(
//               height: MediaQuery.of(context).size.height * 0.4,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.2),
//                     blurRadius: 10,
//                     offset: const Offset(0, -2),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Padding(
//                     padding: EdgeInsets.all(16.0),
//                     child: Text(
//                       "Emergency Tracking",
//                       style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                     ),
//                   ),
//                   Expanded(
//                     child: ListView.builder(
//                       itemCount: statusList.length,
//                       itemBuilder: (context, index) {
//                         return ListTile(
//                           leading: Icon(
//                             index <= currentStatusIndex
//                                 ? Icons.check_circle
//                                 : Icons.radio_button_unchecked,
//                             color: index <= currentStatusIndex
//                                 ? Colors.green
//                                 : Colors.grey,
//                           ),
//                           title: Text(statusList[index]),
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
