import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:asset_guard/provider/asset_provider.dart';

class Usage extends StatefulWidget {
  const Usage({super.key});

  @override
  State<Usage> createState() => _UsageState();
}

class _UsageState extends State<Usage> {
  late String _assetId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final Map<String, dynamic>? arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    _assetId = arguments?['id'] ?? '';

    if (_assetId.isNotEmpty) {
      checkFlaskConnectionAndSendAssetId(_assetId);
    }
  }

  Future<void> checkFlaskConnectionAndSendAssetId(String assetId) async {
    try {
      final url = Uri.parse('http://192.168.100.10:5000/monitor-usage');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        await sendAssetIdToFlask(assetId);
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> sendAssetIdToFlask(String assetId) async {
    final url = Uri.parse('http://192.168.100.10:5000/send-assetid');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'assetid': assetId}),
      );

      if (response.statusCode == 200) {
        print('Asset ID sent to Flask successfully');
      } else {
        print(
            'Failed to send Asset ID to Flask (Status: ${response.statusCode})');
      }
    } catch (e) {
      print('Error sending Asset ID to Flask: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final AssetProvider assetProvider = AssetProvider();

    return Scaffold(
      appBar: AppBar(title: const Text('Usage Analysis')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: assetProvider.fetchMonitorData(_assetId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final data = snapshot.data ?? [];

            if (data.isEmpty) {
              return const Center(child: Text('No data available'));
            }

            return ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                return ListTile(
                  title: Text(item['status'] ?? 'Unknown Status'),
                  subtitle: Text('Count: ${item['count'] ?? 0}'),
                );
              },
            );
          } else {
            return const Center(child: Text('No data available'));
          }
        },
      ),
    );
  }
}
