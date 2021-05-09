import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'constants.dart';
import 'package:flutter_blue/flutter_blue.dart';

class MainScreen extends StatefulWidget {
  static String id = "/main";

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  final textController = TextEditingController();
  String lampiId = "";

  double _hueSliderPosition = 359.9;
  double _saturationSliderPosition = 359.9;
  double _brightnessSliderPosition = 359.9;

  bool on = true;

  FlutterBlue flutterBlue;

  final List<Color> _colors = [
    Colors.red,
    Colors.yellow,
    Colors.green,
    Colors.cyan,
    Colors.blueAccent,
    Colors.purple,
    Colors.red
  ];

  Color calculateSelectedColor(colors, position, maxWidth) {
    //determine color
    Color _currentColor;
    double positionInColorArray = (position / maxWidth * (colors.length - 1));
    print(positionInColorArray);
    int index = positionInColorArray.truncate();
    print(index);
    double remainder = positionInColorArray - index;
    if (remainder == 0.0) {
      _currentColor = colors[index];
    } else {
      //calculate new color
      int redValue = colors[index].red == colors[index + 1].red
          ? colors[index].red
          : (colors[index].red +
                  (colors[index + 1].red - colors[index].red) * remainder)
              .round();
      int greenValue = colors[index].green == colors[index + 1].green
          ? colors[index].green
          : (colors[index].green +
                  (colors[index + 1].green - colors[index].green) * remainder)
              .round();
      int blueValue = colors[index].blue == colors[index + 1].blue
          ? colors[index].blue
          : (colors[index].blue +
                  (colors[index + 1].blue - colors[index].blue) * remainder)
              .round();
      _currentColor = Color.fromARGB(255, redValue, greenValue, blueValue);
    }
    return _currentColor;
  }

  Color currentColor = Color(0xFFFFFF);
  Color shadedColor = Color(0xFFFFFF);
  Color brightnessColor = Color(0xFFFFFF);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) => startColor(context));
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  void startColor(context) async {
    await Future.delayed(Duration(milliseconds: 1), () {
      setState(() {
        flutterBlue = FlutterBlue.instance;

        _hueSliderPosition = 0;
        currentColor = calculateSelectedColor(_colors, 0, 360.0);
        shadedColor = calculateSelectedColor(
            [Colors.white, currentColor], _saturationSliderPosition, 360.0);
        brightnessColor = calculateSelectedColor(
            [Colors.black, shadedColor], _brightnessSliderPosition, 360.0);

        // Start scanning
        flutterBlue.startScan(timeout: Duration(seconds: 4));

        // Listen to scan results
        var subscription = flutterBlue.scanResults.listen((results) {
          // do something with scan results
          for (ScanResult r in results) {
            print('${r.device} found! rssi: ${r.rssi}');
          }
        });

// Stop scanning
        flutterBlue.stopScan();


      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Row(
                children: [
                  Text("Lampi ID: " + lampiId)
                ],
              ),
              Container(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 80, horizontal: 20),
                ),
                width: double.infinity,
                height: MediaQuery.of(context).size.height / 3.5,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                  color: on ? brightnessColor : Colors.black,
                ),
              ),
              colorSlider(
                  colors: _colors,
                  sliderPos: _hueSliderPosition,
                  maxWidth: 360.0,
                  handle: (position) {
                    setState(() {
                      _hueSliderPosition = position;
                      currentColor =
                          calculateSelectedColor(_colors, position, 360.0);
                      shadedColor = calculateSelectedColor(
                          [Colors.white, currentColor],
                          _saturationSliderPosition,
                          360.0);
                      brightnessColor = calculateSelectedColor(
                          [Colors.black, shadedColor],
                          _brightnessSliderPosition,
                          360.0);
                    });
                  },
                  currentColor: brightnessColor),
              colorSlider(
                  colors: [Colors.white, currentColor],
                  sliderPos: _saturationSliderPosition,
                  maxWidth: 360.0,
                  handle: (position) {
                    setState(() {
                      _saturationSliderPosition = position;
                      shadedColor = calculateSelectedColor(
                          [Colors.white, currentColor], position, 360.0);
                      brightnessColor = calculateSelectedColor(
                          [Colors.black, shadedColor],
                          _brightnessSliderPosition,
                          360.0);
                    });
                  },
                  currentColor: brightnessColor),
              colorSlider(
                  colors: [Colors.black, Colors.white],
                  sliderPos: _brightnessSliderPosition,
                  maxWidth: 360.0,
                  handle: (position) {
                    setState(() {
                      _brightnessSliderPosition = position;
                      brightnessColor = calculateSelectedColor(
                          [Colors.black, shadedColor], position, 360.0);
                    });
                  },
                  currentColor: brightnessColor),
              Row(
                children: <Widget>[
                  IconButton(
                    icon: Icon(Icons.settings),
                    iconSize: 40,
                    onPressed: () {
                      showMyDialog(context, textController, (){
                        setState(() {
                          lampiId = textController.text;
                        });
                      });
                    },
                  ),
                  Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: 5,
                          horizontal: MediaQuery.of(context).size.width / 4),
                      child: IconButton(
                        icon: Icon(Icons.power_settings_new),
                        color: on ? brightnessColor : Colors.black,
                        iconSize: 60,
                        onPressed: () {
                          setState(() {
                            on = !on;
                          });
                        },
                      )),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
