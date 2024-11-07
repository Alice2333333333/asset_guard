import 'package:flutter/material.dart';

class AssetPage extends StatelessWidget {
  const AssetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> asset =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${asset['name']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Serial Number: ${asset['serialNumber']}',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 10),
            Text(
              'Type of asset: ${asset['type']}',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 10),
            Text(
              'Price: ${asset['price']}',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 10),
            Text(
              'Condition: ${asset['condition']}',
              style: const TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
