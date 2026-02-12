import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';



// ==================== DATABASE HELPER ====================
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String dbPath = path.join(await getDatabasesPath(), 'health_tracker.db');
    return await openDatabase(dbPath, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        dob TEXT NOT NULL,
        sex TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE glucose_readings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        value REAL NOT NULL,
        reading_time TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE bp_readings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        systolic INTEGER NOT NULL,
        diastolic INTEGER NOT NULL,
        reading_time TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }
}

// ==================== MODELS ====================
class User {
  int? id;
  String name;
  DateTime dob;
  String sex;
  String phone;
  String address;
  DateTime createdAt;

  User({
    this.id,
    required this.name,
    required this.dob,
    required this.sex,
    required this.phone,
    required this.address,
    required this.createdAt,
  });

  int get age {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dob': dob.toIso8601String(),
      'sex': sex,
      'phone': phone,
      'address': address,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static User fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      dob: DateTime.parse(map['dob']),
      sex: map['sex'],
      phone: map['phone'],
      address: map['address'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class GlucoseReading {
  int? id;
  int userId;
  double value;
  DateTime readingTime;

  GlucoseReading({
    this.id,
    required this.userId,
    required this.value,
    required this.readingTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'value': value,
      'reading_time': readingTime.toIso8601String(),
    };
  }

  static GlucoseReading fromMap(Map<String, dynamic> map) {
    return GlucoseReading(
      id: map['id'],
      userId: map['user_id'],
      value: map['value'],
      readingTime: DateTime.parse(map['reading_time']),
    );
  }
}

class BPReading {
  int? id;
  int userId;
  int systolic;
  int diastolic;
  DateTime readingTime;

  BPReading({
    this.id,
    required this.userId,
    required this.systolic,
    required this.diastolic,
    required this.readingTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'systolic': systolic,
      'diastolic': diastolic,
      'reading_time': readingTime.toIso8601String(),
    };
  }

  static BPReading fromMap(Map<String, dynamic> map) {
    return BPReading(
      id: map['id'],
      userId: map['user_id'],
      systolic: map['systolic'],
      diastolic: map['diastolic'],
      readingTime: DateTime.parse(map['reading_time']),
    );
  }
}

// ==================== MAIN APP ====================
class HealthTracker extends StatelessWidget {
  final Future<Database> _databaseFuture = DatabaseHelper().database;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _databaseFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return MaterialApp(
            title: 'Health Tracker',
            theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
            home: UserListPage(),
            debugShowCheckedModeBanner: false,
          );
        } else {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }
      },
    );
  }
}

// // ==================== AUTH PAGE =========================
// class AuthPage extends StatefulWidget {
//   AuthPage({super.key});
//
//   @override
//   State<AuthPage> createState() => _AuthPageState();
// }
//
// class _AuthPageState extends State<AuthPage> {
//   @override
//   void initState() {
//     super.initState();
//     authInit();
//   }
//
//   void authInit() async {
//     bool check = await AuthService().authenticateLocally();
//     if (check) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => UserListPage()),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Health Tracker'),
//         backgroundColor: Colors.blue,
//         foregroundColor: Colors.white,
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.fingerprint,
//               size: 100,
//               color: Colors.blue,
//             ),
//             SizedBox(height: 24),
//             Text(
//               'Biometric Authentication Required',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             SizedBox(height: 12),
//             Text(
//               'Tap the fingerprint icon to authenticate',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey.shade600,
//               ),
//             ),
//             SizedBox(height: 32),
//             ElevatedButton.icon(
//               onPressed: () async {
//                 bool check = await AuthService().authenticateLocally();
//                 if (check) {
//                   Navigator.pushReplacement(
//                     context,
//                     MaterialPageRoute(builder: (context) => UserListPage()),
//                   );
//                 }
//               },
//               icon: Icon(Icons.fingerprint),
//               label: Text('Authenticate'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue,
//                 foregroundColor: Colors.white,
//                 padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // ==================== AUTH SERVICES =========================
// class AuthService {
//   final LocalAuthentication localAuth = LocalAuthentication();
//
//   Future<bool> authenticateLocally() async {
//     bool isAuthenticate = false;
//
//     try {
//       // Check if biometric is available
//       final bool canAuthenticate = await localAuth.canCheckBiometrics;
//
//       if (!canAuthenticate) {
//         print('No biometric hardware');
//         return false;
//       }
//
//       // Check for enrolled biometrics
//       final List<BiometricType> availableBiometrics =
//       await localAuth.getAvailableBiometrics();
//
//       if (availableBiometrics.isEmpty) {
//         print('No biometrics enrolled on device');
//         return false;
//       }
//
//       isAuthenticate = await localAuth.authenticate(
//         localizedReason: "Authenticate to access Health Tracker",
//         options: AuthenticationOptions(
//           biometricOnly: true,
//           useErrorDialogs: true,
//           stickyAuth: true,
//         ),
//       );
//     } catch (e) {
//       print('Authentication error: $e');
//       isAuthenticate = false;
//     }
//
//     return isAuthenticate;
//   }
// }

