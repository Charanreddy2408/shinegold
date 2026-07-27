import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shine_gold/shared/utils/geocoding_service.dart';

/// Fails every request — stands in for a Nominatim 403 / offline device, the
/// condition that used to make "Confirm boundary" throw and silently do nothing.
class _AlwaysFailingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      response: Response<void>(requestOptions: options, statusCode: 403),
      message: 'Forbidden',
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Serves the backend proxy shape (`/api/v1/geo/reverse`) and 403s anything
/// else, mirroring a device that can reach our API but not Nominatim.
class _ProxyOnlyAdapter implements HttpClientAdapter {
  final requestedPaths = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestedPaths.add(options.uri.path);
    if (!options.uri.path.endsWith('/api/v1/geo/reverse')) {
      throw DioException(
        requestOptions: options,
        response: Response<void>(requestOptions: options, statusCode: 403),
      );
    }
    return ResponseBody.fromString(
      jsonEncode({'display_name': 'Sultan Bazar, Hyderabad, Telangana, India'}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  const point = LatLng(17.385, 78.4867);

  Dio apiDio(HttpClientAdapter adapter) =>
      Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = adapter;

  test('reverseGeocode returns null instead of throwing when every host fails',
      () async {
    final service = GeocodingService(dio: apiDio(_AlwaysFailingAdapter()));
    await expectLater(service.reverseGeocode(point), completion(isNull));
  });

  test('reverseGeocode uses the backend proxy before third-party Nominatim',
      () async {
    final adapter = _ProxyOnlyAdapter();
    final service = GeocodingService(dio: apiDio(adapter));

    expect(
      await service.reverseGeocode(point),
      'Sultan Bazar, Hyderabad, Telangana, India',
    );
    expect(adapter.requestedPaths, ['/api/v1/geo/reverse']);
  });
}
