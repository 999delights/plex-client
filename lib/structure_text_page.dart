import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StructureTextPage extends StatefulWidget {
  @override
  _StructureTextPageState createState() => _StructureTextPageState();
}

class _StructureTextPageState extends State<StructureTextPage> {
  List<dynamic> _structureList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStructureText();
  }

  Future<void> _fetchStructureText() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse('http://numeserver.go.ro:8082/get_structure_text'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _structureList = _parseStructureText(data['content']);
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch structure text from server')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<dynamic> _parseStructureText(String text) {
    List<dynamic> structure = [];
    List<String> lines = text.split('\n');
    Map<String, dynamic> currentSeries = {};
    Map<String, dynamic> currentSeason = {};

    for (String line in lines) {
      if (line.startsWith('[SERIES]')) {
        currentSeries = {
          'title': line.replaceFirst('[SERIES]', '').trim(),
          'type': 'series',
          'children': [],
        };
        structure.add(currentSeries);
      } else if (line.startsWith('  [SEASON]')) {
        currentSeason = {
          'title': line.replaceFirst('[SEASON]', '').trim(),
          'type': 'season',
          'children': [],
        };
        currentSeries['children'].add(currentSeason);
      } else if (line.startsWith('    [EPISODE]')) {
        Map<String, dynamic> episode = {
          'title': line.replaceFirst('[EPISODE]', '').trim(),
          'type': 'episode',
        };
        currentSeason['children'].add(episode);
      }
    }
    return structure;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Structure Text'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchStructureText,
              child: _structureList.isNotEmpty
                  ? ListView.builder(
                      padding: EdgeInsets.all(16.0),
                      itemCount: _structureList.length,
                      itemBuilder: (context, index) {
                        return _buildSeriesItem(_structureList[index]);
                      },
                    )
                  : Center(child: Text('No structure data found')),
            ),
      backgroundColor: Colors.black,
    );
  }

  Widget _buildSeriesItem(Map<String, dynamic> series) {
    return ExpansionTile(
      title: Text(
        series['title'],
        style: TextStyle(color: Colors.white),
      ),
      children: series['children']
          .map<Widget>((season) => _buildSeasonItem(season))
          .toList(),
    );
  }

  Widget _buildSeasonItem(Map<String, dynamic> season) {
    return ExpansionTile(
      title: Text(
        season['title'],
        style: TextStyle(color: Colors.white70),
      ),
      children: season['children']
          .map<Widget>((episode) => _buildEpisodeItem(episode))
          .toList(),
    );
  }

  Widget _buildEpisodeItem(Map<String, dynamic> episode) {
    return ListTile(
      title: Text(
        episode['title'],
        style: TextStyle(color: Colors.white54),
      ),
    );
  }
}