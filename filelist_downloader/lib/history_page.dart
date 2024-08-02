import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add this import for date formatting

class HistoryPage extends StatelessWidget {
  final List<dynamic> filteredHistory;
  final String? userEmail;
  final Function(int id) onDelete;
  final List<String> allUsers;
  final List<String> selectedUsers;
  final Function(String) onUserToggle;

  HistoryPage({
    required this.filteredHistory,
    required this.userEmail,
    required this.onDelete,
    required this.allUsers,
    required this.selectedUsers,
    required this.onUserToggle,
  });

  Future<void> _confirmDeleteDownload(BuildContext context, int id) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text(
            'Confirm Delete',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to delete this download?',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                onDelete(id);
              },
            ),
          ],
        );
      },
    );
  }

  void _showDetails(BuildContext context, dynamic status) {
    DateTime dateTime = DateTime.parse(status['download_date']);
    String formattedDate = DateFormat('HH:mm:ss dd-MM-yyyy').format(dateTime);
    double sizeInGB = status['size'] / (1024 * 1024 * 1024);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text(
            status['name'],
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Size: ${sizeInGB.toStringAsFixed(2)} GB', style: TextStyle(color: Colors.white)),
              Text('Description: ${status['small_description']}', style: TextStyle(color: Colors.white)),
              Text('Category: ${status['category']}', style: TextStyle(color: Colors.white)),
              Text('Downloaded by: ${status['username']}', style: TextStyle(color: Colors.white)),
              Text('Date: $formattedDate', style: TextStyle(color: Colors.white)),
              Text('State: ${status['state']}', style: TextStyle(color: Colors.white)),
            ],
          ),
          actions: [
            TextButton(
              child: Text(
                'Close',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 40, // Adjust height as needed
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: allUsers.length,
            itemBuilder: (context, index) {
              final user = allUsers[index];
              final isSelected = selectedUsers.contains(user);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4.0),
                child: ElevatedButton(
                  onPressed: () => onUserToggle(user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected ? Colors.purple.withOpacity(0.4) : Colors.grey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5), // Less rounded corners
                    ),
                  ),
                  child: Text(user),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: filteredHistory.isEmpty
              ? Center(
                  child: Text(
                    "No history available",
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : Container(
                  color: Colors.black, // Set background color to black
                  padding: const EdgeInsets.all(8.0),
                  child: ListView.builder(
                    itemCount: filteredHistory.length,
                    itemBuilder: (context, index) {
                      final status = filteredHistory[index];
                      double sizeInGB = status['size'] / (1024 * 1024 * 1024);

                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white30),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ListTile(
                          onTap: () => _showDetails(context, status),
                          title: Text(
                            status['name'],
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Size: ${sizeInGB.toStringAsFixed(2)} GB',
                                style: TextStyle(color: Colors.white),
                              ),
                              Text(
                                'Description: ${status['small_description']}',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                          trailing: status['username'] == userEmail
                              ? IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmDeleteDownload(context, status['id']),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
