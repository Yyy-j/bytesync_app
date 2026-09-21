import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bytesync/core/config/app_config.dart';
import 'package:bytesync/core/network/dio_error_mapper.dart';
import 'package:bytesync/features/meals/data/remote_meal_ai_repository.dart';

class _Adapter implements HttpClientAdapter {
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      jsonEncode({
        'name': '测试餐',
        'calories': 100,
        'protein': 10,
        'carbs': 12,
        'fat': 2,
        'dishes': [
          {'name': '测试菜', 'calories': 100},
        ],
        'source': options.path.endsWith('analyze-image') ? 'ai' : 'text',
      }),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Dio dio;
  late _Adapter adapter;
  late RemoteMealAiRepository repository;

  setUp(() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.test',
        receiveTimeout: const Duration(
          milliseconds: AppConfig.receiveTimeoutMs,
        ),
      ),
    );
    adapter = _Adapter();
    dio.httpClientAdapter = adapter;
    repository = RemoteMealAiRepository(dio, const DioErrorMapper());
  });

  test('text recognition overrides the ordinary receive timeout', () async {
    await repository.analyzeText('一碗饭');

    expect(
      adapter.lastRequest?.receiveTimeout,
      const Duration(milliseconds: AppConfig.aiReceiveTimeoutMs),
    );
  });

  test('image recognition overrides the ordinary receive timeout', () async {
    final image = File(
      '${Directory.systemTemp.path}/bytesync-ai-timeout-test.jpg',
    );
    await image.writeAsBytes([0xff, 0xd8, 0xff, 0xd9]);
    addTearDown(() async {
      if (await image.exists()) await image.delete();
    });

    await repository.analyzeImage(image.path);

    expect(
      adapter.lastRequest?.receiveTimeout,
      const Duration(milliseconds: AppConfig.aiReceiveTimeoutMs),
    );
  });
}
