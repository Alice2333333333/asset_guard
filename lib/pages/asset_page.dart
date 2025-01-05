import 'package:flutter/material.dart';

class AssetPage extends StatelessWidget {
  const AssetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> asset =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;

    String condition = asset['condition'] ? 'Good' : 'Bad';
    Color conditionColor = asset['condition'] ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Asset Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 144, 181, 212),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 3,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Image(
                  width: double.infinity,
                  height: 170,
                  image: NetworkImage(
                      'https://www.hilti.com.my/medias/sys_master/images/h7d/h71/9718078996510.jpg'),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              asset['name'],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              margin: const EdgeInsets.symmetric(horizontal: 90),
              decoration: BoxDecoration(
                color: conditionColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: conditionColor, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                condition,
                style: TextStyle(
                  color: conditionColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Asset Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const Divider(thickness: 1.2),
                    const SizedBox(height: 10),
                    _buildStackedAssetDetailRow(
                        Icons.vpn_key, 'Serial Number:', asset['serial_number']),
                    const Divider(),
                    _buildStackedAssetDetailRow(Icons.description,
                        'Description:', asset['description']),
                    const Divider(),
                    _buildStackedAssetDetailRow(
                        Icons.category, 'Type of Asset:', asset['type']),
                    const Divider(),
                    _buildStackedAssetDetailRow(
                        Icons.attach_money, 'Price:', 'RM ${asset['price']}'),
                    const Divider(),
                    _buildStackedAssetDetailRow(
                        Icons.calendar_today,
                        'Next Maintenance:',
                        asset['next_maintenance'] ?? 'Not Scheduled'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/usage', arguments: asset);
              },
              icon: const Icon(Icons.analytics, color: Colors.white),
              label: const Text(
                'Usage Analysis',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 25, 58, 94),
                padding: const EdgeInsets.symmetric(vertical: 8),
                elevation: 6,
                shadowColor: Colors.black.withOpacity(0.1),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/maintenance', arguments: asset);
              },
              icon: const Icon(
                Icons.build,
                color: Color.fromARGB(255, 25, 58, 94),
              ),
              label: const Text(
                'Maintenance Records',
                style: TextStyle(
                  fontSize: 15,
                  color: Color.fromARGB(255, 25, 58, 94),
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                elevation: 3,
                shadowColor: Colors.black.withOpacity(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildStackedAssetDetailRow(IconData icon, String label, String value) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, color: const Color.fromARGB(255, 84, 141, 188)),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.only(left: 36),
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
      ),
    ],
  );
}
