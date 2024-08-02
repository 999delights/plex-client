import 'dart:async';

import 'package:filelist_downloader/structure_text_page.dart';
import 'package:filelist_downloader/torrent_page.dart';
import 'package:filelist_downloader/torrent_page2.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'FolderStatusPage.dart';
import 'login_page.dart';
import 'custom_button.dart';
import 'custom_textfield.dart';
import 'package:string_similarity/string_similarity.dart'; // Import this package for string similarity

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController _controller = TextEditingController();
  List<dynamic> _results = [];
  List<dynamic> _tvShows = [];
  List<dynamic> _seasonFolders = [];
  String _message = '';
  final User? user = FirebaseAuth.instance.currentUser;
  int _activeDownloadCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchActiveDownloads();
    _timer = Timer.periodic(Duration(seconds: 5), (timer) => _fetchActiveDownloads());
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchActiveDownloads() async {
    try {
      final response = await http.get(Uri.parse('http://numeserver.go.ro:8082/torrent_info'));
      if (response.statusCode == 200) {
        setState(() {
          final data = json.decode(response.body);
          _activeDownloadCount = data.where((torrent) => torrent['state'] == 'downloading').length;
        });
      }
    } catch (e) {
      print('An error occurred: $e');
    }
  }

  

  Future<void> _search(String query) async {
    final String url = 'https://filelist.io/api.php';
    final String allowedCategories = '1,2,3,4,6,19,20,21,23,26,27';
    final response = await http.get(Uri.parse(
        '$url?username=andreiyu93&passkey=4747bc183148d707c794410fec1e60b4&action=search-torrents&type=name&query=$query&category=$allowedCategories'));

    if (response.statusCode == 200) {
      setState(() {
        _results = json.decode(response.body);
        _message = '';
      });
    } else {
      setState(() {
        _message = 'Search failed';
      });
    }
  }


