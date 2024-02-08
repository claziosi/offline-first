import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'local_storage.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive and register the adapter.
  await Hive.initFlutter();
  Hive.registerAdapter(FormDataAdapter());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Online/Offline Indicator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Connectivity _connectivity = Connectivity();
  late Stream<ConnectivityResult> _connectivityStream;
  ConnectivityResult _connectionStatus = ConnectivityResult.none;

  // Additional variable to track whether we're currently syncing
  bool _isSyncing = false;

  final TextEditingController _field1Controller = TextEditingController();
  final TextEditingController _field2Controller = TextEditingController();
  final TextEditingController _field3Controller = TextEditingController();

  Box<FormData>? formDataBox;

  @override
  void initState() {
    super.initState();
    initConnectivity();
    _connectivityStream = _connectivity.onConnectivityChanged;
    _connectivityStream.listen((ConnectivityResult result) {
      // We pass context here assuming that this callback is only called while the widget is still mounted
      _updateConnectionStatus(result, context);
    });
    openHiveBox();
  }

  Future<void> openHiveBox() async {
    formDataBox = await Hive.openBox<FormData>('formData');
  }

  void saveDataLocally() {
    final formData = FormData()
      ..field1 = _field1Controller.text
      ..field2 = _field2Controller.text
      ..field3 = _field3Controller.text;

    formDataBox?.add(formData);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data saved locally!')),
    );
    clearFields();
  }

  void clearFields() {
    _field1Controller.clear();
    _field2Controller.clear();
    _field3Controller.clear();
  }

  Future<void> syncDataWithBackend() async {
    if (_isSyncing) return; // Prevent multiple sync attempts simultaneously

    if (_connectionStatus != ConnectivityResult.none) {
      setState(() {
        _isSyncing = true;
      });

      final unsyncedData = formDataBox?.values.toList() ?? [];

      for (var data in unsyncedData) {
        await sendDataToBackend(data);
        await data.delete(); // Remove from local storage after successful sync.
      }

      setState(() {
        _isSyncing = false;
      });

      if (!unsyncedData.isEmpty)
        clearFields(); // Clear fields only if there was something to sync
    }
  }

  Future<bool> sendDataToBackend(FormData data) async {
    // Simulate a delay for testing purposes
    await Future.delayed(Duration(seconds: 2));

    try {
      var response = await http.post(
        Uri.parse('https://salvr.westeurope.cloudapp.azure.com/data/add'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'field1': data.field1,
          'field2': data.field2,
          'field3': data.field3,
        }),
      );

      if (response.statusCode == 201) {
        print('Data sent to backend!');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data sent to backend!')),
        );
        return true;
      } else {
        print('Failed to send data. Status code: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send data!')),
        );
        return false;
      }
    } catch (e) {
      print('Failed to send data due to exception: $e');
      return false;
    }
  }

  void handleSubmit() async {
    final formData = FormData()
      ..field1 = _field1Controller.text
      ..field2 = _field2Controller.text
      ..field3 = _field3Controller.text;

    if (_connectionStatus != ConnectivityResult.none) {
      bool success = await sendDataToBackend(formData);
      if (success) clearFields(); // Only clear fields on successful send
    } else {
      formDataBox?.add(formData); // Save locally if offline
      clearFields(); // Clear fields after saving locally
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No connection. Data saved locally!')),
      );
    }
  }

  void _updateConnectionStatus(
      ConnectivityResult result, BuildContext context) async {
    setState(() => _connectionStatus = result);

    if (result != ConnectivityResult.none && formDataBox != null) {
      final unsyncedData = formDataBox!.values.toList();

      for (var formData in unsyncedData) {
        bool success = await sendDataToBackend(formData);
        if (success) {
          await formData
              .delete(); // Remove from local storage after successful sync.
        }
      }
    }
  }

  // Initialize connectivity status
  Future<void> initConnectivity() async {
    try {
      var currentStatus = await _connectivity.checkConnectivity();
      if (!mounted) return; // In case our widget was removed from the tree.
      setState(() {
        _connectionStatus = currentStatus;
      });
    } catch (e) {
      print("Couldn't check connectivity status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Offline-First App'),
        backgroundColor: (_connectionStatus != ConnectivityResult.none)
            ? Colors.green
            : Colors.red, // For better contrast of AppBar items
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                (_connectionStatus != ConnectivityResult.none)
                    ? 'Online'
                    : 'Offline',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextField(
              controller: _field1Controller,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _field2Controller,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            //Text area with 4 lines
            TextField(
              controller: _field3Controller,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            // Add a margin-down to create some space between the fields and the button
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: (_connectionStatus != ConnectivityResult.none)
                  ? handleSubmit // Call handleSubmit when online
                  : saveDataLocally, // Call saveDataLocally when offline
              child: Text((_connectionStatus != ConnectivityResult.none)
                  ? 'Submit'
                  : 'Save Locally'),
            ),

            // The rest of your app content goes here.
          ],
        ),
      ),
    );
  }
}
