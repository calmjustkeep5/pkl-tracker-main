import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapSection extends StatelessWidget {
  final double userLat;
  final double userLng;
  final double officeLat = -6.9828; // Koordinat SMK 10
  final double officeLng = 110.4091;

  MapSection({required this.userLat, required this.userLng});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      margin: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(userLat, userLng),
            zoom: 16,
          ),
          markers: {
            Marker(markerId: MarkerId("user"), position: LatLng(userLat, userLng)),
            Marker(
              markerId: MarkerId("office"), 
              position: LatLng(officeLat, officeLng),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            ),
          },
          circles: {
            Circle(
              circleId: CircleId("radius"),
              center: LatLng(officeLat, officeLng),
              radius: 50, // 50 Meter sesuai spek
              fillColor: Colors.blue.withValues(alpha: 0.2),
              strokeColor: Colors.blue,
              strokeWidth: 2,
            ),
          },
        ),
      ),
    );
  }
}