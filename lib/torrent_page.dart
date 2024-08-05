import 'package:flutter/material.dart';

class TorrentDetailsPage extends StatelessWidget {
  final dynamic torrent;
  final VoidCallback onDownload;

  TorrentDetailsPage({required this.torrent, required this.onDownload});

  String _formatSize(String sizeInBytesStr) {
    // Convert the string to an integer
    int sizeInBytes = int.tryParse(sizeInBytesStr) ?? 0;
    double sizeInGB = sizeInBytes / (1024 * 1024 * 1024);
    return sizeInGB.toStringAsFixed(2) + ' GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(torrent['name']),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Name: ${torrent['name']}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text('Category: ${torrent['category']}'),
            SizedBox(height: 10),
            Text('Size: ${_formatSize(torrent['size'])}'),
            SizedBox(height: 10),
            Text('Seeders: ${torrent['seeders']}'),
            SizedBox(height: 10),
            Text('Leechers: ${torrent['leechers']}'),
            SizedBox(height: 10),
            if (torrent.containsKey('small_description'))
              Text('Description: ${torrent['small_description']}'),
            SizedBox(height: 10),
            if (torrent.containsKey('upload_date'))
              Text('Uploaded: ${torrent['upload_date']}'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: onDownload,
              child: Text('Download'),
            ),
          ],
        ),
      ),
    );
  }
}
