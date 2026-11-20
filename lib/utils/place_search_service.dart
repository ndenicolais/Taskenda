// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

/// Place suggestions for the event location field, from Google Places
/// Autocomplete through the `searchPlaces` Cloud Function (which holds the
/// API key). Only the text typed in the location field is sent, with the
/// app language and the device country, and only while typing in it.
class PlaceSearchService {
  PlaceSearchService._();

  /// Same region as `setGlobalOptions` in `functions/index.js`.
  static const _region = 'europe-west1';

  /// Up to 5 places (business names included) matching [query] (at least 3
  /// characters), in [languageCode] when available. Silent on errors
  /// (offline, timeout, signed out): it is only a typing aid, an empty list
  /// leaves the free text as is.
  static Future<List<String>> search(String query, String languageCode) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) return const [];
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) return const [];
      final projectId = Firebase.app().options.projectId;
      final country =
          WidgetsBinding.instance.platformDispatcher.locale.countryCode;
      // Callable protocol over plain HTTPS: {data} in, {result} out.
      final response = await http
          .post(
            Uri.parse(
              'https://$_region-$projectId.cloudfunctions.net/searchPlaces',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'data': {
                'query': trimmed,
                'language': languageCode,
                if (country != null) 'region': country.toUpperCase(),
              },
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return const [];
      final results = (jsonDecode(response.body) as Map)['result']?['results'];
      if (results is! List) return const [];
      return results.whereType<String>().toSet().toList();
    } catch (_) {
      return const [];
    }
  }
}
