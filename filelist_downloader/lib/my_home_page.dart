import 'package:filelist_downloader/app_drawer.dart';
import 'package:filelist_downloader/custom_button.dart';
import 'package:filelist_downloader/custom_textfield.dart';
import 'package:filelist_downloader/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:filelist_downloader/torrent_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart'; // Add this import for date formatting
import 'history_page.dart'; // Import the new history_page.dart file
import 'active_page.dart'; // Import the new active_page.dart file

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController _controller = TextEditingController();
  List<dynamic> _results = [];
  List<dynamic> _statuses = [];
  List<dynamic> _history = [];
  List<dynamic> _filteredHistory = [];
  String _message = '';
  int _currentIndex = 0;
  Timer? _timer;
  final User? user = FirebaseAuth.instance.currentUser;

  List<String> _activeFilters = ['downloading', 'stalledUP'];

  String _activeSort = ''; // To keep track of which sort button is active
  bool _sortAscending = true; // To keep track of the sorting order

  Map<int, String> _categories = {
    1: 'Filme SD',
    2: 'Filme DVD',
    3: 'Filme DVD-RO',
    4: 'Filme HD',
    6: 'Filme 4K',
    19: 'Filme HD-RO',
    20: 'Filme Blu-Ray',
    21: 'Seriale HD',
    23: 'Seriale SD',
    26: 'Filme 4K Blu-Ray',
    27: 'Seriale 4K',
  };

  List<int> _selectedCategories = [1, 2, 3, 4, 6, 19, 20, 21, 23, 26, 27];
  List<String> _selectedUsers = [];
  List<String> _allUsers = [];
  bool _isFirstFetch = true;

  @override
  void initState() {
    super.initState();
    _startStatusTimer();
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startStatusTimer() {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _fetchStatus();
    });
  }

  Future<void> _search(String query) async {
    final String url = 'https://filelist.io/api.php';
    final allowedCategories = _selectedCategories.join(',');
    final response = await http.get(Uri.parse(
        '$url?username=andreiyu93&passkey=4747bc183148d707c794410fec1e60b4&action=search-torrents&type=name&query=$query&category=$allowedCategories'));

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      setState(() {
        _results = json.decode(response.body);
        _message = '';
        _sortResults(); // Sort results based on the active sort criteria
      });
    } else {
      setState(() {
        _message = 'Search failed';
      });
    }
  }

  void _sortResults() {
    setState(() {
      if (_activeSort == 'size') {
        _results.sort((a, b) => _sortAscending
            ? a['size'].compareTo(b['size'])
            : b['size'].compareTo(a['size']));
      } else if (_activeSort == 'date') {
        _results.sort((a, b) {
          var aDate = a['upload_date'] ?? '';
          var bDate = b['upload_date'] ?? '';
          return _sortAscending
              ? aDate.compareTo(bDate)
              : bDate.compareTo(aDate);
        });
      }
    });
  }

  Future<void> _download(int id, String downloadLink, String torrentName, String smallDescription, int size, String category) async {
    final String flaskUrl = 'http://192.168.1.85:5000/download';
    final response = await http.post(
      Uri.parse(flaskUrl),
      body: {
        'id': id.toString(),
        'download_link': downloadLink,
        'torrent_name': torrentName,
        'small_description': smallDescription,
        'size': size.toString(),
        'category': category,
        'username': user?.email ?? 'Anonymous',
        'timestamp': DateTime.now().toString(),
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download started on server')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start download on server')),
      );
    }
  }

  Future<void> _deleteDownload(int id) async {
    final String flaskUrl = 'http://192.168.1.85:5000/delete';
    final response = await http.post(
      Uri.parse(flaskUrl),
      body: {
        'id': id.toString(),
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download deleted on server')),
      );
      _fetchStatus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete download on server')),
      );
    }
  }

  Future<void> _fetchStatus() async {
    final String flaskUrl = 'http://192.168.1.85:5000/status';
    final response = await http.get(Uri.parse(flaskUrl));

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      print('Fetched data: ${data['history']}');
      setState(() {
        _statuses = data['active'];
        _history = data['history'];
        _updateAllUsers(data['history']);
        _applyUserFilter(); // Ensure the filter is applied after fetching data
      });
      print('All users: $_allUsers');
      print('Selected users: $_selectedUsers');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch status from server')),
      );
    }
  }

  void _applyUserFilter() {
    setState(() {
      _filteredHistory = _history.where((status) => _selectedUsers.contains(status['username'])).toList();
    });
    print('Filtered history: $_filteredHistory');
  }

  void _updateAllUsers(List<dynamic> history) {
    List<String> newUsers = history.map<String>((status) => status['username'] as String).toSet().toList();
    // Add new users to _allUsers if they don't exist
    newUsers.forEach((user) {
      if (!_allUsers.contains(user)) {
        _allUsers.add(user);
      }
    });
    // Select all users by default on first fetch
    if (_isFirstFetch) {
      _selectedUsers = List.from(_allUsers);
      _isFirstFetch = false;
    }
    print('Updated all users: $_allUsers');
    _applyUserFilter();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text(
            'Logout',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Colors.white),
          ),
          actions: <Widget>[
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
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
            ),
          ],
        );
      },
    );
  }

  void _setSort(String sort) {
    setState(() {
      if (_activeSort == sort) {
        // If the same sort button is pressed again, reset sorting
        _activeSort = '';
        _search(_controller.text); // Perform search without any sort
      } else {
        _activeSort = sort;
        _sortAscending = true; // Reset to ascending when changing sort type
        _sortResults();
      }
    });
  }

  void _toggleSortOrder() {
    setState(() {
      _sortAscending = !_sortAscending;
      _sortResults();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Transform.scale(
          scale: 0.5,
          child: Image.asset(
            'lib/images/logo.png',
            color: Colors.white,
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.person, color: Colors.grey),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      drawer: AppDrawer(user: user, onLogout: _showLogoutConfirmation),
      body: _currentIndex == 0
          ? _buildSearchPage()
          : (_currentIndex == 1 ? _buildStatusPage() : _buildHistoryPage()),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent, // Removes the splash animation
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.black,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white54, // Optional: to differentiate selected and unselected icons
          showSelectedLabels: false, // Removes the label for selected items
          showUnselectedLabels: false, // Removes the label for unselected items
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.download),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: '',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchPage() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: <Widget>[
          CustomTextField(
            controller: _controller,
            hintText: 'Search',
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      setState(() {
                        _results.clear();
                      });
                    },
                  )
                : null,
          ),
          SizedBox(height: 20),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomButton(
                  text: 'Search',
                  isPressed: false,
                  isEnabled: true,
                  onPressed: () => _search(_controller.text),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomButton(
                text: 'Size',
                isPressed: _activeSort == 'size',
                isEnabled: _results.isNotEmpty,
                onPressed: () => _setSort('size'),
              ),
              SizedBox(width: 10),
              CustomButton(
                text: 'Date',
                isPressed: _activeSort == 'date',
                isEnabled: _results.isNotEmpty,
                onPressed: () => _setSort('date'),
              ),
              SizedBox(width: 10),
              CustomButton(
                text: _sortAscending ? '↑' : '↓',
                isPressed: _activeSort.isNotEmpty,
                isEnabled: _results.isNotEmpty && _activeSort.isNotEmpty,
                onPressed: _toggleSortOrder,
              ),
            ],
          ),
          SizedBox(height: 20),
          _message.isNotEmpty
              ? Text(_message)
              : Expanded(
                  child: Card(
                    color: Colors.white.withOpacity(0.1),
                    child: ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final result = _results[index];
                        double sizeInGB = result['size'] / (1024 * 1024 * 1024);
                        String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.parse(result['upload_date']));
                        return ListTile(
                          title: Text(
                            result['name'],
                            style: TextStyle(fontSize: 14, color: Colors.white),
                          ),
                          subtitle: Text(
                            'Size: ${sizeInGB.toStringAsFixed(2)} GB, Description: ${result['small_description']}, Date: $formattedDate',
                            style: TextStyle(fontSize: 12),
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TorrentDetailsPage(
                                torrent: result,
                                onDownload: () => _download(
                                  result['id'],
                                  result['download_link'],
                                  result['name'],
                                  result['small_description'],
                                  result['size'],
                                  result['category'],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildStatusPage() {
    return ActivePage(
      statuses: _statuses,
      activeFilters: _activeFilters,
      onStatusTapped: (context, status, formattedDate, sizeInGB) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(status['name']),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('State: ${status['state']}'),
                  Text('Size: ${sizeInGB.toStringAsFixed(2)} GB'),
                  Text('Description: ${status['small_description']}'),
                  Text('Category: ${status['category']}'),
                  Text('Downloaded by: ${status['username']}'),
                  Text('Date: $formattedDate'),
                ],
              ),
              actions: [
                TextButton(
                  child: Text('Close'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryPage() {
    return HistoryPage(
      filteredHistory: _filteredHistory,
      userEmail: user?.email,
      onDelete: _deleteDownload,
      allUsers: _allUsers,
      selectedUsers: _selectedUsers,
      onUserToggle: (String user) {
        setState(() {
          if (_selectedUsers.contains(user)) {
            _selectedUsers.remove(user);
          } else {
            _selectedUsers.add(user);
          }
          _applyUserFilter();
        });
      },
    );
  }
}
