import 'dart:convert';

import 'package:http/http.dart' as http;

import '../l10n/l10n.dart';

/// Error raised when the Stash server answers with GraphQL errors or a bad
/// HTTP status.
class StashException implements Exception {
  StashException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Minimal GraphQL client for the Stash API (`<server>/graphql`).
///
/// Authentication uses Stash's API key (Settings > Security > API Key), sent
/// in the `ApiKey` header and appended as `apikey` to media URLs.
class StashClient {
  StashClient({required String serverUrl, String? apiKey, http.Client? client})
    : serverUrl = normalizeUrl(serverUrl),
      apiKey = (apiKey == null || apiKey.trim().isEmpty) ? null : apiKey.trim(),
      _http = client ?? http.Client();

  final String serverUrl;
  final String? apiKey;
  final http.Client _http;

  /// Told whether the server answered (true) or could not be reached.
  void Function(bool reachable)? onReachability;

  static String normalizeUrl(String url) {
    var u = url.trim();
    if (u.isEmpty) return u;
    if (!u.startsWith('http://') && !u.startsWith('https://')) {
      u = 'http://$u';
    }
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  Uri get graphqlUri => Uri.parse('$serverUrl/graphql');

  Map<String, String> get authHeaders =>
      apiKey == null ? const {} : {'ApiKey': apiKey!};

  /// Makes a media URL returned by Stash usable by image/video widgets:
  /// resolves relative paths against the server and adds the API key.
  String? mediaUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    var uri = Uri.parse(url);
    if (!uri.hasScheme) {
      uri = Uri.parse(serverUrl).resolveUri(uri);
    }
    if (apiKey != null && !uri.queryParameters.containsKey('apikey')) {
      uri = uri.replace(
        queryParameters: {...uri.queryParameters, 'apikey': apiKey!},
      );
    }
    return uri.toString();
  }

  Future<Map<String, dynamic>> query(
    String document, {
    Map<String, dynamic>? variables,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final http.Response res;
    try {
      res = await _http
          .post(
            graphqlUri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              ...authHeaders,
            },
            body: jsonEncode({'query': document, 'variables': ?variables}),
          )
          .timeout(timeout);
    } catch (e) {
      onReachability?.call(false);
      throw StashException(tr.serverUnreachable('$e'));
    }
    // A reverse proxy answering for a stopped Stash: unreachable too.
    if (res.statusCode >= 500) {
      onReachability?.call(false);
      throw StashException(tr.httpError(res.statusCode));
    }
    onReachability?.call(true);

    if (res.statusCode == 401 || res.statusCode == 403) {
      throw StashException(tr.accessDenied(res.statusCode));
    }
    if (res.statusCode != 200) {
      throw StashException(tr.httpError(res.statusCode));
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } on FormatException {
      throw StashException(tr.invalidResponse);
    }
    final errors = body['errors'];
    if (errors is List && errors.isNotEmpty) {
      throw StashException(
        errors.map((e) => (e as Map)['message'] ?? e.toString()).join('\n'),
      );
    }
    return (body['data'] as Map<String, dynamic>?) ?? const {};
  }

  void close() => _http.close();
}
