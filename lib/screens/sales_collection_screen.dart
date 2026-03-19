import 'package:flutter/material.dart';
import '../widgets/csv_upload_card.dart';

class SalesCollectionScreen extends StatelessWidget {
  const SalesCollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page header bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sales Collection',
                    style: TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Upload and manage sales collection records',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),

          // Upload card — uses your API endpoint
          const CsvUploadCard(
            title: 'Sales Collection',
            apiEndpoint: '/SalesCollection/upload',
          ),
        ],
      ),
    );
  }
}