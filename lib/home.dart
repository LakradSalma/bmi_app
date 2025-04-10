import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import 'history_page.dart';
import 'welcome_page.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController controlWeight = TextEditingController();
  final TextEditingController controlHeight = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _info = "Report your data";
  double _bmi = 0.0;
  Color _gaugeColor = Colors.grey;
  bool _isCalculating = false;

  void _resetFields() {
    controlHeight.text = "";
    controlWeight.text = "";
    setState(() {
      _info = "Report your data";
      _bmi = 0.0;
      _gaugeColor = Colors.grey;
      _isCalculating = false;
    });
  }

  Future<void> _saveToFirebase(double bmiValue) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('bmi_data').add({
        'email': user.email,
        'bmi': bmiValue,
        'timestamp': Timestamp.now(),
      });
    }
  }

  void _calculate() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isCalculating = true;
      });

      Future.delayed(Duration(seconds: 2), () {
        setState(() {
          double weight = double.parse(controlWeight.text);
          double height = double.parse(controlHeight.text) / 100;
          _bmi = weight / (height * height);

          if (_bmi < 18.6) {
            _info = "Below the weight (${_bmi.toStringAsPrecision(4)})";
            _gaugeColor = Colors.blue;
          } else if (_bmi >= 18.6 && _bmi < 24.9) {
            _info = "Ideal Weight (${_bmi.toStringAsPrecision(4)})";
            _gaugeColor = Colors.green;
          } else if (_bmi >= 24.9 && _bmi < 29.9) {
            _info = "Slightly Overweight (${_bmi.toStringAsPrecision(4)})";
            _gaugeColor = Colors.orange;
          } else if (_bmi >= 29.9 && _bmi < 34.9) {
            _info = "Obesity Grade I (${_bmi.toStringAsPrecision(4)})";
            _gaugeColor = Colors.red;
          } else if (_bmi >= 34.9 && _bmi < 39.9) {
            _info = "Obesity Grade II (${_bmi.toStringAsPrecision(4)})";
            _gaugeColor = Colors.red.shade700;
          } else {
            _info = "Obesity Grade III (${_bmi.toStringAsPrecision(4)})";
            _gaugeColor = Colors.red.shade900;
          }

          _saveToFirebase(_bmi); // save result
          _isCalculating = false;
        });
      });
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("BMI CALCULATOR"),
        centerTitle: true,
        backgroundColor: Colors.green,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _resetFields),
          IconButton(icon: const Icon(Icons.history), onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage()));
          }),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.person, size: 100.0, color: Colors.green),
              TextFormField(
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "Weight (Kg)",
                  labelStyle: TextStyle(color: Colors.green),
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.green, fontSize: 22.0),
                controller: controlWeight,
                validator: (value) => value == null || value.isEmpty ? "Insert your weight!" : null,
              ),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Height (cm)",
                  labelStyle: TextStyle(color: Colors.green),
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.green, fontSize: 22.0),
                controller: controlHeight,
                validator: (value) => value == null || value.isEmpty ? "Insert your height!" : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _calculate,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("Calculate", style: TextStyle(color: Colors.white, fontSize: 22)),
              ),
              const SizedBox(height: 20),
              _isCalculating
                  ? const Center(child: CircularProgressIndicator())
                  : Text(_info, textAlign: TextAlign.center, style: const TextStyle(color: Colors.green, fontSize: 22.0)),
              const SizedBox(height: 20),
              _bmi > 0
                  ? SfRadialGauge(
                      axes: <RadialAxis>[
                        RadialAxis(
                          minimum: 10,
                          maximum: 40,
                          ranges: <GaugeRange>[
                            GaugeRange(startValue: 10, endValue: 18.5, color: Colors.blue),
                            GaugeRange(startValue: 18.5, endValue: 24.9, color: Colors.green),
                            GaugeRange(startValue: 24.9, endValue: 29.9, color: Colors.orange),
                            GaugeRange(startValue: 29.9, endValue: 40, color: Colors.red),
                          ],
                          pointers: <GaugePointer>[
                            NeedlePointer(value: _bmi, enableAnimation: true, needleColor: _gaugeColor, knobStyle: KnobStyle(color: _gaugeColor)),
                          ],
                          annotations: <GaugeAnnotation>[
                            GaugeAnnotation(
                              widget: Text(_bmi > 0 ? _bmi.toStringAsFixed(1) : "", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              angle: 90,
                              positionFactor: 0.5,
                            ),
                          ],
                        ),
                      ],
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }
}
