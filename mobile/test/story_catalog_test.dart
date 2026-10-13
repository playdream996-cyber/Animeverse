import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:animeverse/demo/temporary_story_catalog.dart';
import 'package:animeverse/demo/story_seeds.dart';
import 'package:animeverse/story_session.dart';

void main() {
  test('five unique original fixtures have playable openings and choices', () {
    expect(demoStorySeeds.length, 5);
    expect(demoStorySeeds.map((s) => s.id).toSet().length, 5);
    for (final story in demoStorySeeds) {
      final session = StorySession(story.title, story.character, story: story);
      expect(session.turns.first.text, story.opening);
      session.send(story.choices.first);
      session.finishReply();
      expect(session.turns.last.text, story.responses.first);
      expect(story.sourceUrl, startsWith('https://www.gutenberg.org/'));
      session.dispose();
    }
  });
  test('API failure keeps offline stories intact', () async {
    final catalog = TemporaryStoryCatalog(client: MockClient((_) async => http.Response('', 429)));
    final result = await catalog.refresh();
    expect(result.length, 5);
    expect(catalog.offline, isTrue);
    expect(result.first.referenceTitle, isNull);
    catalog.dispose();
  });
  test('API metadata is retained separately and cannot overwrite original prose', () async {
    var calls = 0;
    final catalog = TemporaryStoryCatalog(client: MockClient((request) async {
      expect(request.url.host, 'api.jikan.moe');
      calls++;
      if (calls > 1) return http.Response('', 503);
      return http.Response(jsonEncode({'data': [{
        'title': 'Reference edition', 'url': 'https://myanimelist.net/manga/123',
        'synopsis': 'Never import this text'
      }]}), 200);
    }));
    final result = await catalog.refresh();
    expect(result.first.referenceTitle, 'Reference edition');
    expect(result.first.opening, demoStorySeeds.first.opening);
    expect(result.first.opening, isNot(contains('Never import')));
    catalog.dispose();
  });
}
