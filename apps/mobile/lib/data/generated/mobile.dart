library moolsocial_data;
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

part 'get_my_account.dart';

part 'upsert_my_account.dart';



  enum AccountStatus {
    
      ACTIVE,
    
      RESTRICTED,
    
      DELETED,
    
  }
  
  String accountStatusSerializer(EnumValue<AccountStatus> e) {
    return e.stringValue;
  }
  EnumValue<AccountStatus> accountStatusDeserializer(dynamic data) {
    switch (data) {
      
      case 'ACTIVE':
        return const Known(AccountStatus.ACTIVE);
      
      case 'RESTRICTED':
        return const Known(AccountStatus.RESTRICTED);
      
      case 'DELETED':
        return const Known(AccountStatus.DELETED);
      
      default:
        return Unknown(data);
    }
  }
  



String enumSerializer(Enum e) {
  return e.name;
}



/// A sealed class representing either a known enum value or an unknown string value.
@immutable
sealed class EnumValue<T extends Enum> {
  const EnumValue();

  

  /// The string representation of the value.
  String get stringValue;
  @override
  String toString() {
    return "EnumValue($stringValue)";
  }
}

/// Represents a known, valid enum value.
class Known<T extends Enum> extends EnumValue<T> {
  /// The actual enum value.
  final T value;

  const Known(this.value);

  @override
  String get stringValue => value.name;

  @override
  String toString() {
    return "Known($stringValue)";
  }
}
/// Represents an unknown or unrecognized enum value.
class Unknown extends EnumValue<Never> {
  /// The raw string value that couldn't be mapped to a known enum.
  @override
  final String stringValue;

  const Unknown(this.stringValue);
  @override
  String toString() {
    return "Unknown($stringValue)";
  }
}

class MobileConnector {
  
  
  GetMyAccountVariablesBuilder getMyAccount () {
    return GetMyAccountVariablesBuilder(dataConnect, );
  }
  
  
  UpsertMyAccountVariablesBuilder upsertMyAccount () {
    return UpsertMyAccountVariablesBuilder(dataConnect, );
  }
  

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'asia-south1',
    'mobile',
    'moolsocial-core',
  );

  MobileConnector({required this.dataConnect});
  static MobileConnector get instance {
    return MobileConnector(
        dataConnect: FirebaseDataConnect.instanceFor(
            connectorConfig: connectorConfig,
            sdkType: CallerSDKType.generated));
  }

  FirebaseDataConnect dataConnect;
}
