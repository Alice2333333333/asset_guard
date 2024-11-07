import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asset_guard/provider/asset_provider.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  @override
  void initState() {
    super.initState();
    Provider.of<AssetProvider>(context, listen: false).fetchAssets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AssetGuard'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.notifications),
            tooltip: 'Notification',
            onPressed: () {
              Navigator.pushNamed(context, '/notification');
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_rounded),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: Consumer<AssetProvider>(
        builder: (context, assetProvider, child) {
          final assets = assetProvider.assets;

          return ListView.separated(
            padding: const EdgeInsets.all(12.0),
            itemCount: assets.length,
            itemBuilder: (context, index) {
              final asset = assets[index];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    elevation: 3,
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.build, color: Colors.blueAccent),
                      ),
                      title: Text(
                        asset['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        "Serial Number: ${asset['serialNumber']}",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                      onTap: () {
                        Navigator.pushNamed(context, '/asset', arguments: asset);
                      },
                    ),
                  ),
                ],
              );
            },
            separatorBuilder: (context, index) => const SizedBox(height: 8),
          );
        },
      ),
    );
  }
}
