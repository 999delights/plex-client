import 'package:bliss/my_home_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class FolderStatusPage extends StatefulWidget {
  @override
  _FolderStatusPageState createState() => _FolderStatusPageState();
}

class _FolderStatusPageState extends State<FolderStatusPage> {
  List<dynamic> _movies = [];
  List<dynamic> _tvShows = [];
  String _filter = 'all';
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final String adminEmail = 'serverdeservermafiot@gmail.com';
  User? user;
  String? _loadingFolderName;

  @override
  void initState() {
    super.initState();
    _fetchUserEmail();
    _fetchFolderStatus();
  }

  void _fetchUserEmail() {
    final User? firebaseUser = FirebaseAuth.instance.currentUser;
    setState(() {
      user = firebaseUser;
    });
  }

  Future<void> _fetchFolderStatus() async {
    final String url = 'http://numeserver.go.ro:8082/folder_status';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      setState(() {
        _movies = data['movies'];
        _tvShows = data['tvshows'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch folder status from server')),
      );
    }
  }

  Future<void> _deleteFolder(String folderName) async {
    setState(() {
      _loadingFolderName = folderName;
    });

    try {
      final response = await http.post(
        Uri.parse('http://numeserver.go.ro:8082/delete_folder'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'folder_name': folderName}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Folder deleted successfully')),
        );
        _fetchFolderStatus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete folder')),
        );
      }
    } catch (e) {
      print('An error occurred while deleting the folder: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred')),
      );
    } finally {
      setState(() {
        _loadingFolderName = null;
      });
    }
  }

  void _showDeleteConfirmationDialog(String folderName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this folder?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteFolder(folderName);
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }
double _calculateTotalMoviesSize() {
  return _movies.fold(0.0, (sum, movie) => sum + (movie['size'] as double));
}

double _calculateTotalTvShowsSize() {
  return _tvShows.fold(0.0, (sum, tvShow) => sum + (tvShow['size'] as double));
}

double _calculateTotalAllSize() {
  return _calculateTotalMoviesSize() + _calculateTotalTvShowsSize();
}
  List<dynamic> _filterItems(List<dynamic> items) {
    return items.where((item) {
      final itemName = item['name'].toLowerCase();
      final searchWords = _searchQuery.split(' ').where((word) => word.isNotEmpty).toList();
      return searchWords.every((searchWord) => itemName.contains(searchWord));
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> displayedItems = _filter == 'movies'
        ? _filterItems(_movies.map((movie) => {...movie, 'category': 'Movie'}).toList())
        : _filter == 'tvshows'
            ? _filterItems(_tvShows.map((tvShow) => {...tvShow, 'category': 'TV Show'}).toList())
            : _filterItems([
                ..._movies.map((movie) => {...movie, 'category': 'Movie'}),
                ..._tvShows.map((tvShow) => {...tvShow, 'category': 'TV Show'}),
              ]);

    displayedItems.sort((a, b) => DateTime.parse(b['creation_time']).compareTo(DateTime.parse(a['creation_time'])));

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          onChanged: _updateSearchQuery,
          decoration: InputDecoration(
            hintText: 'Search...',
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
            icon: Icon(Icons.search, color: Colors.white),
          ),
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String result) {
              setState(() {
                _filter = result;
              });
            },
            icon: Icon(Icons.filter_list, color: Colors.white),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'all',
                child: Text('All', style: TextStyle(color: Colors.grey)),
              ),
              PopupMenuItem<String>(
                value: 'movies',
                child: Text('Movies', style: TextStyle(color: Colors.grey)),
              ),
              PopupMenuItem<String>(
                value: 'tvshows',
                child: Text('TV Shows', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildHeader(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchFolderStatus,
              child: ListView.builder(
                itemCount: displayedItems.length,
                itemBuilder: (context, index) {
                  final item = displayedItems[index];
                  final bool isLoading = item['name'] == _loadingFolderName;

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      color: item['type'] == 'directory' ? Colors.yellow.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
                      child: ListTile(
                        title: isLoading
                            ? Row(
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(width: 10),
                                  Text('Deleting...', style: TextStyle(color: Colors.white)),
                                ],
                              )
                            : Text(
                                item['name'],
                                style: TextStyle(color: Colors.white),
                              ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Size: ${item['size']} GB',
                              style: TextStyle(color: Colors.white54),
                            ),
                            Text(
                              'Created: ${item['creation_time']}',
                              style: TextStyle(color: Colors.white54),
                            ),
                            Text(
                              item['category'],
                              style: TextStyle(color: Colors.orange.withOpacity(0.5), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        trailing: user?.email == adminEmail && item['type'] == 'directory' && !isLoading
                            ? IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _showDeleteConfirmationDialog(item['name']),
                              )
                            : null,
                        onTap: () {
                          if (item['type'] == 'directory') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SubFolderPage(
                                  folderName: item['name'],
                                  contents: item['contents'],
                                  fetchFolderStatus: _fetchFolderStatus,
                                ),
                              ),
                            );
                          }
                        },
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

Widget _buildHeader() {
  // Calculate sizes
  final double totalMoviesSize = _calculateTotalMoviesSize();
  final double totalTvShowsSize = _calculateTotalTvShowsSize();
  final double totalSize = _calculateTotalAllSize();
  final double maxSize = 2000.0; // 2 TB in GB

  // Convert numbers to strings
  final String totalMoviesSizeStr = totalMoviesSize.toStringAsFixed(0); // Two decimal places
  final String totalTvShowsSizeStr = totalTvShowsSize.toStringAsFixed(0); // Two decimal places
  final String totalSizeStr = totalSize.toStringAsFixed(0); // Two decimal places
  final String maxSizeStr = maxSize.toStringAsFixed(0); // Two decimal places


  // Header text based on the filter
  String headerText;
  if (_filter == 'all') {
    headerText = '${_movies.length} Movies, ${_tvShows.length} TV Shows';
  } else if (_filter == 'movies') {
    headerText = '${_movies.length} Movies';
  } else {
    headerText = '${_tvShows.length} TV Shows';
  }

  // Create the header widget with length and space usage
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Length info
        Text(
          headerText,
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        // Space usage info
        Text(
          _filter == 'all'
              ? '${totalSizeStr} / ${maxSizeStr} GB'
              : _filter == 'movies'
                  ? '${totalMoviesSizeStr} GB'
                  : '${totalTvShowsSizeStr} GB',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}
}

class SubFolderPage extends StatelessWidget {
  final String folderName;
  final List<dynamic> contents;
  final Future<void> Function() fetchFolderStatus;

  SubFolderPage({required this.folderName, required this.contents, required this.fetchFolderStatus});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(folderName),
      ),
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        onRefresh: fetchFolderStatus,
        child: ListView.builder(
          itemCount: contents.length,
           itemBuilder: (context, index) {
            final item = contents[index];
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                color: item['type'] == 'directory' ? Colors.yellow.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
                child: ListTile(
                  title: Text(
                    item['name'],
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Size: ${item['size']} GB',
                        style: TextStyle(color: Colors.white54),
                      ),
                      Text(
                        'Created: ${item['creation_time']}',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                  onTap: () {
                    if (item['type'] == 'directory') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubFolderPage(
                            folderName: item['name'],
                            contents: item['contents'],
                            fetchFolderStatus: fetchFolderStatus,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}