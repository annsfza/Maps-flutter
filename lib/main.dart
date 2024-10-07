import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; // Import package geocoding

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  LatLng _markerLocation = LatLng(0, 0); // Lokasi default awal (akan diubah)
  double _zoom = 13.0; // Level zoom awal
  final MapController _mapController = MapController(); // Mengatur MapController sebagai final

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  String _currentAddress = ''; // Untuk menyimpan detail alamat saat ini

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Mendapatkan lokasi saat ini saat inisialisasi
  }

  Future<void> _getCurrentLocation() async {
    // Meminta izin lokasi
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Jika izin ditolak, coba minta izin
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Jika pengguna menolak izin
        return;
      }
    }

    // Jika izin diberikan, dapatkan lokasi saat ini
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _markerLocation = LatLng(position.latitude, position.longitude);
      _mapController.move(_markerLocation, _zoom); // Memindahkan peta ke lokasi saat ini
      _updateAddress(_markerLocation); // Update address saat inisialisasi
    });
  }

  Future<void> _updateAddress(LatLng location) async {
    // Mendapatkan detail alamat dari lokasi
    List<Placemark> placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
    if (placemarks.isNotEmpty) {
      setState(() {
        _currentAddress = '${placemarks.first.street}, ${placemarks.first.locality}, ${placemarks.first.country}'; // Format detail alamat
        _detailsController.text = _currentAddress; // Mengisi TextField dengan alamat
      });
    }
  }

  Future<void> _goToCurrentLocation() async {
    // Panggil fungsi untuk mendapatkan lokasi saat ini
    await _getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Contoh OpenStreetMap dengan Marker'),
        ),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0), // Menambahkan padding horizontal
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 1),
                    ),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        center: _markerLocation,
                        zoom: _zoom,
                        onPositionChanged: (position, hasGesture) {
                          setState(() {
                            if (position.center != null) {
                              _markerLocation = position.center!;
                              _updateAddress(_markerLocation); // Update address saat peta bergerak
                            }
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                          subdomains: ['a', 'b', 'c'],
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              width: 80.0,
                              height: 80.0,
                              point: _markerLocation,
                              builder: (ctx) => const Icon(Icons.location_pin,
                                  color: Colors.red, size: 40),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 20, // Jarak dari bawah
                    right: 20, // Jarak dari kanan
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // Untuk menjaga ukuran kolom sesuai kebutuhan
                      children: [
                        FloatingActionButton(
                          heroTag: null,
                          mini: true,
                          onPressed: _goToCurrentLocation,
                          child: const Icon(Icons.my_location),
                        ),
                        SizedBox(height: 10), // Spasi antara tombol
                        FloatingActionButton(
                          heroTag: null,
                          mini: true,
                          onPressed: () {
                            setState(() {
                              if (_zoom < 18.0) {
                                _zoom++;
                                _mapController.move(_markerLocation, _zoom);
                              }
                            });
                          },
                          child: const Icon(Icons.add),
                        ),
                        SizedBox(height: 10), // Spasi antara tombol
                        FloatingActionButton(
                          heroTag: null,
                          mini: true,
                          onPressed: () {
                            setState(() {
                              if (_zoom > 1.0) {
                                _zoom--;
                                _mapController.move(_markerLocation, _zoom);
                              }
                            });
                          },
                          child: const Icon(Icons.remove),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Align text to the start
                children: [
                  const Text(
                    'Cari Lokasi',
                    style: TextStyle(
                      fontWeight: FontWeight.bold, // Font weight bold
                      fontSize: 16, // Ukuran font
                    ),
                  ),
                  SizedBox(height: 8), // Spasi antara teks dan TextField
                  TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Cari nama jalan, kelurahan, dsb',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      // Implementasi pencarian lokasi di sini
                      // Misalnya, Anda dapat menggunakan Geocoding API untuk menemukan lokasi
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Align text to the start
                children: [
                  const Text(
                    'Alamat Lengkap',
                    style: TextStyle(
                      fontWeight: FontWeight.bold, // Font weight bold
                      fontSize: 16, // Ukuran font
                    ),
                  ),
                  SizedBox(height: 8), // Spasi antara teks dan TextField
                  TextField(
                    controller: _detailsController,
                    decoration: InputDecoration(
                      labelText: 'Location Now', 
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2, // Biarkan pengguna menulis detail lebih banyak
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
