import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weather_app/secrets/secrets.dart';
import 'package:http/http.dart' as http;

class DisplayWeatherScreen extends StatefulWidget {
  const DisplayWeatherScreen({super.key});

  @override
  State<DisplayWeatherScreen> createState() => _DisplayWeatherScreenState();
}

class _DisplayWeatherScreenState extends State<DisplayWeatherScreen> {
  late Future<Map<String, dynamic>> weather;

  TextEditingController myController = TextEditingController()..text = 'Mumbai';

  Future<Map<String, dynamic>> getCurrentWeather(String cityName) async {
    try {
      final res = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?q=$cityName&units=metric&APPID=$OPEN_WEATHER_API_KEY',
        ),
      );

      final data = jsonDecode(res.body);
      if (data['cod'] != '200') {
        myController.text = "Mumbai";
        throw "An unexpected error occurred.\nPlease Try Again by clicking the refresh button.";
      }

      return data;
    } catch (e) {
      throw e.toString();
    }
  }

  @override
  void initState() {
    super.initState();
    weather = getCurrentWeather(myController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "MyWeatherApp",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                weather = getCurrentWeather(myController.text);
              });
            },
            icon: const Icon(
              Icons.refresh_outlined,
            ),
          )
        ],
      ),
      body: FutureBuilder(
        future: weather,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                textAlign: TextAlign.center,
              ),
            );
          } else if (snapshot.hasData) {
            final data = snapshot.data;
            final currWeatherData = data!['list'][0];
            final currentSkyData = currWeatherData['weather'][0];
            final currHumidity = currWeatherData["main"]["humidity"];
            final currWindSpeed = currWeatherData["wind"]["speed"];
            final currPressure = currWeatherData["main"]["pressure"];
            final hourlyForecastList = data['list'];

            return ListView(
              shrinkWrap: true,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: myController,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () {
                              setState(() {
                                weather = getCurrentWeather(myController.text);
                              });
                            },
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                width: 0.8, color: Colors.grey.shade800),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: Card(
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Text(
                                      '${currWeatherData['main']['temp']} °C',
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 16,
                                    ),
                                    Icon(
                                      currentSkyData['main'] == "Clouds" ||
                                              currentSkyData['main'] == "Rain"
                                          ? Icons.cloud
                                          : Icons.sunny,
                                      size: 64,
                                    ),
                                    const SizedBox(
                                      height: 16,
                                    ),
                                    Text(
                                      currentSkyData['main'],
                                      style: const TextStyle(
                                        fontSize: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      const Text(
                        "Hourly Forecast",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(6, 12, 0, 12),
                        child: SizedBox(
                          height: 120,
                          child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: 5,
                              itemBuilder: (context, index) {
                                final hourlySky =
                                    hourlyForecastList[index + 1]["weather"][0];
                                final timezone = data["city"]["timezone"];
                                final time = DateTime.parse(
                                        hourlyForecastList[index + 1]["dt_txt"])
                                    .add(Duration(seconds: timezone));
                                return HourlyForecastCard(
                                    time: DateFormat.Hm().format(time),
                                    temp: (hourlyForecastList[index + 1]['main']
                                            ['temp'])
                                        .toString(),
                                    icon: hourlySky['main'] == "Clouds" ||
                                            hourlySky['main'] == "Rain"
                                        ? Icons.cloud
                                        : Icons.sunny);
                              }),
                        ),
                      ),
                      const Text(
                        "Additional Information",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            AddInfoItem(
                                category: "Humidity",
                                value: currHumidity.toString(),
                                icon: Icons.water_drop),
                            AddInfoItem(
                                category: "Wind Speed",
                                value: currWindSpeed.toString(),
                                icon: Icons.air),
                            AddInfoItem(
                                category: "Pressure",
                                value: currPressure.toString(),
                                icon: Icons.beach_access),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
        },
      ),
    );
  }
}

// Helper widgets

class HourlyForecastCard extends StatelessWidget {
  const HourlyForecastCard(
      {super.key, required this.time, required this.temp, required this.icon});

  final String time;
  final IconData icon;
  final String temp;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Card(
        elevation: 6,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
          child: Column(
            children: [
              Text(
                this.time,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Icon(
                this.icon,
                size: 32,
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                "${this.temp}°",
                style: const TextStyle(color: Colors.white60),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddInfoItem extends StatelessWidget {
  const AddInfoItem(
      {super.key,
      required this.category,
      required this.value,
      required this.icon});

  final String category;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          Icon(
            this.icon,
            size: 32,
          ),
          const SizedBox(
            height: 6,
          ),
          Text(
            this.category,
            style: const TextStyle(color: Colors.white60),
          ),
          const SizedBox(
            height: 6,
          ),
          Text(
            this.value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