Future<void> _fetchFolderStatus() async {
    final String url = 'http://numeserver.go.ro:8082/folder_status';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      setState(() {
        _tvShows = data['tvshows'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch folder status from server')),
      );
    }
  }
Future<void> _fetchSeasonFolders(String seriesName) async {
  var seriesFolder = _tvShows.firstWhere((folder) => folder['name'] == seriesName, orElse: () => null);
  if (seriesFolder != null && seriesFolder['contents'] != null) {
    setState(() {
      _seasonFolders = List<Map<String, dynamic>>.from(seriesFolder['contents']);
    });
  } else {
    setState(() {
      _seasonFolders = [];
    });
  }
}

Future<void> _download(int id, String downloadLink, String torrentName, String smallDescription, int size) async {
  final historyStack = <String>[];
  final String? category = await _showCategoryDialog();
  if (category == null) return;

  historyStack.add('category');
  String? seriesName;
  String? season;
  bool entireSeason = false;

  while (historyStack.isNotEmpty) {
    final currentStep = historyStack.last;

    switch (currentStep) {
      case 'category':
        final String? episodeOrSeason = await _showEpisodeOrSeasonDialog();
        if (episodeOrSeason == null) {
          historyStack.removeLast();
          continue;
        }
        if (episodeOrSeason == 'entire_series') {
          // Directly proceed to download without further prompts
          historyStack.clear();
          break;
        }
        entireSeason = episodeOrSeason == 'entire_season';
        historyStack.add(episodeOrSeason);
        break;

      case 'entire_season':
      case 'single_episode':
        final bool? mainFolderExists = await _showMainFolderExistsDialog();
        if (mainFolderExists == null) {
          historyStack.removeLast();
          continue;
        }
        if (!mainFolderExists) {
          seriesName = await _showSeriesNameDialog(torrentName);
          if (seriesName == null) {
            historyStack.removeLast();
            continue;
          }
          if (!entireSeason) {
            season = await _showSeasonDialog(preFill: _extractSeasonFromEpisode(torrentName));
            if (season == null) {
              historyStack.removeLast();
              continue;
            }
          }
        } else {
          await _fetchFolderStatus(); // Fetch the folder status only if the folder exists
          seriesName = await _showSelectMainFolderDialog(torrentName: torrentName); // Pass the torrentName here
          if (seriesName == null) {
            historyStack.removeLast();
            continue;
          }

          if (!entireSeason) {
            await _fetchSeasonFolders(seriesName); // Fetch the season folders for the selected series
            final bool? seasonFolderExists = await _showSeasonFolderExistsDialog();
            if (seasonFolderExists == null) {
              historyStack.removeLast();
              continue;
            }
            if (seasonFolderExists) {
              season = await _showSelectSeasonFolderDialog(torrentName: torrentName); // Pass the torrentName here
              if (season == null) {
                historyStack.removeLast();
                continue;
              }
            } else {
              season = await _showSeasonDialog(preFill: _extractSeasonFromEpisode(torrentName));
              if (season == null) {
                historyStack.removeLast();
                continue;
              }
            }
          }
        }
        historyStack.clear();
        break;

      default:
        historyStack.clear();
    }
  }

  final body = {
    'id': id.toString(),
    'download_link': downloadLink,
    'torrent_name': torrentName,
    'small_description': smallDescription,
    'size': size.toString(),
    'category': category,
    'username': user?.email ?? 'Anonymous',
    'timestamp': DateTime.now().toString(),
    'entire_season': entireSeason.toString(),
  };

  if (seriesName != null) body['series_name'] = seriesName;
  if (season != null) body['season'] = season;

  final response = await http.post(
    Uri.parse('http://numeserver.go.ro:8082/download'),
    body: body,
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


Future<String?> _showCategoryDialog() async {
  return await showDialog<String?>(
    context: context,
    builder: (BuildContext context) {
      return CustomDialog(
        title: Text(
          'Select Category',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              title: Text(
                'Movie',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(context, 'movie'),
            ),
            ListTile(
              title: Text(
                'TV Show',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(context, 'tvshow'),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: Text(
              'Back',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () => Navigator.pop(context, null),
          ),
        ],
      );
    },
  );
}
Future<String?> _showEpisodeOrSeasonDialog() async {
  return await showDialog<String?>(
    context: context,
    builder: (BuildContext context) {
      return CustomDialog(
        title: Text(
          'Download Option',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              title: Text(
                'Entire Series',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(context, 'entire_series'),
            ),
            ListTile(
              title: Text(
                'Entire Season',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(context, 'entire_season'),
            ),
            ListTile(
              title: Text(
                'Single Episode',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(context, 'single_episode'),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: Text(
              'Back',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () => Navigator.pop(context, null),
          ),
        ],
      );
    },
  );
}
Future<bool?> _showMainFolderExistsDialog() async {
  return await showDialog<bool?>(
    context: context,
    builder: (BuildContext context) {
      return CustomDialog(
        title: Text('Main Folder Exists'),
        content: Text('Does the main folder for this TV show already exist?'),
        actions: <Widget>[
          TextButton(
            child: Text('No'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: Text('Yes'),
            onPressed: () => Navigator.pop(context, true),
          ),
          TextButton(
            child: Text('Back'),
            onPressed: () => Navigator.pop(context, null),
          ),
        ],
      );
    },
  );
}

Future<bool?> _showSeasonFolderExistsDialog() async {
  return await showDialog<bool?>(
    context: context,
    builder: (BuildContext context) {
      return CustomDialog(
        title: Text('Season Folder Exists'),
        content: Text('Does the season folder for this TV show already exist?'),
        actions: <Widget>[
          TextButton(
            child: Text('No'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: Text('Yes'),
            onPressed: () => Navigator.pop(context, true),
          ),
          TextButton(
            child: Text('Back'),
            onPressed: () => Navigator.pop(context, null),
          ),
        ],
      );
    },
  );
}


Future<String?> _showSeriesNameDialog(String torrentName) async {
  TextEditingController _controller = TextEditingController(text: _extractSeriesNameFromTorrent(torrentName));
  return await showDialog<String?>(
    context: context,
    builder: (BuildContext context) {
      return CustomDialog(
        title: Text('Series Name'),
        content: TextField(
          controller: _controller,
          decoration: InputDecoration(hintText: 'Enter series name'),
          style: TextStyle(color: Colors.white),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Back'),
            onPressed: () => Navigator.pop(context, null),
          ),
          TextButton(
            child: Text('Confirm'),
            onPressed: () => Navigator.pop(context, _controller.text),
          ),
        ],
      );
    },
  );
}

Future<String?> _showSelectMainFolderDialog({required String torrentName}) async {
  String extractedSeriesName = _extractSeriesNameFromTorrent(torrentName);

  List<String> mainFolders = _tvShows
      .where((folder) => !RegExp(r'S\d{2}').hasMatch(folder['name']))
      .map<String>((folder) => folder['name'].toString())
      .toList();

  mainFolders.sort((a, b) => b.similarityTo(extractedSeriesName).compareTo(a.similarityTo(extractedSeriesName)));

  return await showDialog<String?>(
    context: context,
    builder: (BuildContext context) {
      return CustomDialog(
        title: Text(
          'Select Main Folder',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: mainFolders.map((folder) {
              return ListTile(
                title: Text(
                  folder,
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.pop(context, folder),
              );
            }).toList(),
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(
              'Back',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () => Navigator.pop(context, null),
          ),
        ],
      );
    },
  );
}
Future<String?> _showSelectSeasonFolderDialog({String? preFill, required String torrentName}) async {
  RegExp episodePattern = RegExp(r'S\d{2}E\d{2}', caseSensitive: false);
  String? extractedSeasonName = _extractSeasonFromEpisode(torrentName);

  List<String> seasonFolders = _seasonFolders
      .where((folder) => !episodePattern.hasMatch(folder['name']))
      .map<String>((folder) => folder['name'].toString())
      .toList();

  if (extractedSeasonName != null) {
    seasonFolders.sort((a, b) => b.similarityTo(extractedSeasonName).compareTo(a.similarityTo(extractedSeasonName)));
  }

  if (preFill != null && !seasonFolders.contains(preFill)) {
    seasonFolders.insert(0, preFill);
  } else if (preFill != null && seasonFolders.contains(preFill)) {
    seasonFolders.remove(preFill);
    seasonFolders.insert(0, preFill);
  }

  return await showDialog<String?>(
    context: context,
    builder: (BuildContext context) {
      return CustomDialog(
        title: Text(
          'Select Season Folder',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: seasonFolders.map((folder) {
              return ListTile(
                title: Text(
                  folder,
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.pop(context, folder),
              );
            }).toList(),
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(
              'Back',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () => Navigator.pop(context, null),
          ),
        ],
      );
    },
  );
}

Future<String?> _showSeasonDialog({String? preFill}) async {
  TextEditingController _controller = TextEditingController(text: preFill);
  return await showDialog<String?>(
    context: context,
    builder: (BuildContext context) {
      return CustomDialog(
        title: Text('Season'),
        content: TextField(
          controller: _controller,
          decoration: InputDecoration(hintText: 'Enter season (e.g., Season 1)'),
          style: TextStyle(color: Colors.white),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Back'),     
            onPressed: () => Navigator.pop(context, null),
          ),
          TextButton(
            child: Text('Confirm'),
            onPressed: () => Navigator.pop(context, _controller.text),
          ),
        ],
      );
    },
  );
}



String _extractSeriesNameFromTorrent(String torrentName) {
  RegExp regex = RegExp(r'^(.*?)(\.S\d{2}E\d{2}\.|\.S\d{2}\.|\.Season\d+)', caseSensitive: false);
  Match? match = regex.firstMatch(torrentName);
  if (match != null) {
    return match.group(1)!.replaceAll('.', ' ').trim();
  }
  return torrentName.split('.')[0].replaceAll('.', ' ').trim();
}

String _extractSeasonFromEpisode(String torrentName) {
  RegExp regex = RegExp(r'S(\d{2})', caseSensitive: false);
  Match? match = regex.firstMatch(torrentName);
  if (match != null) {
    return 'Season ${int.parse(match.group(1)!)}';
  }
  return '';
}



  Future<void> _refreshPlexLibraries() async {
    final response = await http.post(
      Uri.parse('http://numeserver.go.ro:8082/refresh_plex'),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Plex libraries refreshed successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to refresh Plex libraries')),
      );
    }
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
      return CustomDialog(
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
  void _navigateToDetails(BuildContext context, dynamic torrent) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TorrentDetailsPage(
          torrent: torrent,
          onDownload: () => _download(
            torrent['id'],
            torrent['download_link'],
            torrent['name'],
            torrent['small_description'],
            torrent['size'],
          ),
        ),
      ),
    );
  }

  void _navigateToTorrentStatus(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TorrentStatusPage()),
    );
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
            icon: Icon(Icons.menu, color: Colors.grey),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.cloud_download, color: Colors.white),
                if (_activeDownloadCount > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 7,
                      backgroundColor: Colors.red,
                      child: Text(
                        '$_activeDownloadCount',
                        style: TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              _navigateToTorrentStatus(context);
            },
          ),
          IconButton(
            icon: Icon(Icons.folder, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FolderStatusPage()),
              );
            },
          ),
        ],
      ),
      drawer: AppDrawer(
        user: user,
        onLogout: _showLogoutConfirmation,
        onRefresh: _refreshPlexLibraries,
       onViewStructure: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => StructureTextPage()),
          );
        },
      ),
      body: Padding(
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
            CustomButton(
              text: 'Search',
              isPressed:              false,
              isEnabled: true,
              onPressed: () => _search(_controller.text),
            ),
            SizedBox(height: 20),
            _message.isNotEmpty
                ? Text(
                    _message,
                    style: TextStyle(color: Colors.grey),
                  )
                : Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey, width: 1),
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.all(8),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final result = _results[index];
                          double sizeInGB = result['size'] / (1024 * 1024 * 1024);
                          String formattedDate = DateFormat('yyyy-MM-dd')
                              .format(DateTime.parse(result['upload_date']));
                          return InkWell(
                            onTap: () => _navigateToDetails(context, result),
                            child: ListTile(
                              title: Text(
                                result['name'],
                                style: TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                'Size: ${sizeInGB.toStringAsFixed(2)} GB, Date: $formattedDate',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
          ],
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}

class AppDrawer extends StatelessWidget {
  final User? user;
  final VoidCallback onLogout;
  final VoidCallback onRefresh;
  final VoidCallback onViewStructure;

  AppDrawer({
    required this.user,
    required this.onLogout,
    required this.onRefresh,
    required this.onViewStructure,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.grey[900],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Column(
            children: [
              Theme(
                data: Theme.of(context).copyWith(
                  dividerTheme: const DividerThemeData(
                    color: Colors.transparent,
                  ),
                ),
                child: DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Transform.scale(
                    scale: 1.0,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60.0),
                      child: Image.asset(
                        'lib/images/logo.png',
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Divider(color: Colors.grey[800]),
              ),
              ListTile(
                leading: Icon(
                  Icons.refresh,
                  color: Colors.white,
                ),
                title: Text(
                  'Refresh Plex Libraries',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onRefresh();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.text_snippet,
                  color: Colors.white,
                ),
                title: Text(
                  'TV Shows Structure',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onViewStructure();
                },
              ),
            ],
          ),
          Column(
            children: [
              ListTile(
                leading: const Icon(Icons.email, color: Colors.grey, size: 18),
                title: Text(
                  user?.email ?? 'Email',
                  style: const TextStyle(fontSize: 10.0, color: Colors.white),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 25.0),
                child: ListTile(
                  leading: const Icon(
                    Icons.logout,
                    color: Colors.white,
                    size: 18.0,
                  ),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.0,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onLogout();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class CustomDialog extends StatelessWidget {
  final Widget title;
  final Widget content;
  final List<Widget> actions;

  CustomDialog({
    required this.title,
    required this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black, // Set background color to black
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // Rounded corners
        side: BorderSide(color: Colors.grey[800]!, width: 1), // Border color and width
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            color: Colors.black,
            padding: EdgeInsets.all(16.0),
            child: DefaultTextStyle(
              style: TextStyle(color: Colors.white),
              child: title,
            ),
          ),
          Container(
            color: Colors.black,
            padding: EdgeInsets.all(16.0),
            child: DefaultTextStyle(
              style: TextStyle(color: Colors.white),
              child: content,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: actions,
          ),
        ],
      ),
    );
  }
}