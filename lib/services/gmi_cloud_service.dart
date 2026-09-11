import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/gmi_cloud_config.dart';

/// GMI Cloud 服务。
///
/// 该服务会把 GMI Cloud API key 加入到每个请求头中，便于项目内部其他模块调用。
class GmiCloudService {
  GmiCloudService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  String get baseUrl => GmiCloudConfig.baseUrl;
  String get apiKey => GmiCloudConfig.apiKey;
  bool get isConfigured => GmiCloudConfig.isConfigured;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      };

  Uri _buildUri(String path, [Map<String, dynamic>? query]) {
    final base = Uri.parse(baseUrl);
    return base.replace(
      path: base.path.endsWith('/')
          ? '${base.path}${path.replaceFirst('/', '')}'
          : '${base.path}${path.startsWith('/') ? path : '/$path'}',
      queryParameters: query?.map((key, value) => MapEntry(key, '$value')),
    );
  }

  Future<http.Response> postJson(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    if (!isConfigured) {
      throw StateError('GMI Cloud service is not configured.');
    }

    final uri = _buildUri(path);
    return _httpClient.post(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );
  }

  Future<http.Response> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    if (!isConfigured) {
      throw StateError('GMI Cloud service is not configured.');
    }

    final uri = _buildUri(path, query);
    return _httpClient.get(
      uri,
      headers: _headers,
    );
  }

  Future<bool> sendTelemetry(Map<String, dynamic> payload) async {
    final response = await postJson('/telemetry', body: payload);
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  Future<Map<String, dynamic>?> fetchStatus() async {
    final response = await getJson('/status');
    if (response.statusCode != 200) return null;
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
