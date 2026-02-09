import 'package:flutter/material.dart';
import 'package:iss_app/pages/AgeCalculator.dart';
import 'package:iss_app/pages/BirthdayCountdown.dart';
import 'package:iss_app/pages/BmiCalculator.dart';
import 'package:iss_app/pages/EventCountdown.dart';
import 'package:iss_app/pages/FullAnimation.dart';
import 'package:iss_app/pages/NextLevelAnimation.dart';
import 'package:iss_app/pages/TempConverter.dart';
import 'package:iss_app/pages/TestDBScreen.dart';
import 'package:iss_app/pages/WorkProgressTracker.dart';
import 'package:iss_app/pages/BmiCalculatorPro.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reorderables/reorderables.dart';
import 'models/grid_item.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double boxSize = 150;
  List<GridItem> items = [];

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  void loadItems() async {
    items = [
      GridItem(title: "BMI Calculator", image: "assets/images/img0.png", page: BmiCalculator(),),
      GridItem(title: "Temperature Convertor", image: "assets/images/img1.png", page: TempConverter(),),
      GridItem(title: "Splash 1", image: "assets/images/img2.png", page: NextLevelAnimation(),),
      GridItem(title: "Splash 2", image: "assets/images/img3.png", page: FullAnimation(),),
      GridItem(title: "Notes", image: "assets/images/notes.png", page: TestDBScreen(),),
      GridItem(title: "Work Progress Tracker", image: "assets/images/wPT.png", page: WorkProgressTracker(),),
      GridItem(title: "Event Countdown", image: "assets/images/eventCountdown.png", page: EventCountdown(),),
      GridItem(title: "Age Claculator", image: "assets/images/ageCalculator.png", page: AgeCalculator(),),
      GridItem(title: "Bithday Countdown", image: "assets/images/BirthDayCounter.png", page: BirthdayCountdown(),),
      GridItem(title: "BMI Calculator Pro", image: "assets/images/bmi_cal_pro.png", page: BmiCalculatorPro(),),

      // Add all 16 items here
    ];

    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String>? order = prefs.getStringList("gridOrder");

    if (order != null) {
      List<GridItem> newOrder = [];
      for (var t in order) {
        newOrder.add(items.firstWhere((e) => e.title == t));
      }
      setState(() => items = newOrder);
    } else {
      setState(() {});
    }
  }

  void saveOrder() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList("gridOrder", items.map((e) => e.title).toList());
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> tiles = items.map((item) {
      return GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => item.page));
        },
        child: Container(
          width: boxSize,
          height: boxSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: AssetImage(item.image),
              fit: BoxFit.cover,
            ),
          ),
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(8),
            color: Colors.black54,
            child: Text(
              item.title,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text("Dashboard")),

      body: Column(
        children: [
          Slider(
            value: boxSize,
            min: 80,
            max: 200,
            label: "Size",
            onChanged: (v) => setState(() => boxSize = v),
          ),

          Expanded(
            child: ReorderableWrap(
              spacing: 12,
              runSpacing: 12,
              children: tiles,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  final item = items.removeAt(oldIndex);
                  items.insert(newIndex, item);
                  saveOrder();
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
