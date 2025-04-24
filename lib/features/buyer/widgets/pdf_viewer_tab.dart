// Add this class at the bottom of your file or in a separate file
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

class PDFViewerPage extends StatelessWidget {
  final String pdfPath;
  final String pdfUrl;
  final String pdfTitle;

  const PDFViewerPage({
    Key? key,
    required this.pdfPath,
    required this.pdfUrl,
    required this.pdfTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pdfTitle),
        actions: [
          // Download button
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () async {
              final Uri uri = Uri.parse(pdfUrl);
              try {
                await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Could not download: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SfPdfViewer.network(pdfUrl),
    );
  }
}