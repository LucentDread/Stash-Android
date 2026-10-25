/// Converts the filters saved by Stash's web UI into GraphQL filters.
///
/// The web UI stores each criterion in its own format (`{value, modifier}`
/// with labels: `{"items": [{"id", "label"}], "depth"}`, "1080p",
/// "Female"…), not as the API's input. The expected input is read from the
/// server's schema (introspection), so the conversion follows the server's
/// version; criteria it cannot map are skipped.
class FilterSchema {
  FilterSchema(this._types);

  /// From the result of [introspectionQuery].
  factory FilterSchema.fromIntrospection(Map<String, dynamic> data) {
    final types = <String, _Type>{};
    for (final t in (data['__schema'] as Map)['types'] as List) {
      final m = (t as Map).cast<String, dynamic>();
      types[m['name'] as String] = _Type(
        m['kind'] as String,
        {
          for (final f in m['inputFields'] as List? ?? const [])
            (f as Map)['name'] as String: _TypeRef.fromJson(
              (f['type'] as Map).cast<String, dynamic>(),
            ),
        },
        [
          for (final e in m['enumValues'] as List? ?? const [])
            (e as Map)['name'] as String,
        ],
      );
    }
    return FilterSchema(types);
  }

  static const introspectionQuery = '''
    query FilterTypes {
      __schema {
        types {
          name kind
          inputFields { name type { ...T } }
          enumValues { name }
        }
      }
    }
    fragment T on __Type {
      kind name ofType { kind name ofType { kind name ofType { kind name } } }
    }''';

  final Map<String, _Type> _types;

  /// Web UI labels of resolutions (ui/v2.5/src/utils/resolution.ts).
  static const _resolutions = {
    '144p': 'VERY_LOW',
    '240p': 'LOW',
    '360p': 'R360P',
    '480p': 'STANDARD',
    '540p': 'WEB_HD',
    '720p': 'STANDARD_HD',
    '1080p': 'FULL_HD',
    '1440p': 'QUAD_HD',
    '1920p': 'VR_HD',
    '4k': 'FOUR_K',
    '5k': 'FIVE_K',
    '6k': 'SIX_K',
    '7k': 'SEVEN_K',
    '8k': 'EIGHT_K',
    'huge': 'HUGE',
  };

  /// Converts [saved] (a saved filter's `object_filter`) into an input of
  /// type [typeName] (`SceneFilterType`…). Keys that could not be
  /// converted are added to [skipped].
  Map<String, dynamic> convert(
    String typeName,
    Map<String, dynamic> saved, {
    List<String>? skipped,
  }) {
    final fields = _types[typeName]?.fields ?? const {};
    final out = <String, dynamic>{};
    for (final MapEntry(:key, :value) in saved.entries) {
      final type = fields[key];
      final converted = type == null ? null : _value(type, value);
      if (converted == null) {
        skipped?.add(key);
      } else {
        out[key] = converted;
      }
    }
    return out;
  }

  Object? _value(_TypeRef type, Object? saved) {
    final named = type.named;
    // Lists are saved as is (custom fields).
    if (type.isList) return saved is List ? saved : null;
    final c = saved is Map
        ? saved.cast<String, dynamic>()
        : <String, dynamic>{'value': saved};
    final v = c['value'];
    switch (named.kind) {
      case 'SCALAR':
        return _scalar(named.name!, v);
      case 'ENUM':
        return _enum(named.name!, v);
      case 'INPUT_OBJECT':
        return _criterion(named.name!, v, c['modifier'] as String?);
    }
    return null;
  }

  Object? _scalar(String name, Object? v) {
    if (v == null) return null;
    return switch (name) {
      'Boolean' => v is bool ? v : '$v' == 'true',
      'Int' => v is num ? v.toInt() : int.tryParse('$v'),
      'Float' => v is num ? v.toDouble() : double.tryParse('$v'),
      _ => v is Map || v is List ? null : '$v',
    };
  }

  String? _enum(String name, Object? label) {
    if (label == null) return null;
    final values = _types[name]?.enumValues ?? const [];
    final s = '$label';
    for (final candidate in [
      s,
      if (name == 'ResolutionEnum') _resolutions[s.toLowerCase()],
      s.toUpperCase().replaceAll(RegExp('[^A-Z0-9]+'), '_'),
    ]) {
      if (candidate != null && values.contains(candidate)) return candidate;
    }
    return null;
  }

