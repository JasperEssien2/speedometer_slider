import 'package:flutter/material.dart';

import 'widget/speedometer_slider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      home: const Scaffold(
        body: Center(
          child: SizedBox(
            height: 300,
            width: 300,
            child: CustomSlider(),
          ),
        ),
      ),
    );
  }
}
