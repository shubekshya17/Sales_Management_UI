import 'package:flutter/material.dart';
import '../widgets/csv_upload_card.dart';

class SalesDetailScreen extends StatelessWidget {
  const SalesDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sales Detail',
                    style: TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Upload and manage detailed sales records',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const CsvUploadCard(
            title: 'Sales Detail',
            apiEndpoint: '/SalesDetail/upload',  // matches your route
          ),
        ],
      ),
    );
  }
}