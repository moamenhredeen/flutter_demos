
import 'dart:async';

import 'package:flutter_demos/data/rest_countries/models/country.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CountryNotifier extends AsyncNotifier<List<Country>> {

  @override
  FutureOr<List<Country>> build() {
    return Future.value(null);
  }

}

final countries_provider = null;