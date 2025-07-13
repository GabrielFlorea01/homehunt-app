import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:homehunt/firebase/secrets/api_key.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:flutter/material.dart';

// Model de widget pentru harta afisata in card-uri

// obtine coordonatele geografice ale unei adrese
Future<LatLng?> geocodeAddress(String address) async {
  // URL-ul pentru request + Romania ca sa fie mai precis
  final url = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
    'address': '$address, Romania',
    'key': googleMapsApiKey,
  });
  // request-ul HTTP
  final resp = await http.get(url);
  if (resp.statusCode != 200) return null;
  // Decodific raspunsul JSON
  final body = json.decode(resp.body) as Map<String, dynamic>;

  // daca statusul e OK si exista rezultate
  if (body['status'] != 'OK' || (body['results'] as List).isEmpty) {
    return null;
  }
  // coordonatele din raspuns
  final loc =
      body['results'][0]['geometry']['location'] as Map<String, dynamic>;
  return LatLng((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble());
}

//afiseaza o harta pentru adresa
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
      // inca astept raspunsul, afisez un loader
      if (snap.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      // nu am primit coordonate, afisez mesaj
      final loc = snap.data;
      if (loc == null) return const Text('Nu se poate afisa harta');
      //am coordonatele, afisez harta cu marker pe adresa
      return SizedBox(
        height: 500,
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
