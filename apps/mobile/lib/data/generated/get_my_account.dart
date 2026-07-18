part of 'mobile.dart';

class GetMyAccountVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  GetMyAccountVariablesBuilder(this._dataConnect, );
  Deserializer<GetMyAccountData> dataDeserializer = (dynamic json)  => GetMyAccountData.fromJson(jsonDecode(json));
  
  Future<QueryResult<GetMyAccountData, void>> execute() {
    return ref().execute();
  }

  QueryRef<GetMyAccountData, void> ref() {
    
    return _dataConnect.query("GetMyAccount", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class GetMyAccountAppUser {
  final String uid;
  final String? displayName;
  final EnumValue<AccountStatus> status;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  GetMyAccountAppUser.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']),
  displayName = json['displayName'] == null ? null : nativeFromJson<String>(json['displayName']),
  status = accountStatusDeserializer(json['status']),
  createdAt = Timestamp.fromJson(json['createdAt']),
  updatedAt = Timestamp.fromJson(json['updatedAt']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyAccountAppUser otherTyped = other as GetMyAccountAppUser;
    return uid == otherTyped.uid && 
    displayName == otherTyped.displayName && 
    status == otherTyped.status && 
    createdAt == otherTyped.createdAt && 
    updatedAt == otherTyped.updatedAt;
    
  }
  @override
  int get hashCode => Object.hashAll([uid.hashCode, displayName.hashCode, status.hashCode, createdAt.hashCode, updatedAt.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    if (displayName != null) {
      json['displayName'] = nativeToJson<String?>(displayName);
    }
    json['status'] = 
    accountStatusSerializer(status)
    ;
    json['createdAt'] = createdAt.toJson();
    json['updatedAt'] = updatedAt.toJson();
    return json;
  }

  GetMyAccountAppUser({
    required this.uid,
    this.displayName,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
}

@immutable
class GetMyAccountData {
  final GetMyAccountAppUser? appUser;
  GetMyAccountData.fromJson(dynamic json):
  
  appUser = json['appUser'] == null ? null : GetMyAccountAppUser.fromJson(json['appUser']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyAccountData otherTyped = other as GetMyAccountData;
    return appUser == otherTyped.appUser;
    
  }
  @override
  int get hashCode => appUser.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (appUser != null) {
      json['appUser'] = appUser!.toJson();
    }
    return json;
  }

  GetMyAccountData({
    this.appUser,
  });
}

