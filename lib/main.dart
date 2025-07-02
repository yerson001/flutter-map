import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Custom Map-server with OSRM',
      home: const MapWithRoute(),
    );
  }
}

class MapWithRoute extends StatefulWidget {
  const MapWithRoute({super.key});

  @override
  State<MapWithRoute> createState() => _MapWithRouteState();
}

class _MapWithRouteState extends State<MapWithRoute> {
  final MapController _mapController = MapController();

  LatLng? startPoint;
  LatLng? endPoint;
  bool settingStart = true;

  List<LatLng> routePoints = [];

  @override
  void initState() {
    super.initState();
    // Puedes establecer puntos por defecto si quieres
    startPoint = LatLng(-16.409047, -71.537451);
    endPoint = LatLng(-16.399819, -71.534044);
    fetchRoute();
  }

  Future<void> fetchRoute() async {
    if (startPoint == null || endPoint == null) return;

    try {
      final points = await getRouteFromOSRM(
        startPoint!.latitude,
        startPoint!.longitude,
        endPoint!.latitude,
        endPoint!.longitude,
      );

      setState(() {
        routePoints = points;
      });
    } catch (e) {
      debugPrint('Error fetching route: $e');
    }
  }

  Future<List<LatLng>> getRouteFromOSRM(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) async {
    final url = Uri.parse(
      'http://router.project-osrm.org/route/v1/driving/$lon1,$lat1;$lon2,$lat2?overview=full&geometries=geojson',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final coords = data['routes'][0]['geometry']['coordinates'] as List;

      return coords
          .map<LatLng>(
            (point) => LatLng(point[1] as double, point[0] as double),
          )
          .toList();
    } else {
      throw Exception('Error fetching route');
    }
  }

  void handleMapTap(LatLng tappedPoint) {
    setState(() {
      if (settingStart) {
        startPoint = tappedPoint;
      } else {
        endPoint = tappedPoint;
      }

      settingStart = !settingStart;
    });

    if (startPoint != null && endPoint != null) {
      fetchRoute();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Map con Ruta OSRM'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                routePoints.clear();
                startPoint = null;
                endPoint = null;
                settingStart = true;
              });
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: startPoint ?? LatLng(-16.409047, -71.537451),
          initialZoom: 13,
          onTap: (tapPosition, latlng) => handleMapTap(latlng),
        ),
        children: [
          TileLayer(
            urlTemplate:
                "http://10.0.2.2:8080/styles/test-style/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.example.app',
          ),
          if (routePoints.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: routePoints,
                  color: Colors.blue,
                  strokeWidth: 4,
                ),
              ],
            ),
          MarkerLayer(
            markers: [
              if (startPoint != null)
                Marker(
                  width: 80,
                  height: 80,
                  point: startPoint!,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.green,
                    size: 40,
                  ),
                ),
              if (endPoint != null)
                Marker(
                  width: 80,
                  height: 80,
                  point: endPoint!,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
