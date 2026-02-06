import 'package:flutter/material.dart';

class TempConverter extends StatefulWidget {
  @override
  State<TempConverter> createState() => _TempConverterState();
}

class _TempConverterState extends State<TempConverter> {
  var cController = TextEditingController();
  var fController = TextEditingController();
  var kController = TextEditingController();

  bool isTyping = false; // 👈 to prevent infinite loops

  @override
  void initState() {
    super.initState();

    // Celsius listener
    cController.addListener(() {
      if (isTyping) return;
      if (cController.text.isEmpty) {
        _clearOthers();
        return;
      }
      isTyping = true;
      double? c = double.tryParse(cController.text);
      if (c != null) {
        fController.text = (c * 9 / 5 + 32).toStringAsFixed(2);
        kController.text = (c + 273.15).toStringAsFixed(2);
      }
      isTyping = false;
    });

    // Fahrenheit listener
    fController.addListener(() {
      if (isTyping) return;
      if (fController.text.isEmpty) {
        _clearOthers();
        return;
      }
      isTyping = true;
      double? f = double.tryParse(fController.text);
      if (f != null) {
        double c = (f - 32) * 5 / 9;
        cController.text = c.toStringAsFixed(2);
        kController.text = (c + 273.15).toStringAsFixed(2);
      }
      isTyping = false;
    });

    // Kelvin listener
    kController.addListener(() {
      if (isTyping) return;
      if (kController.text.isEmpty) {
        _clearOthers();
        return;
      }
      isTyping = true;
      double? k = double.tryParse(kController.text);
      if (k != null) {
        double c = k - 273.15;
        cController.text = c.toStringAsFixed(2);
        fController.text = (c * 9 / 5 + 32).toStringAsFixed(2);
      }
      isTyping = false;
    });
  }

  void _clearOthers() {
    if (!isTyping) {
      isTyping = true;
      cController.clear();
      fController.clear();
      kController.clear();
      isTyping = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Temperature Converter'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey.shade200,
        child: Center(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(21),
            ),
            child: Container(
              width: 320,
              height: 420,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(21),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Live Temperature Converter',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: cController,
                    decoration: InputDecoration(
                      label: Text('Celsius (°C)'),
                      hintText: 'e.g., 25',
                      prefixIcon: Icon(Icons.thermostat),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: fController,
                    decoration: InputDecoration(
                      label: Text('Fahrenheit (°F)'),
                      hintText: 'e.g., 77',
                      prefixIcon: Icon(Icons.device_thermostat),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: kController,
                    decoration: InputDecoration(
                      label: Text('Kelvin (K)'),
                      hintText: 'e.g., 298',
                      prefixIcon: Icon(Icons.ac_unit),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _clearOthers,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Reset',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
