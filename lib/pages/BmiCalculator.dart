import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BmiCalculator extends StatefulWidget {
  @override
  State<BmiCalculator> createState() => _BmiCalculatorState();
}

class _BmiCalculatorState extends State<BmiCalculator> {
  var wtController = TextEditingController();
  var ftController = TextEditingController();
  var inController = TextEditingController();
  var result = "";
  var bgColor = Colors.orange.shade100;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BMI Calculator'),
      ),
      body: Container(
        color: bgColor,
        child: Center(
          child: Container(
            width: 300,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'BMI',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 21),
                TextField(
                  controller: wtController,
                  decoration: InputDecoration(
                    label: Text('Enter your weight (in Kgs.)'),
                    prefixIcon: Icon(Icons.line_weight),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 11),
                TextField(
                  controller: ftController,
                  decoration: InputDecoration(
                    label: Text('Enter your height (in Foot.)'),
                    prefixIcon: Icon(Icons.height),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 11),
                TextField(
                  controller: inController,
                  decoration: InputDecoration(
                    label: Text('Enter your height (in Inches.)'),
                    prefixIcon: Icon(Icons.height),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        var wt = wtController.text.toString();
                        var ft = ftController.text.toString();
                        var inch = inController.text.toString();
                        if (wt != "" && ft != "" && inch != "") {
                          var iWt = double.parse(wt);
                          var iFt = double.parse(ft);
                          var iInch = double.parse(inch);
                          var tInch = (iFt * 12) + iInch;
                          var tCm = tInch * 2.54;
                          var tM = tCm / 100;
                          var bmi = iWt / (tM * tM);
                          var msg = "";

                          if (bmi > 25) {
                            msg = "You're Overweight!!!";
                            bgColor = Colors.red.shade200;
                          } else if (bmi < 18) {
                            msg = "You're Underweight!!!";
                            bgColor = Colors.yellow.shade200;
                          } else {
                            msg = "You're Healthy!!!";
                            bgColor = Colors.green.shade200;
                          }

                          setState(() {
                            result = '$msg \nYour BMI is : ${bmi.toStringAsFixed(2)}';
                          });
                        } else {
                          setState(() {
                            result = 'Please fill all the required blanks!!!';
                          });
                        }
                      },
                      child: Text('Calculate'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade400,
                      ),
                      onPressed: () {
                        setState(() {
                          wtController.clear();
                          ftController.clear();
                          inController.clear();
                          result = "";
                          bgColor = Colors.orange.shade100;
                        });
                      },
                      child: Text('Reset'),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Text(
                  result,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
