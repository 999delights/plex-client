import 'dart:async';  // Import this package for Timer
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TorrentStatusPage extends StatefulWidget {
  @override
  _TorrentStatusPageState createState() => _TorrentStatusPageState();
}

class _TorrentStatusPageState extends State<TorrentStatusPage> {
  List<dynamic> _torrentData = [];
  Set<String> _loadingTorrents = Set<String>();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchTorrentData();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      _fetchTorrentData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchTorrentData() async {
    try {
      final response = await http.get(Uri.parse('http://numeserver.go.ro:8082/torrent_info'));
      if (response.statusCode == 200) {
        setState(() {
          _torrentData = json.decode(response.body).where((torrent) {
            return torrent['state'] == 'downloading' || torrent['state'] == 'pausedDL';
          }).toList();
        });
      } else {
        print('Failed to load torrent data: ${response.statusCode}');
        print('Response body: ${response.body}');
        setState(() {
          _torrentData = [];
        });
      }
    } catch (e) {
      print('An error occurred: $e');
      setState(() {
        _torrentData = [];
      });
    }
  }

  Future<void> _pauseTorrent(String name) async {
    setState(() {
      _loadingTorrents.add(name);
    });

    try {
      final response = await http.post(
        Uri.parse('http://numeserver.go.ro:8082/pause_torrent'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': name}),
      );
      String message = response.statusCode == 200
          ? 'Torrent paused successfully'
          : 'Failed to pause torrent';
      print(message);

      // Show snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(seconds: 2),
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _updateTorrentState(name, 'pausedDL');
        });
      }
    } catch (e) {
      print('An error occurred while pausing the torrent: $e');
    } finally {
      setState(() {
        _loadingTorrents.remove(name);
      });
    }
  }

  Future<void> _resumeTorrent(String name) async {
    setState(() {
      _loadingTorrents.add(name);
    });

    try {
      final response = await http.post(
        Uri.parse('http://numeserver.go.ro:8082/resume_torrent'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': name}),
      );
      String message = response.statusCode == 200
          ? 'Torrent resumed successfully'
          : 'Failed to resume torrent';
      print(message);

      // Show snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(seconds: 2),
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _updateTorrentState(name, 'downloading');
        });
      }
    } catch (e) {
      print('An error occurred while resuming the torrent: $e');
    } finally {
      setState(() {
        _loadingTorrents.remove(name);
      });
    }
  }

  void _updateTorrentState(String name, String newState) {
    final index = _torrentData.indexWhere((torrent) => torrent['name'] == name);
    if (index != -1) {
      setState(() {
        _torrentData[index]['state'] = newState;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Torrent Status'),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTorrentData,
        child: _torrentData.isEmpty
            ? ListView(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No active torrents',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: _torrentData.length,
                itemBuilder: (context, index) {
                  final torrent = _torrentData[index];
                  final double dlspeed = torrent['download_speed'] ?? 0.0;
                  final double upspeed = torrent['upload_speed'] ?? 0.0;
                  final bool isDownloading = torrent['state'] == 'downloading';
                  final bool isLoading = _loadingTorrents.contains(torrent['name']);
                  final double progress = torrent['progress'];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Stack(
                      children: [
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: isDownloading ? Colors.green.withOpacity(0.2) : Colors.yellow.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        Positioned.fill(
                          child: FractionallySizedBox(
                            widthFactor: progress,
                            alignment: Alignment.centerLeft,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDownloading ? Colors.green.withOpacity(0.4) : Colors.yellow.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${dlspeed.toStringAsFixed(2)} MB/s',
                                      style: TextStyle(color: Colors.white, fontSize: 16),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '${(progress * 100).toStringAsFixed(2)}%',
                                      style: TextStyle(color: Colors.white, fontSize: 16),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  torrent['name'],
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 15),
                                Text(
                                  '${(torrent['downloaded'] / (1024 * 1024 * 1024)).toStringAsFixed(2)} / ${(torrent['size'] / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            width: 32, // Small width
                            height: 32, // Small height
                            decoration: BoxDecoration(
                              color: Colors.black,
                              border: Border.all(color: Colors.black),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: isLoading
                                ? CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  )
                                : IconButton(
                                    iconSize: 16, // Smaller icon size
                                    padding: EdgeInsets.all(0), // No padding
                                    icon: Icon(
                                      isDownloading ? Icons.pause : Icons.play_arrow,
                                      color: isDownloading ? Colors.red : Colors.green,
                                    ),
                                    onPressed: () {
                                      if (isDownloading) {
                                        _pauseTorrent(torrent['name']);
                                      } else {
                                        _resumeTorrent(torrent['name']);
                                      }
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      backgroundColor: Colors.black,
    );
  }
}