// ==================== USER LIST PAGE (MAIN PAGE) ====================
class UserListPage extends StatefulWidget {
  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  List<User> _users = [];
  final db = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final database = await db.database;
    final List<Map<String, dynamic>> userMaps = await database.query(
      'users',
      orderBy: 'created_at DESC',
    );
    setState(() {
      _users = userMaps.map((map) => User.fromMap(map)).toList();
    });
  }

  void _registerUser() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: RegisterUserForm(onUserAdded: _loadUsers),
        ),
      ),
    );
  }

  void _editUser(User user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: EditUserForm(user: user, onUserUpdated: _loadUsers),
        ),
      ),
    );
  }

  Future<void> _deleteUser(User user) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete User'),
        content: Text(
            'Are you sure you want to delete ${user.name}?\n\nAll their health records will also be deleted permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final database = await db.database;
              await database.delete(
                'users',
                where: 'id = ?',
                whereArgs: [user.id],
              );
              Navigator.pop(context);
              _loadUsers();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('User deleted successfully')),
              );
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Health Tracker - Users'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _users.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No users registered',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Tap + to register a new user',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: EdgeInsets.all(12),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return Card(
            elevation: 2,
            margin: EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  user.name[0].toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
              title: Text(
                user.name,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Age: ${user.age} • Sex: ${user.sex} • Phone: ${user.phone}',
                  ),
                  Text(
                    user.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                icon: Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    _editUser(user);
                  } else if (value == 'delete') {
                    _deleteUser(user);
                  }
                },
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserDashboardPage(user: user),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _registerUser,
        child: Icon(Icons.add),
        tooltip: 'Register New User',
        backgroundColor: Colors.blue,
      ),
    );
  }
}

// ==================== EDIT USER FORM ====================
class EditUserForm extends StatefulWidget {
  final User user;
  final Function onUserUpdated;

  EditUserForm({required this.user, required this.onUserUpdated});

  @override
  _EditUserFormState createState() => _EditUserFormState();
}

