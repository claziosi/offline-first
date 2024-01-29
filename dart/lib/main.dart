import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'local_storage.dart';

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

  final TextEditingController _field1Controller = TextEditingController();
  final TextEditingController _field2Controller = TextEditingController();

  Box<FormData>? formDataBox;

  @override
  void initState() {
    super.initState();
    initConnectivity();
    _connectivityStream = _connectivity.onConnectivityChanged;
    _connectivityStream.listen(_updateConnectionStatus);
    openHiveBox();
  }

  Future<void> openHiveBox() async {
    formDataBox = await Hive.openBox<FormData>('formData');
  }

  void saveDataLocally() {
    final formData = FormData()
      ..field1 = _field1Controller.text
      ..field2 = _field2Controller.text;

    formDataBox?.add(formData);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data saved locally!')),
    );
  }

  Future<void> syncDataWithBackend() async {
    if (_connectionStatus != ConnectivityResult.none) {
      // Assume that we have a function `sendDataToBackend(FormData data)`
      // that takes care of sending our saved form data to the backend.

      final unsyncedData = formDataBox?.values.toList() ?? [];

      for (var data in unsyncedData) {
        try {
          await sendDataToBackend(
              data); // Implement this function based on your backend API.
          await data
              .delete(); // Remove from local storage after successful sync.

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data synced with backend!')),
          );
        } catch (e) {
          print('Failed to send data: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to sync data!')),
          );
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

  void _updateConnectionStatus(ConnectivityResult result) {
    if (!mounted) return; // In case our widget was removed from the tree.
    setState(() {
      _connectionStatus = result;
    });
  }

  sendDataToBackend(FormData data) {
    print("Sending data to backend: $data");
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
              decoration: const InputDecoration(labelText: 'Field One'),
            ),
            TextField(
              controller: _field2Controller,
              decoration: const InputDecoration(labelText: 'Field Two'),
            ),
            ElevatedButton(
              onPressed: (_connectionStatus != ConnectivityResult.none)
                  ? () async {
                      await syncDataWithBackend();
                    }
                  : saveDataLocally,
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
