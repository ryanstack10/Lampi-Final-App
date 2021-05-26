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

  double _hueSliderPosition = 360.0;
  double _saturationSliderPosition = 360.0;
  double _brightnessSliderPosition = 360.0;
  static const uuid_hsv = "0002a7d3-d8a4-4fea-8174-1736e808c066";
  static const uuid_brightness = "0003a7d3-d8a4-4fea-8174-1736e808c066";
  static const uuid_onoff = "0004a7d3-d8a4-4fea-8174-1736e808c066";
  BluetoothCharacteristic c_hsv;
  BluetoothCharacteristic c_brightness;
  BluetoothCharacteristic c_onoff;
  double width;
  var lampiList = [];
  List<String> lampiNameList = [];

  bool on = true;

  bool _visible = false;

  bool lampiConnected = false;

  bool slidingInUse = false;

  String currentLampi;

  String dropdownHint = "Choose a Lampi to Connect";

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
    int index = positionInColorArray.truncate();
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

  Color currentColor = Color(0x808080);
  Color shadedColor = Color(0x808080);
  Color brightnessColor = Color(0x808080);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => startColor(context));
  }

  @override
  bool equalsIgnoreCase(String string1, String string2) {
    return string1?.toLowerCase() == string2?.toLowerCase();
  }

  void dispose() {
    textController.dispose();
    super.dispose();
  }

  writeHSV(v1, v2) async {
    await c_hsv.write([v1.toInt(), v2.toInt(), 255]);
    return new Future.delayed(const Duration(milliseconds: 20), () => false);
  }

  writeBRIGHTNESS(v1) async {
    await c_brightness.write([v1.toInt()]);
    return new Future.delayed(const Duration(milliseconds: 20), () => false);
  }

  writeONOFF(v1) async {
    await c_onoff.write([v1.toInt()]);
    return new Future.delayed(const Duration(milliseconds: 20), () => false);
  }

  void sendHSV() async {
    if (!slidingInUse) {
      slidingInUse = true;

      var v1 = _hueSliderPosition * 255.0 / width;
      var v2 = _saturationSliderPosition * 255.0 / width;
      slidingInUse = await writeHSV(v1, v2);
    }
  }

  void sendBrightness() async {
    if (!slidingInUse) {
      slidingInUse = true;
      var v1 = _brightnessSliderPosition * 255.0 / width;
      slidingInUse = await writeBRIGHTNESS(v1);
    }
  }

  void scan() async {
    // Start scanning
    flutterBlue.startScan(timeout: Duration(seconds: 4));
    lampiId = "Searching........";
    // Listen to results
    var subscription = flutterBlue.scanResults.listen((results) {
      // do something with scan results
      for (ScanResult r in results) {
        //  print("name");
        //  print(r.device.name);
        if (r.device.name.length > 4 &&
            equalsIgnoreCase(r.device.name.substring(0, 5), "LAMPI")) {
          if (!lampiList.contains(r.device)) {
            setState(() {
              lampiList.add(r.device);
              lampiNameList.add(r.device.name as String);
            });
          }
          var target = r.device;
          lampiId = r.device.name;
        }
      }
    });
  }

  void startColor(context) async {
    width = MediaQuery.of(context).size.width * .9;
    _hueSliderPosition = width;
    _saturationSliderPosition = width;
    _brightnessSliderPosition = width;
    await Future.delayed(Duration(milliseconds: 1), () {
      setState(() {
        flutterBlue = FlutterBlue.instance;
        _hueSliderPosition = 0;
        currentColor = calculateSelectedColor(_colors, 0, width);
        shadedColor = calculateSelectedColor(
            [Colors.white, currentColor], _saturationSliderPosition, width);
        brightnessColor = calculateSelectedColor(
            [Colors.black, shadedColor], _brightnessSliderPosition, width);

        //initial scan
        scan();
      });
    });
  }

  setAppHSV(value) {
    if (value.length > 2) {
      setState(() {
        _hueSliderPosition = width / 255.0 * value[0];
        _saturationSliderPosition = width / 255.0 * value[1];

        currentColor =
            calculateSelectedColor(_colors, _hueSliderPosition, width);
        shadedColor = calculateSelectedColor(
            [Colors.white, currentColor], _saturationSliderPosition, width);
        brightnessColor = calculateSelectedColor(
            [Colors.black, shadedColor], _brightnessSliderPosition, width);
      });
    }
  }

  setAppBrightness(value) {
    if (value.length > 0) {
      setState(() {
        _brightnessSliderPosition = width / 255.0 * value[0];

        brightnessColor = calculateSelectedColor(
            [Colors.black, shadedColor], _brightnessSliderPosition, width);
      });
    }
  }

  setAppOnOff(value) {
    if (value.length > 0) {
      setState(() {
        if (value[0] == 0) {
          on = false;
        } else {
          on = true;
        }
      });
    }
  }

  disconnectTarget(BluetoothDevice target) async {
    await target.disconnect();
  }

  connectTarget(BluetoothDevice target) async {
    print("Connecting");
    //connect to chosen device
    await target.connect();
    //interrogate services to capture characteristic information for all the
    //characteristics we need by uuid
    //interrogate lampi initial values for app - do that once only
    List<BluetoothService> services = await target.discoverServices();
    for (BluetoothService service in services) {
      var characteristics = service.characteristics;
      for (BluetoothCharacteristic characteristic in characteristics) {
        var uuid = characteristic.uuid.toString();
        switch (uuid) {
          case uuid_hsv:
            {
              c_hsv = characteristic;
              //interrogate upon first connection
              List<int> initialCharacteristic = await characteristic.read();
              setAppHSV(initialCharacteristic);
              //setup listener for HSV characteristic
              await characteristic.setNotifyValue(true);
              characteristic.value.listen((value) {
                setAppHSV(value);
              });
            }
            break;
          case uuid_brightness:
            {
              c_brightness = characteristic;
              //interrogate initial value
              List<int> initialCharacteristic = await characteristic.read();
              setAppBrightness(initialCharacteristic);
              //setup brightness listener
              await characteristic.setNotifyValue(true);
              characteristic.value.listen((value) {
                setAppBrightness(value);
              });
            }
            break;
          case uuid_onoff:
            {
              c_onoff = characteristic;
              //interrogate initial value
              List<int> initialCharacteristic = await characteristic.read();
              setAppOnOff(initialCharacteristic);
              //setup listener
              await characteristic.setNotifyValue(true);
              characteristic.value.listen((value) {
                setAppOnOff(value);
              });
            }
            break;
          default:
            {}
            break;
        }
      }
    }

    print("Completed Connection");
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
                  !lampiConnected
                      ? new DropdownButton<String>(
                          items: lampiNameList
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          hint: Text(dropdownHint),
                          onChanged: (value) {
                            setState(() {
                              if (!lampiConnected) {
                                //if there are no lampis from the prior scan,
                                //scan again
                                if (lampiList.length < 1) {
                                  scan();
                                }
                                flutterBlue.stopScan();
                                for (BluetoothDevice device in lampiList) {
                                  if (device.name == value) {
                                    slidingInUse = false;
                                    currentLampi = device.name;
                                    connectTarget(device);
                                    slidingInUse = false;
                                    lampiConnected = true;
                                    dropdownHint = "Choose Lampi to Disconnect";
                                  }
                                }
                              } else {
                                //kill subscription

                                for (BluetoothDevice device in lampiList) {
                                  if (device.name == value) {
                                    disconnectTarget(device);

                                    slidingInUse = false;
                                    lampiList = [];
                                    lampiNameList = [];
                                    lampiConnected = false;
                                    dropdownHint = "Choose Lampi to Connect";
                                  }
                                }

                                scan();
                              }
                            });
                          },
                        )
                      : ElevatedButton(
                          child: Text("Disconnect"),
                          onPressed: () {
                            for (BluetoothDevice device in lampiList) {
                              if (device.name == currentLampi) {
                                disconnectTarget(device);

                                slidingInUse = false;
                                lampiList = [];
                                lampiNameList = [];
                                lampiConnected = false;
                                dropdownHint = "Choose Lampi to Connect";
                              }
                            }

                            scan();
                          },
                        )
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
                  maxWidth: width,
                  handle: (position) {
                    setState(() {
                      _hueSliderPosition = position;
                      if (lampiConnected) {
                        sendHSV();
                      }
                      currentColor =
                          calculateSelectedColor(_colors, position, width);
                      shadedColor = calculateSelectedColor(
                          [Colors.white, currentColor],
                          _saturationSliderPosition,
                          width);
                      brightnessColor = calculateSelectedColor(
                          [Colors.black, shadedColor],
                          _brightnessSliderPosition,
                          width);
                    });
                  },
                  currentColor: brightnessColor),
              colorSlider(
                  colors: [Colors.white, currentColor],
                  sliderPos: _saturationSliderPosition,
                  maxWidth: width,
                  handle: (position) {
                    setState(() {
                      _saturationSliderPosition = position;
                      if (lampiConnected) {
                        sendHSV();
                      }
                      shadedColor = calculateSelectedColor(
                          [Colors.white, currentColor], position, width);
                      brightnessColor = calculateSelectedColor(
                          [Colors.black, shadedColor],
                          _brightnessSliderPosition,
                          width);
                    });
                  },
                  currentColor: brightnessColor),
              colorSlider(
                  colors: [Colors.black, Colors.white],
                  sliderPos: _brightnessSliderPosition,
                  maxWidth: width,
                  handle: (position) {
                    setState(() {
                      _brightnessSliderPosition = position;
                      if (lampiConnected) {
                        sendBrightness();
                      }
                      brightnessColor = calculateSelectedColor(
                          [Colors.black, shadedColor], position, width);
                    });
                  },
                  currentColor: brightnessColor),
              Row(
                children: <Widget>[
                  IconButton(
                    icon: Icon(Icons.settings),
                    iconSize: 40,
                    onPressed: () {
                      showMyDialog(context, textController, () {
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
                            if (lampiConnected) {
                              on = !on;
                              if (on) {
                                writeONOFF(1);
                              } else
                                writeONOFF(0);
                            }
                            {}
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
