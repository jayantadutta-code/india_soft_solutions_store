import 'package:flutter/material.dart';



class BmiCalculatorPro extends StatefulWidget {
  const BmiCalculatorPro({super.key});

  @override
  State<BmiCalculatorPro> createState() => _BmiCalculatorProState();
}

class _BmiCalculatorProState extends State<BmiCalculatorPro> {
  final weightController = TextEditingController();
  final heightControllerFoot = TextEditingController();
  final heightControllerInch = TextEditingController();

  double bmi = 0.0;
  bool _hasAllInputs = false;

  @override
  void initState() {
    super.initState();
    weightController.addListener(_calculateBmiLive);
    heightControllerFoot.addListener(_calculateBmiLive);
    heightControllerInch.addListener(_calculateBmiLive);

    // Listen for input completion
    weightController.addListener(_checkInputs);
    heightControllerFoot.addListener(_checkInputs);
    heightControllerInch.addListener(_checkInputs);
  }

  @override
  void dispose() {
    weightController.dispose();
    heightControllerFoot.dispose();
    heightControllerInch.dispose();
    super.dispose();
  }

  void _checkInputs() {
    final hasAllFields = weightController.text.isNotEmpty &&
        heightControllerFoot.text.isNotEmpty &&
        heightControllerInch.text.isNotEmpty;

    if (_hasAllInputs != hasAllFields) {
      setState(() {
        _hasAllInputs = hasAllFields;
      });
    }
  }

  void _calculateBmiLive() {
    if (weightController.text.isEmpty ||
        heightControllerFoot.text.isEmpty ||
        heightControllerInch.text.isEmpty) {
      setState(() {
        _hasAllInputs = false;
      });
      return;
    }

    final weight = double.tryParse(weightController.text);
    final heightFoot = double.tryParse(heightControllerFoot.text);
    final heightInch = double.tryParse(heightControllerInch.text);

    if (weight == null || heightFoot == null || heightInch == null) {
      setState(() {
        _hasAllInputs = false;
      });
      return;
    }

    setState(() {
      _hasAllInputs = true;
    });

    final heightInMeters = ((heightFoot * 12) + heightInch) * 0.0254;
    final result = weight / (heightInMeters * heightInMeters);

    setState(() {
      bmi = result;
    });
  }

  void _reset() {
    setState(() {
      weightController.clear();
      heightControllerFoot.clear();
      heightControllerInch.clear();
      bmi = 0.0;
      _hasAllInputs = false;
    });
    // Remove focus from text fields
    FocusScope.of(context).unfocus();
  }

  String getBmiStatus(double bmi) {
    if (bmi < 18.5) return "Underweight";
    if (bmi < 25) return "Normal";
    if (bmi < 30) return "Overweight";
    return "Obese";
  }

  String getBmiRecommendation(double bmi) {
    if (bmi < 18.5) return "Consider gaining weight through a balanced diet";
    if (bmi < 25) return "Maintain your healthy lifestyle!";
    if (bmi < 30) return "Consider moderate exercise and diet adjustment";
    return "Consult a healthcare professional for guidance";
  }

  Color getBmiColor(double bmi) {
    if (bmi < 18.5) return Colors.orange;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  Color getBmiBackgroundColor(double bmi) {
    if (bmi == 0) return Colors.grey.shade100;
    if (bmi < 18.5) return Colors.orange.shade50;
    if (bmi < 25) return Colors.green.shade50;
    if (bmi < 30) return Colors.orange.shade50;
    return Colors.red.shade50;
  }

  IconData getBmiIcon(double bmi) {
    if (bmi < 18.5) return Icons.arrow_downward;
    if (bmi < 25) return Icons.check_circle;
    if (bmi < 30) return Icons.warning;
    return Icons.error;
  }

  @override
  Widget build(BuildContext context) {
    final bool showResult = bmi > 0 && _hasAllInputs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BMI Calculator'),
        actions: [
          if (_hasAllInputs)
            IconButton(
              onPressed: _reset,
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset',
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.pinkAccent.withOpacity(0.1),
              Colors.cyanAccent.withOpacity(0.1),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.pinkAccent.withOpacity(0.2),
                          Colors.cyanAccent.withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.fitness_center,
                          size: 64,
                          color: Colors.pinkAccent,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'BMI Calculator',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.pinkAccent,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter your details • See results instantly',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Input Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Weight Input
                        TextField(
                          controller: weightController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Weight',
                            hintText: 'Enter weight in kg',
                            prefixIcon: const Icon(Icons.monitor_weight),
                            suffixText: 'kg',
                            suffixStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.pinkAccent,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Height Inputs
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: heightControllerFoot,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Feet',
                                  hintText: 'ft',
                                  prefixIcon: const Icon(Icons.height),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: heightControllerInch,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Inches',
                                  hintText: 'in',
                                  suffixText: 'in',
                                  suffixStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.pinkAccent,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Real-time calculation hint
                        if (!showResult && (_hasAllInputs || bmi == 0))
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.lightbulb,
                                  color: Colors.amber.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Results appear automatically',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // BMI Result Card (appears automatically)
                if (showResult)
                  Column(
                    children: [
                      const SizedBox(height: 32),
                      ScaleTransition(
                        scale: Tween<double>(begin: 0.9, end: 1).animate(
                          CurvedAnimation(
                            parent: ModalRoute.of(context)!.animation!,
                            curve: Curves.easeInOutBack,
                          ),
                        ),
                        child: Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          color: getBmiBackgroundColor(bmi),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      getBmiIcon(bmi),
                                      size: 32,
                                      color: getBmiColor(bmi),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'YOUR BMI RESULT',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: getBmiColor(bmi),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  bmi.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 64,
                                    fontWeight: FontWeight.bold,
                                    color: getBmiColor(bmi),
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  getBmiStatus(bmi),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    color: getBmiColor(bmi),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                LinearProgressIndicator(
                                  value: bmi / 40,
                                  minHeight: 12,
                                  borderRadius: BorderRadius.circular(6),
                                  backgroundColor: Colors.grey.shade300,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    getBmiColor(bmi),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '<18.5',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '18.5-25',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '25-30',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '>30',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: getBmiColor(bmi).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: getBmiColor(bmi).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.lightbulb_outline,
                                        color: getBmiColor(bmi),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          getBmiRecommendation(bmi),
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 32),

                // Reset Button (centered)
                if (_hasAllInputs)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _reset,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        foregroundColor: Colors.grey.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Clear All',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Info Section (always visible)
                const SizedBox(height: 32),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info,
                              color: Colors.pinkAccent,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'BMI Categories',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildBmiCategoryRow('Underweight', '< 18.5', Colors.orange),
                        _buildBmiCategoryRow('Normal', '18.5 - 24.9', Colors.green),
                        _buildBmiCategoryRow('Overweight', '25 - 29.9', Colors.orange),
                        _buildBmiCategoryRow('Obese', '≥ 30', Colors.red),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBmiCategoryRow(String label, String range, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            range,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}