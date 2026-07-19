part of 'mobile.dart';

class UpsertMyAccountVariablesBuilder {
  Optional<String> _displayName = Optional.optional(
    nativeFromJson,
    nativeToJson,
  );

  final FirebaseDataConnect _dataConnect;
  UpsertMyAccountVariablesBuilder displayName(String? t) {
    _displayName.value = t;
    return this;
  }

  UpsertMyAccountVariablesBuilder(this._dataConnect);
  Deserializer<UpsertMyAccountData> dataDeserializer = (dynamic json) =>
      UpsertMyAccountData.fromJson(jsonDecode(json));
  Serializer<UpsertMyAccountVariables> varsSerializer =
      (UpsertMyAccountVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpsertMyAccountData, UpsertMyAccountVariables>>
  execute() {
    return ref().execute();
  }

  MutationRef<UpsertMyAccountData, UpsertMyAccountVariables> ref() {
    UpsertMyAccountVariables vars = UpsertMyAccountVariables(
      displayName: _displayName,
    );
    return _dataConnect.mutation(
      "UpsertMyAccount",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class UpsertMyAccountAppUserUpsert {
  final String uid;
  UpsertMyAccountAppUserUpsert.fromJson(dynamic json)
    : uid = nativeFromJson<String>(json['uid']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertMyAccountAppUserUpsert otherTyped =
        other as UpsertMyAccountAppUserUpsert;
    return uid == otherTyped.uid;
  }

  @override
  int get hashCode => uid.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  UpsertMyAccountAppUserUpsert({required this.uid});
}

@immutable
class UpsertMyAccountData {
  final UpsertMyAccountAppUserUpsert appUser_upsert;
  UpsertMyAccountData.fromJson(dynamic json)
    : appUser_upsert = UpsertMyAccountAppUserUpsert.fromJson(
        json['appUser_upsert'],
      );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertMyAccountData otherTyped = other as UpsertMyAccountData;
    return appUser_upsert == otherTyped.appUser_upsert;
  }

  @override
  int get hashCode => appUser_upsert.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['appUser_upsert'] = appUser_upsert.toJson();
    return json;
  }

  UpsertMyAccountData({required this.appUser_upsert});
}

@immutable
class UpsertMyAccountVariables {
  late final Optional<String> displayName;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  UpsertMyAccountVariables.fromJson(Map<String, dynamic> json) {
    displayName = Optional.optional(nativeFromJson, nativeToJson);
    displayName.value = json['displayName'] == null
        ? null
        : nativeFromJson<String>(json['displayName']);
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertMyAccountVariables otherTyped =
        other as UpsertMyAccountVariables;
    return displayName == otherTyped.displayName;
  }

  @override
  int get hashCode => displayName.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (displayName.state == OptionalState.set) {
      json['displayName'] = displayName.toJson();
    }
    return json;
  }

  UpsertMyAccountVariables({required this.displayName});
}
