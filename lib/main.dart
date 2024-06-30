import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
        home: CheckPermissions(), debugShowCheckedModeBanner: false);
  }
}

class CheckPermissions extends StatefulWidget {
  const CheckPermissions({super.key});

  @override
  State<CheckPermissions> createState() => _CheckPermissionsState();
}

class _CheckPermissionsState extends State<CheckPermissions> {
  Future<bool>? canGetPosition;

  @override
  void initState() {
    canGetPosition = checkPermissions();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder(
        future: canGetPosition,
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return const CalculateDistanceState();
          }

          return const Center(
              child: CircularProgressIndicator(color: Colors.white));
        },
      ),
    );
  }

  Future<bool> checkPermissions() async {
    bool locationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!locationServiceEnabled) {
      return Future.error('Location services are disabled.');
    }

    LocationPermission locationPermission = await Geolocator.checkPermission();

    if (locationPermission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    if (locationPermission == LocationPermission.denied) {
      locationPermission = await Geolocator.requestPermission();
      if (locationPermission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }

    return true;
  }
}

class CalculateDistanceState extends StatefulWidget {
  const CalculateDistanceState({super.key});

  @override
  State<CalculateDistanceState> createState() => CalculateDistanceStateState();
}

class CalculateDistanceStateState extends State<CalculateDistanceState> {
  int counter = 0;
  Position? previousPosition;
  double distanceInMeters = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder(
        stream: Geolocator.getPositionStream(locationSettings: LocationSettings(distanceFilter: counter * 100)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            if (counter == 0) {
              counter++;
              previousPosition = snapshot.data;
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }

            final currentPosition = snapshot.data as Position;
            distanceInMeters += Geolocator.distanceBetween(
                    previousPosition!.latitude,
                    previousPosition!.longitude,
                    currentPosition.latitude,
                    currentPosition.longitude) /
                1000;
            previousPosition = currentPosition;

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('${distanceInMeters.toStringAsFixed(1)} KM', style: getDefaultAppFont()),
                  const SizedBox(height: 100),
                  IconButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) =>
                                ShareDistance(distance: distanceInMeters)));
                      },
                      icon: const Icon(
                        Icons.stop_circle_rounded,
                        size: 30,
                        color: Colors.white,
                      ))
                ],
              ),
            );
          }

          return const Center(
              child: CircularProgressIndicator(color: Colors.white));
        },
      ),
    );
  }
}

class ShareDistance extends StatelessWidget {
  final double distance;
  const ShareDistance({super.key, required this.distance});

  @override
  Widget build(BuildContext context) {
    var congratulationsOneMoreRoundConcluded =
        'Congratulations. One more round concluded.';
    var distanceKM = '${distance.toStringAsFixed(1)} KM';
    return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            const Image(
              image: AssetImage('assets/ryan.gif'),
              fit: BoxFit.fitHeight,
              height: double.infinity,
              width: double.infinity,
              alignment: Alignment.center,
              opacity: AlwaysStoppedAnimation(0.2),
            ),
            Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(congratulationsOneMoreRoundConcluded,
                        style: GoogleFonts.getFont('Roboto',
                            color: Colors.white, fontSize: 12)),
                    Text(distanceKM, style: getDefaultAppFont()),
                    const SizedBox(height: 100),
                    IconButton(
                        onPressed: () {
                          Share.share(
                              '$congratulationsOneMoreRoundConcluded ${distance.toStringAsFixed(1)} KM.');
                        },
                        icon: const Icon(
                          Icons.share,
                          size: 30,
                          color: Colors.white,
                        )),
                  ]),
            )
          ],
        ));
  }
}

TextStyle getDefaultAppFont() {
  return GoogleFonts.getFont('Roboto', color: Colors.white, fontSize: 24);
}
