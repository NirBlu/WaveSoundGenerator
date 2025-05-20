import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sound_generator/sound_generator.dart';
import 'package:sound_generator/waveTypes.dart';

class SineWaveScreen extends StatefulWidget {
  const SineWaveScreen({Key? key}) : super(key: key);

  @override
  _SineWaveScreenState createState() => _SineWaveScreenState();
}

class MyPainter extends CustomPainter {
  final List<int> oneCycleData;

  MyPainter(this.oneCycleData);

  @override
  void paint(Canvas canvas, Size size) {
    var i = 0;
    List<Offset> maxPoints = [];

    final t = size.width / (oneCycleData.length - 1);
    for (var i0 = 0, len = oneCycleData.length; i0 < len; i0++) {
      maxPoints.add(Offset(
          t * i,
          size.height / 2 -
              oneCycleData[i0].toDouble() / 32767.0 * size.height / 2));
      i++;
    }

    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    canvas.drawPoints(PointMode.polygon, maxPoints, paint);
  }

  @override
  bool shouldRepaint(MyPainter oldDelegate) {
    return oneCycleData != oldDelegate.oneCycleData;
  }
}

class _SineWaveScreenState extends State<SineWaveScreen> {
  bool isPlaying = false;
  double frequency = 440; // Default frequency
  double balance = 0;
  double volume = 1;
  waveTypes waveType = waveTypes.SINUSOIDAL; // Default waveform
  int sampleRate = 96000;
  List<int>? oneCycleData;
  TextEditingController _frequencyController =
      TextEditingController(); // Text controller for frequency input

  Timer? _timer; // Timer for continuous frequency change
  int _timerInterval = 100; // Initial timer interval
  int _accelerationStep = 5; // How fast the interval decreases (acceleration)

  @override
  void initState() {
    super.initState();
    isPlaying = false;

    SoundGenerator.init(sampleRate);

    SoundGenerator.onIsPlayingChanged.listen((value) {
      setState(() {
        isPlaying = value;
      });
    });

    SoundGenerator.onOneCycleDataHandler.listen((value) {
      setState(() {
        oneCycleData = value;
      });
    });

    SoundGenerator.setAutoUpdateOneCycleSample(true);
    SoundGenerator.refreshOneCycleData();
    SoundGenerator.setFrequency(frequency);
    _frequencyController.text = frequency
        .toStringAsFixed(1); // Initialize text field with default frequency
  }

  void _startIncreasing() {
    _timer?.cancel(); // Cancel any previous timer
    _timerInterval = 100; // Reset the interval to its initial value

    _timer = Timer.periodic(Duration(milliseconds: _timerInterval), (timer) {
      setState(() {
        frequency = (frequency + 0.1).clamp(20.0, 10000.0); // Limit range
        SoundGenerator.setFrequency(frequency);
        _frequencyController.text =
            frequency.toStringAsFixed(1); // Update text field

        // Decrease the interval progressively to speed up the increase
        _timerInterval = (_timerInterval - _accelerationStep).clamp(20, 100);
        timer.cancel();
        _startIncreasing(); // Restart the timer with the new interval
      });
    });
  }

  void _startDecreasing() {
    _timer?.cancel();
    _timerInterval = 100;

    _timer = Timer.periodic(Duration(milliseconds: _timerInterval), (timer) {
      setState(() {
        frequency = (frequency - 0.1).clamp(20.0, 10000.0); // Limit range
        SoundGenerator.setFrequency(frequency);
        _frequencyController.text =
            frequency.toStringAsFixed(1); // Update text field

        // Decrease the interval progressively to speed up the decrease
        _timerInterval = (_timerInterval - _accelerationStep).clamp(20, 100);
        timer.cancel();
        _startDecreasing(); // Restart the timer with the new interval
      });
    });
  }

  void _stopChanging() {
    _timer?.cancel(); // Stop the timer when the button is released
  }

  void _setFrequencyFromInput(String input) {
    double? newFrequency = double.tryParse(input);
    if (newFrequency != null && newFrequency >= 20 && newFrequency <= 10000) {
      setState(() {
        frequency = newFrequency;
        SoundGenerator.setFrequency(frequency);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sound Generator for Cymatics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text("Waveform Visualization"),
            const SizedBox(height: 2),
            Container(
              height: 100,
              width: double.infinity,
              color: Colors.white54,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: oneCycleData != null
                  ? CustomPaint(
                      painter: MyPainter(oneCycleData!),
                    )
                  : Container(),
            ),
            const SizedBox(height: 2),
            Text(
                "Cycle Data Length: ${(sampleRate / frequency).round()} samples at sample rate $sampleRate"),
            const SizedBox(height: 10),
            const Divider(
              color: Colors.red,
            ),
            const SizedBox(height: 10),
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.lightBlueAccent,
              child: IconButton(
                icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
                onPressed: () {
                  setState(() {
                    if (isPlaying) {
                      SoundGenerator.stop();
                    } else {
                      SoundGenerator.play();
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: 10),
            const Divider(
              color: Colors.red,
            ),
            const SizedBox(height: 10),
            const Text("Wave Type"),
            Center(
              child: DropdownButton<waveTypes>(
                value: waveType,
                onChanged: (waveTypes? newValue) {
                  setState(() {
                    waveType = newValue!;
                    SoundGenerator.setWaveType(waveType);
                  });
                },
                items: waveTypes.values.map((waveTypes classType) {
                  return DropdownMenuItem<waveTypes>(
                    value: classType,
                    child: Text(classType.toString().split('.').last),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            const Divider(
              color: Colors.red,
            ),
            const SizedBox(height: 10),
            const Text("Frequency"),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTapDown: (_) => _startDecreasing(),
                  onTapUp: (_) => _stopChanging(),
                  onTapCancel: _stopChanging,
                  child: const Icon(Icons.remove),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('${frequency.toStringAsFixed(1)} Hz'),
                ),
                GestureDetector(
                  onTapDown: (_) => _startIncreasing(),
                  onTapUp: (_) => _stopChanging(),
                  onTapCancel: _stopChanging,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            Slider(
              min: 20,
              max: 10000,
              value: frequency,
              onChanged: (value) {
                setState(() {
                  frequency = value.toDouble();
                  SoundGenerator.setFrequency(frequency);
                  _frequencyController.text = frequency.toStringAsFixed(1);
                });
              },
            ),
            const SizedBox(height: 10),
            const Text("Enter Exact Frequency"),
            TextField(
              controller: _frequencyController,
              keyboardType: TextInputType.number,
              onSubmitted: _setFrequencyFromInput,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter frequency (20 to 10000 Hz)',
              ),
            ),
            const SizedBox(height: 10),
            const Text("Balance"),
            Slider(
              min: -1,
              max: 1,
              value: balance,
              onChanged: (value) {
                setState(() {
                  balance = value.toDouble();
                  SoundGenerator.setBalance(balance);
                });
              },
            ),
            const SizedBox(height: 10),
            const Text("Volume"),
            Slider(
              min: 0,
              max: 1,
              value: volume,
              onChanged: (value) {
                setState(() {
                  volume = value.toDouble();
                  SoundGenerator.setVolume(volume);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the screen is disposed
    SoundGenerator.release();
    _frequencyController.dispose(); // Dispose of the controller
    super.dispose();
  }
}
