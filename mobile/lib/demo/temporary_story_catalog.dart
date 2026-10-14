import 'dart:convert';
import 'package:http/http.dart' as http;
import '../story_catalog.dart';
import 'story_seeds.dart';

/// Removable test adapter. Manga metadata never becomes playable story text.
class TemporaryStoryCatalog implements StoryCatalog {
  TemporaryStoryCatalog({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  List<StoryDefinition> _stories = demoStorySeeds;
  bool offline = false;
  bool _refreshing = false;
  bool _closed = false;
  @override
  List<StoryDefinition> get stories => List.unmodifiable(_stories);
  @override
  Future<List<StoryDefinition>> refresh() async {
    if (_refreshing || _closed) return stories;
    _refreshing = true;
    final updated = <StoryDefinition>[];
    offline = false;
    try {
      for (var i = 0; i < demoStorySeeds.length; i++) {
        if (_closed) break;
        final seed = demoStorySeeds[i];
        var result = seed;
        try {
          final uri = Uri.https('api.jikan.moe', '/v4/manga',
              {'q': mangaReferenceQueries[i], 'limit': '1', 'sfw': 'true'});
          final response = await _client.get(uri).timeout(const Duration(seconds: 6));
          if (response.statusCode != 200) throw const FormatException('API unavailable');
          final data = (jsonDecode(response.body) as Map<String, dynamic>)['data'] as List;
          if (data.isNotEmpty) {
            final item = data.first as Map<String, dynamic>;
            final title = item['title'] as String;
            final url = item['url'] as String;
            final parsed = Uri.tryParse(url);
            if (parsed?.scheme != 'https' || parsed?.host != 'myanimelist.net') {
              throw const FormatException('Invalid reference URL');
            }
            result = seed.withReference(title, url);
          }
        } catch (_) {
          offline = true;
          // Offline fixture remains playable; no invented API result.
          updated.add(result);
          updated.addAll(demoStorySeeds.skip(i + 1));
          break;
        }
        updated.add(result);
        if (i < demoStorySeeds.length - 1) {
          await Future<void>.delayed(const Duration(milliseconds: 1100));
        }
      }
      if (!_closed && updated.length == demoStorySeeds.length) _stories = updated;
    } finally {
      _refreshing = false;
    }
    return stories;
  }
  void dispose() { _closed = true; _client.close(); }
}
