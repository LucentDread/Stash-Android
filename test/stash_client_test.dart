import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stash_android/api/stash_client.dart';
import 'package:stash_android/api/stash_repository.dart';

void main() {
  group('StashClient', () {
    test('normalizes server URLs', () {
      expect(StashClient.normalizeUrl('192.168.1.2:9999/'),
          'http://192.168.1.2:9999');
      expect(StashClient.normalizeUrl(' https://stash.example.com// '),
          'https://stash.example.com');
    });

    test('mediaUrl resolves relative paths and adds the API key', () {
      final c = StashClient(serverUrl: 'http://host:9999', apiKey: 'k');
      expect(c.mediaUrl('/scene/1/screenshot?t=2'),
          'http://host:9999/scene/1/screenshot?t=2&apikey=k');
      expect(c.mediaUrl('http://host:9999/scene/1/stream?apikey=k'),
          'http://host:9999/scene/1/stream?apikey=k');
      expect(c.mediaUrl(null), isNull);
    });

    test('mediaUrl leaves URLs untouched without an API key', () {
      final c = StashClient(serverUrl: 'http://host:9999', apiKey: '  ');
      expect(c.apiKey, isNull);
      expect(c.mediaUrl('http://host:9999/performer/3/image'),
          'http://host:9999/performer/3/image');
    });

    test('sends the API key header and returns data', () async {
      late http.Request sent;
      final c = StashClient(
        serverUrl: 'http://host:9999',
        apiKey: 'secret',
        client: MockClient((req) async {
          sent = req;
          return http.Response(
              jsonEncode({
                'data': {
                  'version': {'version': 'v0.28.1'}
                }
              }),
              200);
        }),
      );
      expect(await StashRepository(c).version(), 'v0.28.1');
      expect(sent.url.toString(), 'http://host:9999/graphql');
      expect(sent.headers['ApiKey'], 'secret');
    });

    test('surfaces GraphQL errors', () async {
      final c = StashClient(
        serverUrl: 'http://host',
        client: MockClient((_) async => http.Response(
            jsonEncode({
              'errors': [
                {'message': 'boom'}
              ]
            }),
            200)),
      );
      expect(c.query('query { x }'),
          throwsA(isA<StashException>().having((e) => e.message, 'message', 'boom')));
    });

    test('reports authentication failures', () async {
      final c = StashClient(
        serverUrl: 'http://host',
        client: MockClient((_) async => http.Response('', 401)),
      );
      expect(c.query('query { x }'), throwsA(isA<StashException>()));
    });
  });

  test('EntityFilter builds Stash criteria', () {
    expect(const EntityFilter.performer('4').toCriterion(), {
      'performers': {
        'value': ['4'],
        'modifier': 'INCLUDES',
      },
    });
    expect(const EntityFilter.studio('2').toCriterion(), {
      'studios': {
        'value': ['2'],
        'modifier': 'INCLUDES',
        'depth': -1,
      },
    });
  });
}