  static List<String> _ids(Object? items) => [
    for (final i in items is List ? items : const [])
      i is Map ? '${i['id']}' : '$i',
  ];

  Map<String, dynamic>? _criterion(String name, Object? v, String? modifier) {
    final fields = _types[name]?.fields ?? const {};
    final out = <String, dynamic>{};
    if (fields.containsKey('modifier')) out['modifier'] = modifier ?? 'EQUALS';
    final valueType = fields['value'];
    final map = v is Map ? v.cast<String, dynamic>() : null;

    if (fields.containsKey('depth') ||
        (valueType != null &&
            valueType.isList &&
            valueType.named.kind == 'SCALAR')) {
      // Performers, tags, studios… (with or without sub-levels): labelled
      // items, possibly with excluded ones.
      out['value'] = _ids(map != null ? map['items'] : v);
      if (fields.containsKey('excludes')) {
        out['excludes'] = _ids(map?['excluded']);
      }
      if (fields.containsKey('depth')) {
        out['depth'] = modifier == 'EQUALS' ? 0 : (map?['depth'] as num? ?? 0);
      }
    } else if (fields.containsKey('value2')) {
      // Numbers, dates, timestamps: a value or {value, value2}.
      final scalar = valueType!.named.name!;
      Object? coerce(Object? x) {
        if (x == null) return null;
        if (scalar == 'String') {
          // Timestamps are typed "2024-01-01 12:00" in the web UI.
          return '$x'.trim().replaceFirst(' ', 'T');
        }
        return _scalar(scalar, x);
      }

      out['value'] =
          coerce(map != null ? map['value'] : v) ??
          (scalar == 'String' ? '' : 0);
      final v2 = coerce(map?['value2']);
      if (v2 != null) out['value2'] = v2;
    } else if (fields.containsKey('value_list')) {
      // Genders: several labels.
      final enumName = fields['value_list']!.named.name!;
      out['value_list'] = [
        for (final l in v is List ? v : [v]) ?_enum(enumName, l),
      ];
    } else if (valueType != null && valueType.named.kind == 'ENUM') {
      // Resolution, orientation, circumcision: one label or several.
      final enumName = valueType.named.name!;
      if (valueType.isList) {
        out['value'] = [
          for (final l in v is List ? v : [v]) ?_enum(enumName, l),
        ];
      } else {
        final e = _enum(enumName, v);
        if (e == null) return null;
        out['value'] = e;
      }
    } else if (map != null) {
      // Stash IDs, phash distance, duplicates: same keys, except the web
      // UI's camel case "stashID".
      for (final MapEntry(:key, :value) in map.entries) {
        final k = key == 'stashID' ? 'stash_id' : key;
        if (fields.containsKey(k) && value != null) out[k] = value;
      }
    } else if (fields.containsKey('phash') ||
        fields.containsKey('duplicated')) {
      // Old saved format of duplicates: "true" / "false", read as phash
      // duplicates like the web UI does ("duplicated" is deprecated, and
      // hidden from introspection, on newer servers).
      out[fields.containsKey('phash') ? 'phash' : 'duplicated'] =
          '$v' == 'true';
    } else if (valueType != null) {
      out['value'] = _scalar(valueType.named.name!, v) ?? '';
    }
    return out;
  }
}

class _Type {
  const _Type(this.kind, this.fields, this.enumValues);
  final String kind;
  final Map<String, _TypeRef> fields;
  final List<String> enumValues;
}

class _TypeRef {
  const _TypeRef(this.kind, this.name, this.ofType);

  factory _TypeRef.fromJson(Map<String, dynamic> j) => _TypeRef(
    j['kind'] as String,
    j['name'] as String?,
    j['ofType'] == null
        ? null
        : _TypeRef.fromJson((j['ofType'] as Map).cast<String, dynamic>()),
  );

  final String kind;
  final String? name;
  final _TypeRef? ofType;

  /// The type without its "required" and "list" wrappers.
  _TypeRef get named => ofType == null ? this : ofType!.named;

  bool get isList =>
      kind == 'LIST' || (kind == 'NON_NULL' && (ofType?.isList ?? false));
}
