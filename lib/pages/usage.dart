import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';

class Usage extends StatefulWidget {
  const Usage({super.key});

  @override
  State<Usage> createState() => _UsageState();
}

class _UsageState extends State<Usage> {
  late Future<List<dynamic>> monitorData;

  @override
  void initState() {
    super.initState();
    monitorData = fetchMonitorUsage();
  }

  // Function to fetch data from Flask endpoint
  Future<List<dynamic>> fetchMonitorUsage() async {
    final response =
        await http.get(Uri.parse('http://192.168.100.10:5000/monitor-usage'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> asset =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;

    final String assetId = asset['id'];

    return Scaffold(
      appBar: AppBar(title: const Text('Usage Analysis')),
      body: FutureBuilder<List<dynamic>>(
        future: monitorData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final data = snapshot.data!;
            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text('No data available'));
            }
            return ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                return ListTile(
                  title: Text("Status: ${item['status']}"),
                  subtitle: Text("Count: ${item['count']}"),
                );
              },
            );
          }
        },
      ),
    );
  }
}
