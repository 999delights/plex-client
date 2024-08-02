import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ActivePage extends StatelessWidget {
  final List<dynamic> statuses;
  final Function onStatusTapped;
  final List<String> activeFilters;

  ActivePage({
    required this.statuses,
    required this.onStatusTapped,
    required this.activeFilters,
  });

  @override
  Widget build(BuildContext context) {
    // Filter the statuses list based on the active filters
    List<dynamic> filteredStatuses = statuses.where((status) {
      return activeFilters.contains(status['state']);
    }).toList();

    if (filteredStatuses.isEmpty) {
      return Center(
        child: Text(
          "No active downloads",
          style: TextStyle(color: Colors.white),
        ),
      );
    } else {
      return ListView.builder(
        itemCount: filteredStatuses.length,
        itemBuilder: (context, index) {
          final status = filteredStatuses[index];
          // Format the date
          DateTime dateTime = DateTime.parse(status['download_date']);
          String formattedDate = DateFormat('HH:mm:ss dd-MM-yyyy').format(dateTime);

          // Convert size to GB
          double sizeInGB = status['size'] / (1024 * 1024 * 1024);

          // Convert download speed to MB/s
          double downloadSpeedInMBps = status['dlspeed'] / (1024 * 1024);

          // Convert upload speed to MB/s
          double uploadSpeedInMBps = status['upspeed'] / (1024 * 1024);

          return Container(
            color: status['state'] != 'downloading' ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
            child: ListTile(
              title: Text(
                status['name'],
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Row(
                children: [
                  Icon(Icons.arrow_downward, color: Colors.green),
                  Text(
                    '${downloadSpeedInMBps.toStringAsFixed(2)} MB/s ',
                    style: TextStyle(color: Colors.white),
                  ),
                  Icon(Icons.arrow_upward, color: Colors.red),
                  Text(
                    '${uploadSpeedInMBps.toStringAsFixed(2)} MB/s ',
                    style: TextStyle(color: Colors.white),
                  ),
                  Spacer(),
                  Text(
                    'Progress: ${(status['progress'] * 100).toStringAsFixed(2)}%',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              onTap: () => onStatusTapped(context, status, formattedDate, sizeInGB),
            ),
          );
        },
      );
    }
  }
}
