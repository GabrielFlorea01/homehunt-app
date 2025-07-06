import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:homehunt/firebase/secrets/api_key.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:flutter/material.dart';

Future<LatLng?> geocodeAddress(String address) async {
  final url = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
    'address': '$address, Romania',
    'key': googleMapsApiKey,
  });
  final resp = await http.get(url);
  if (resp.statusCode != 200) return null;
  final body = json.decode(resp.body) as Map<String, dynamic>;
  if (body['status'] != 'OK' || (body['results'] as List).isEmpty) {
    return null;
  }
  final loc =
      body['results'][0]['geometry']['location'] as Map<String, dynamic>;
  return LatLng((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble());
}

  Widget buildMapSection(String address) {
    return FutureBuilder<LatLng?>(
      future: geocodeAddress(address),
      builder: (context, snap) {
        if (snap.hasError) {
          return Text(
            'Map error: ${snap.error}',
            style: const TextStyle(color: Colors.red),
          );
        }
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final loc = snap.data;
        if (loc == null) return const Text('Cannot display map');
        return SizedBox(
          height: 200,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: loc, zoom: 14),
            markers: {Marker(markerId: MarkerId(address), position: loc)},
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),
        );
      },
    );
  }