class _EditUserFormState extends State<EditUserForm> {
  late final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.user.name);
  late final _phoneController =
  TextEditingController(text: widget.user.phone);
  late final _addressController =
  TextEditingController(text: widget.user.address);

  late DateTime _selectedDate = widget.user.dob;
  late String _selectedSex = widget.user.sex;
  final List<String> _sexOptions = ['Male', 'Female', 'Other'];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _updateUser() async {
    if (_formKey.currentState!.validate()) {
      final db = DatabaseHelper();
      final database = await db.database;

      await database.update(
        'users',
        {
          'name': _nameController.text,
          'dob': _selectedDate.toIso8601String(),
          'sex': _selectedSex,
          'phone': _phoneController.text,
          'address': _addressController.text,
        },
        where: 'id = ?',
        whereArgs: [widget.user.id],
      );

      widget.onUserUpdated();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit User',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Update user information',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.person, color: Colors.blue),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade50,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.cake, color: Colors.orange, size: 20),
                              SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'DOB',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('dd/MM/yy').format(_selectedDate),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade50,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedSex,
                            isExpanded: true,
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: Colors.purple,
                              size: 20,
                            ),
                            items: _sexOptions.map((String sex) {
                              return DropdownMenuItem<String>(
                                value: sex,
                                child: Row(
                                  children: [
                                    Icon(
                                      sex == 'Male'
                                          ? Icons.male
                                          : sex == 'Female'
                                          ? Icons.female
                                          : Icons.transgender,
                                      size: 16,
                                      color: sex == 'Male'
                                          ? Colors.blue
                                          : sex == 'Female'
                                          ? Colors.pink
                                          : Colors.purple,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      sex,
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedSex = newValue!;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.phone, color: Colors.green),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Phone number is required';
                    }
                    String cleaned = v.replaceAll(RegExp(r'[\s\-\(\)]'), '');
                    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned)) {
                      return 'Enter valid 10 digit Indian number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.location_on, color: Colors.red),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
          SizedBox(height: 32),
          Container(
            margin: EdgeInsets.only(bottom: 8),
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _updateUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                elevation: 8,
                shadowColor: Colors.orange.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.update, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'UPDATE USER',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== REGISTER USER FORM ====================
class RegisterUserForm extends StatefulWidget {
  final Function onUserAdded;

  RegisterUserForm({required this.onUserAdded});

  @override
  _RegisterUserFormState createState() => _RegisterUserFormState();
}

class _RegisterUserFormState extends State<RegisterUserForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  DateTime _selectedDate = DateTime.now().subtract(Duration(days: 365 * 30));
  String _selectedSex = 'Male';
  final List<String> _sexOptions = ['Male', 'Female', 'Other'];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveUser() async {
    if (_formKey.currentState!.validate()) {
      final db = DatabaseHelper();
      final database = await db.database;

      await database.insert('users', {
        'name': _nameController.text,
        'dob': _selectedDate.toIso8601String(),
        'sex': _selectedSex,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'created_at': DateTime.now().toIso8601String(),
      });

      widget.onUserAdded();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User registered successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Register New User',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Fill in the details below',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.person, color: Colors.blue),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade50,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.cake, color: Colors.orange, size: 20),
                              SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'DOB',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('dd/MM/yy').format(_selectedDate),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade50,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedSex,
                            isExpanded: true,
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: Colors.purple,
                              size: 20,
                            ),
                            items: _sexOptions.map((String sex) {
                              return DropdownMenuItem<String>(
                                value: sex,
                                child: Row(
                                  children: [
                                    Icon(
                                      sex == 'Male'
                                          ? Icons.male
                                          : sex == 'Female'
                                          ? Icons.female
                                          : Icons.transgender,
                                      size: 16,
                                      color: sex == 'Male'
                                          ? Colors.blue
                                          : sex == 'Female'
                                          ? Colors.pink
                                          : Colors.purple,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      sex,
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedSex = newValue!;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.phone, color: Colors.green),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Phone number is required';
                    }
                    String cleaned = v.replaceAll(RegExp(r'[\s\-\(\)]'), '');
                    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned)) {
                      return 'Enter valid 10 digit Indian number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.location_on, color: Colors.red),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
          SizedBox(height: 32),
          Container(
            margin: EdgeInsets.only(bottom: 8),
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _saveUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 8,
                shadowColor: Colors.blue.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'REGISTER NOW',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== USER DASHBOARD ====================
class UserDashboardPage extends StatefulWidget {
  final User user;

  UserDashboardPage({required this.user});

  @override
  _UserDashboardPageState createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  List<GlucoseReading> _glucoseReadings = [];
  List<BPReading> _bpReadings = [];

  DateTime? _startDate;
  DateTime? _endDate;

  final db = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadReadings();
  }

  Future<void> _loadReadings() async {
    final database = await db.database;

    final glucoseMaps = await database.query(
      'glucose_readings',
      where: 'user_id = ?',
      whereArgs: [widget.user.id],
      orderBy: 'reading_time DESC',
    );

    final bpMaps = await database.query(
      'bp_readings',
      where: 'user_id = ?',
      whereArgs: [widget.user.id],
      orderBy: 'reading_time DESC',
    );

    setState(() {
      _glucoseReadings =
          glucoseMaps.map((m) => GlucoseReading.fromMap(m)).toList();
      _bpReadings = bpMaps.map((m) => BPReading.fromMap(m)).toList();
    });
  }

  List<GlucoseReading> get _graphGlucose {
    if (_startDate == null || _endDate == null) {
      return _glucoseReadings.reversed.toList();
    }
    return _glucoseReadings
        .where(
          (r) =>
      !r.readingTime.isBefore(_startDate!) &&
          r.readingTime.isBefore(_endDate!.add(Duration(days: 1))),
    )
        .toList()
        .reversed
        .toList();
  }

  List<GlucoseReading> get _filteredGlucose {
    if (_startDate == null || _endDate == null) return _glucoseReadings;
    return _glucoseReadings
        .where(
          (r) =>
      !r.readingTime.isBefore(_startDate!) &&
          r.readingTime.isBefore(_endDate!.add(Duration(days: 1))),
    )
        .toList();
  }

  List<BPReading> get _graphBP {
    if (_startDate == null || _endDate == null) {
      return _bpReadings.reversed.toList();
    }
    return _bpReadings
        .where(
          (r) =>
      !r.readingTime.isBefore(_startDate!) &&
          r.readingTime.isBefore(_endDate!.add(Duration(days: 1))),
    )
        .toList()
        .reversed
        .toList();
  }

  List<BPReading> get _filteredBP {
    if (_startDate == null || _endDate == null) return _bpReadings;
    return _bpReadings
        .where(
          (r) =>
      !r.readingTime.isBefore(_startDate!) &&
          r.readingTime.isBefore(_endDate!.add(Duration(days: 1))),
    )
        .toList();
  }

  void _addGlucoseReading() {
    DateTime selectedDate = DateTime.now();
    TextEditingController valueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Glucose Reading'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: valueController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Glucose (mg/dL)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                          );
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today),
                          SizedBox(width: 8),
                          Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (valueController.text.isNotEmpty) {
                      final database = await db.database;
                      await database.insert('glucose_readings', {
                        'user_id': widget.user.id,
                        'value': double.parse(valueController.text),
                        'reading_time': selectedDate.toIso8601String(),
                      });
                      Navigator.pop(context);
                      _loadReadings();
                    }
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addBPReading() {
    DateTime selectedDate = DateTime.now();
    TextEditingController systolicController = TextEditingController();
    TextEditingController diastolicController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add BP Reading'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: systolicController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Systolic',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: diastolicController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Diastolic',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                          );
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today),
                          SizedBox(width: 8),
                          Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (systolicController.text.isNotEmpty &&
                        diastolicController.text.isNotEmpty) {
                      final database = await db.database;
                      await database.insert('bp_readings', {
                        'user_id': widget.user.id,
                        'systolic': int.parse(systolicController.text),
                        'diastolic': int.parse(diastolicController.text),
                        'reading_time': selectedDate.toIso8601String(),
                      });
                      Navigator.pop(context);
                      _loadReadings();
                    }
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editGlucoseReading(GlucoseReading reading) {
    DateTime selectedDate = reading.readingTime;
    TextEditingController valueController =
    TextEditingController(text: reading.value.toString());

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Glucose Reading'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: valueController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Glucose (mg/dL)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                          );
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today),
                          SizedBox(width: 8),
                          Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (valueController.text.isNotEmpty) {
                      final database = await db.database;
                      await database.update(
                        'glucose_readings',
                        {
                          'value': double.parse(valueController.text),
                          'reading_time': selectedDate.toIso8601String(),
                        },
                        where: 'id = ?',
                        whereArgs: [reading.id],
                      );
                      Navigator.pop(context);
                      _loadReadings();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Reading updated')),
                      );
                    }
                  },
                  child: Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editBPReading(BPReading reading) {
    DateTime selectedDate = reading.readingTime;
    TextEditingController systolicController =
    TextEditingController(text: reading.systolic.toString());
    TextEditingController diastolicController =
    TextEditingController(text: reading.diastolic.toString());

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit BP Reading'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: systolicController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Systolic',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: diastolicController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Diastolic',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                          );
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today),
                          SizedBox(width: 8),
                          Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (systolicController.text.isNotEmpty &&
                        diastolicController.text.isNotEmpty) {
                      final database = await db.database;
                      await database.update(
                        'bp_readings',
                        {
                          'systolic': int.parse(systolicController.text),
                          'diastolic': int.parse(diastolicController.text),
                          'reading_time': selectedDate.toIso8601String(),
                        },
                        where: 'id = ?',
                        whereArgs: [reading.id],
                      );
                      Navigator.pop(context);
                      _loadReadings();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Reading updated')),
                      );
                    }
                  },
                  child: Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteGlucoseReading(GlucoseReading reading) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Reading'),
        content: Text('Are you sure you want to delete this glucose reading?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final database = await db.database;
              await database.delete(
                'glucose_readings',
                where: 'id = ?',
                whereArgs: [reading.id],
              );
              Navigator.pop(context);
              _loadReadings();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Reading deleted')),
              );
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBPReading(BPReading reading) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Reading'),
        content: Text('Are you sure you want to delete this BP reading?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final database = await db.database;
              await database.delete(
                'bp_readings',
                where: 'id = ?',
                whereArgs: [reading.id],
              );
              Navigator.pop(context);
              _loadReadings();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Reading deleted')),
              );
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _sharePDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Health Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Patient Information',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Row(children: [
                    pw.Text('Name: ',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(widget.user.name),
                  ]),
                  pw.Row(children: [
                    pw.Text('Date of Birth: ',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(DateFormat('dd/MM/yyyy').format(widget.user.dob)),
                  ]),
                  pw.Row(children: [
                    pw.Text('Age: ',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('${widget.user.age} years'),
                  ]),
                  pw.Row(children: [
                    pw.Text('Sex: ',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(widget.user.sex),
                  ]),
                  pw.Row(children: [
                    pw.Text('Phone: ',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(widget.user.phone),
                  ]),
                  pw.Row(children: [
                    pw.Text('Address: ',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(widget.user.address),
                  ]),
                  pw.SizedBox(height: 8),
                  pw.Row(children: [
                    pw.Text('Report Period: ',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                      _startDate != null && _endDate != null
                          ? '${DateFormat('dd/MM/yy').format(_startDate!)} - ${DateFormat('dd/MM/yy').format(_endDate!)}'
                          : 'All Records',
                    ),
                  ]),
                ],
              ),
            ),
            pw.SizedBox(height: 30),
            if (_graphGlucose.isNotEmpty) ...[
              pw.Text(
                'Glucose Summary',
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 12),
              pw.Container(
                padding: pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('📊 Glucose Readings Overview',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    pw.Text(
                        'Period: ${DateFormat('dd/MM/yy').format(_graphGlucose.first.readingTime)} - ${DateFormat('dd/MM/yy').format(_graphGlucose.last.readingTime)}'),
                    pw.Text('Total Readings: ${_graphGlucose.length}'),
                    pw.SizedBox(height: 8),
                    pw.Text(
                        'Lowest: ${_graphGlucose.map((e) => e.value).reduce((a, b) => a < b ? a : b).toStringAsFixed(1)} mg/dL'),
                    pw.Text(
                        'Highest: ${_graphGlucose.map((e) => e.value).reduce((a, b) => a > b ? a : b).toStringAsFixed(1)} mg/dL'),
                    pw.Text(
                        'Average: ${(_graphGlucose.map((e) => e.value).reduce((a, b) => a + b) / _graphGlucose.length).toStringAsFixed(1)} mg/dL'),
                    pw.SizedBox(height: 8),
                    pw.Divider(),
                    pw.SizedBox(height: 4),
                    pw.Text('📈 Trend:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(_getTrendDescription()),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
            ],
            if (_graphBP.isNotEmpty) ...[
              pw.Text(
                'Blood Pressure Summary',
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 12),
              pw.Container(
                padding: pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('🩺 BP Readings Overview',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    pw.Text('Total Readings: ${_graphBP.length}'),
                    pw.Text(
                        'Avg Systolic: ${(_graphBP.map((e) => e.systolic).reduce((a, b) => a + b) ~/ _graphBP.length)} mmHg'),
                    pw.Text(
                        'Avg Diastolic: ${(_graphBP.map((e) => e.diastolic).reduce((a, b) => a + b) ~/ _graphBP.length)} mmHg'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
            ],
            if (_filteredGlucose.isNotEmpty) ...[
              pw.Text(
                'Glucose Readings',
                style: pw.TextStyle(
                    fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 12),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Container(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text('Date',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold))),
                      pw.Container(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text('Value',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold))),
                      pw.Container(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text('Status',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  ..._filteredGlucose.reversed.take(20).map((r) {
                    String status = r.value < 70
                        ? 'Low'
                        : r.value <= 139
                        ? 'Normal'
                        : r.value <= 199
                        ? 'Borderline'
                        : r.value <= 270
                        ? 'High'
                        : 'Very High';
                    PdfColor color = r.value < 70
                        ? PdfColors.blue700
                        : r.value <= 139
                        ? PdfColors.green700
                        : r.value <= 199
                        ? PdfColors.orange700
                        : r.value <= 270
                        ? PdfColors.red700
                        : PdfColors.purple700;
                    return pw.TableRow(
                      children: [
                        pw.Container(
                            padding: pw.EdgeInsets.all(8),
                            child: pw.Text(DateFormat('dd/MM/yy')
                                .format(r.readingTime))),
                        pw.Container(
                            padding: pw.EdgeInsets.all(8),
                            child: pw.Text('${r.value.toStringAsFixed(1)}')),
                        pw.Container(
                            padding: pw.EdgeInsets.all(8),
                            child: pw.Text(
                              status,
                              style: pw.TextStyle(
                                  color: color,
                                  fontWeight: pw.FontWeight.bold),
                            )),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 20),
            ],
            if (_filteredBP.isNotEmpty) ...[
              pw.Text(
                'Blood Pressure Readings',
                style: pw.TextStyle(
                    fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 12),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Container(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text('Date',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold))),
                      pw.Container(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text('Systolic',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold))),
                      pw.Container(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text('Diastolic',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold))),
                      pw.Container(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text('Status',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  ..._filteredBP.reversed.take(20).map((r) {
                    String status = r.systolic < 120 && r.diastolic < 80
                        ? 'Normal'
                        : (r.systolic < 130 && r.diastolic < 80
                        ? 'Elevated'
                        : 'High');
                    return pw.TableRow(
                      children: [
                        pw.Container(
                            padding: pw.EdgeInsets.all(8),
                            child: pw.Text(DateFormat('dd/MM/yy')
                                .format(r.readingTime))),
                        pw.Container(
                            padding: pw.EdgeInsets.all(8),
                            child: pw.Text('${r.systolic}')),
                        pw.Container(
                            padding: pw.EdgeInsets.all(8),
                            child: pw.Text('${r.diastolic}')),
                        pw.Container(
                            padding: pw.EdgeInsets.all(8),
                            child: pw.Text(status)),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ],
            pw.SizedBox(height: 20),
            pw.Text(
                'Generated on: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
          ];
        },
      ),
    );

    final pdfData = await pdf.save();
    final file = XFile.fromData(
      pdfData,
      mimeType: 'application/pdf',
      name: 'Health_Report_${widget.user.name}.pdf',
    );
    await Share.shareXFiles([file],
        text: 'Health Report - ${widget.user.name}');
  }

  String _getTrendDescription() {
    if (_graphGlucose.length < 2) return 'Insufficient data for trend analysis';

    double first = _graphGlucose.first.value;
    double last = _graphGlucose.last.value;
    double change = ((last - first) / first * 100);

    if (change < -5) {
      return '📉 Decreasing (${change.abs().toStringAsFixed(1)}% lower) - Improving';
    }
    if (change > 5) {
      return '📈 Increasing (${change.toStringAsFixed(1)}% higher) - Needs attention';
    }
    return '➡️ Stable (${change.toStringAsFixed(1)}% change)';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.user.name),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          bottom: TabBar(
            tabs: [
              Tab(text: 'Glucose', icon: Icon(Icons.bloodtype)),
              Tab(text: 'Blood Pressure', icon: Icon(Icons.favorite)),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.picture_as_pdf),
              onPressed: _filteredGlucose.isEmpty && _filteredBP.isEmpty
                  ? null
                  : _sharePDF,
              tooltip: 'Share PDF',
            ),
          ],
        ),
        body: TabBarView(children: [_buildGlucoseTab(), _buildBPTab()]),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: CircleAvatar(
                        child: Icon(Icons.bloodtype),
                        backgroundColor: Colors.green),
                    title: Text('Add Glucose Reading'),
                    onTap: () {
                      Navigator.pop(context);
                      _addGlucoseReading();
                    },
                  ),
                  ListTile(
                    leading: CircleAvatar(
                        child: Icon(Icons.favorite),
                        backgroundColor: Colors.red),
                    title: Text('Add BP Reading'),
                    onTap: () {
                      Navigator.pop(context);
                      _addBPReading();
                    },
                  ),
                ],
              ),
            );
          },
          child: Icon(Icons.add),
          backgroundColor: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildGlucoseTab() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectDateRange,
                  child: Container(
                    padding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.date_range, size: 20),
                        SizedBox(width: 8),
                        Text(
                          _startDate == null
                              ? 'Select Date Range'
                              : '${DateFormat('dd/MM/yy').format(_startDate!)} - ${DateFormat('dd/MM/yy').format(_endDate!)}',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_startDate != null)
                IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () => setState(() {
                    _startDate = null;
                    _endDate = null;
                  }),
                ),
            ],
          ),
        ),
        if (_graphGlucose.isNotEmpty)
          Container(
            height: 200,
            padding: EdgeInsets.all(12),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: _graphGlucose.length > 8 ? 2 : 1,
                          getTitlesWidget: (value, meta) {
                            int index = value.toInt();
                            if (index >= 0 &&
                                index < _graphGlucose.length &&
                                (_graphGlucose.length <= 8 ||
                                    index % 2 == 0)) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  DateFormat('dd/MM').format(
                                      _graphGlucose[index].readingTime),
                                  style: TextStyle(fontSize: 9),
                                ),
                              );
                            }
                            return Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 50,
                          reservedSize: 35,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _graphGlucose
                            .asMap()
                            .entries
                            .map((e) => FlSpot(e.key.toDouble(), 70))
                            .toList(),
                        color: Colors.green.withOpacity(0.3),
                        barWidth: 1,
                        dashArray: [5, 5],
                        dotData: FlDotData(show: false),
                      ),
                      LineChartBarData(
                        spots: _graphGlucose
                            .asMap()
                            .entries
                            .map((e) => FlSpot(e.key.toDouble(), 139))
                            .toList(),
                        color: Colors.red.withOpacity(0.3),
                        barWidth: 1,
                        dashArray: [5, 5],
                        dotData: FlDotData(show: false),
                      ),
                      LineChartBarData(
                        spots: _graphGlucose
                            .asMap()
                            .entries
                            .map((e) =>
                            FlSpot(e.key.toDouble(), e.value.value))
                            .toList(),
                        isCurved: true,
                        color: Colors.green,
                        barWidth: 2,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                            show: true,
                            color: Colors.green.withOpacity(0.1)),
                      ),
                    ],
                    minX: 0,
                    maxX: _graphGlucose.length > 1
                        ? (_graphGlucose.length - 1).toDouble()
                        : 1,
                    minY: 0,
                    maxY: _graphGlucose.isEmpty
                        ? 200
                        : (_graphGlucose
                        .map((e) => e.value)
                        .reduce((a, b) => a > b ? a : b) +
                        50),
                  ),
                ),
              ),
            ),
          )
        else
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bloodtype, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No glucose readings',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            ),
          ),
        if (_filteredGlucose.isNotEmpty)
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: _filteredGlucose.length,
              itemBuilder: (context, index) {
                final reading = _filteredGlucose[index];
                String status = reading.value < 70
                    ? 'Low'
                    : reading.value <= 139
                    ? 'Normal'
                    : reading.value <= 199
                    ? 'Borderline'
                    : reading.value <= 270
                    ? 'High'
                    : 'Very High';
                Color color = reading.value < 70
                    ? Colors.blue
                    : reading.value <= 139
                    ? Colors.green
                    : reading.value <= 199
                    ? Colors.orange
                    : reading.value <= 270
                    ? Colors.red
                    : Colors.purple;
                return Card(
                  margin: EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.2),
                      child: Text(
                        '${reading.value.toInt()}',
                        style: TextStyle(
                            color: color, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text('${reading.value} mg/dL',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        DateFormat('dd/MM/yyyy').format(reading.readingTime)),
                    trailing: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editGlucoseReading(reading);
                        } else if (value == 'delete') {
                          _deleteGlucoseReading(reading);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildBPTab() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectDateRange,
                  child: Container(
                    padding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.date_range, size: 20),
                        SizedBox(width: 8),
                        Text(
                          _startDate == null
                              ? 'Select Date Range'
                              : '${DateFormat('dd/MM/yy').format(_startDate!)} - ${DateFormat('dd/MM/yy').format(_endDate!)}',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_startDate != null)
                IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () => setState(() {
                    _startDate = null;
                    _endDate = null;
                  }),
                ),
            ],
          ),
        ),
        if (_graphBP.isNotEmpty)
          Container(
            height: 200,
            padding: EdgeInsets.all(12),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: _graphBP.length > 8 ? 2 : 1,
                          getTitlesWidget: (value, meta) {
                            int index = value.toInt();
                            if (index >= 0 &&
                                index < _graphBP.length &&
                                (_graphBP.length <= 8 || index % 2 == 0)) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  DateFormat('dd/MM')
                                      .format(_graphBP[index].readingTime),
                                  style: TextStyle(fontSize: 9),
                                ),
                              );
                            }
                            return Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 20,
                          reservedSize: 35,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _graphBP
                            .asMap()
                            .entries
                            .map((e) => FlSpot(e.key.toDouble(), 120))
                            .toList(),
                        color: Colors.green.withOpacity(0.3),
                        barWidth: 1,
                        dashArray: [5, 5],
                        dotData: FlDotData(show: false),
                      ),
                      LineChartBarData(
                        spots: _graphBP
                            .asMap()
                            .entries
                            .map((e) => FlSpot(e.key.toDouble(), 80))
                            .toList(),
                        color: Colors.green.withOpacity(0.3),
                        barWidth: 1,
                        dashArray: [5, 5],
                        dotData: FlDotData(show: false),
                      ),
                      LineChartBarData(
                        spots: _graphBP
                            .asMap()
                            .entries
                            .map((e) => FlSpot(e.key.toDouble(),
                            e.value.systolic.toDouble()))
                            .toList(),
                        isCurved: true,
                        color: Colors.red,
                        barWidth: 2,
                        dotData: FlDotData(show: true),
                      ),
                      LineChartBarData(
                        spots: _graphBP
                            .asMap()
                            .entries
                            .map((e) => FlSpot(e.key.toDouble(),
                            e.value.diastolic.toDouble()))
                            .toList(),
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 2,
                        dotData: FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No BP readings',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            ),
          ),
        if (_filteredBP.isNotEmpty)
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: _filteredBP.length,
              itemBuilder: (context, index) {
                final reading = _filteredBP[index];
                String status =
                reading.systolic < 120 && reading.diastolic < 80
                    ? 'Normal'
                    : (reading.systolic < 130 && reading.diastolic < 80
                    ? 'Elevated'
                    : 'High');
                Color color =
                reading.systolic < 120 && reading.diastolic < 80
                    ? Colors.green
                    : (reading.systolic < 130 && reading.diastolic < 80
                    ? Colors.orange
                    : Colors.red);
                return Card(
                  margin: EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.2),
                      child: Text(
                        '${reading.systolic}',
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                    title: Text(
                        '${reading.systolic}/${reading.diastolic} mmHg',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(DateFormat('dd/MM/yyyy')
                        .format(reading.readingTime)),
                    trailing: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editBPReading(reading);
                        } else if (value == 'delete') {
                          _deleteBPReading(reading);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}