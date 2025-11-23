/*
* Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
*
* Licensed under the Apache License, Version 2.0 (the "License").
* You may not use this file except in compliance with the License.
* A copy of the License is located at
*
*  http://aws.amazon.com/apache2.0
*
* or in the "license" file accompanying this file. This file is distributed
* on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
* express or implied. See the License for the specific language governing
* permissions and limitations under the License.
*/

// NOTE: This file is generated and may not follow lint rules defined in your app
// Generated files can be excluded from analysis in analysis_options.yaml
// For more info, see: https://dart.dev/guides/language/analysis-options#excluding-code-from-analysis

// ignore_for_file: public_member_api_docs, annotate_overrides, dead_code, dead_codepublic_member_api_docs, depend_on_referenced_packages, file_names, library_private_types_in_public_api, no_leading_underscores_for_library_prefixes, no_leading_underscores_for_local_identifiers, non_constant_identifier_names, null_check_on_nullable_type_parameter, override_on_non_overriding_member, prefer_adjacent_string_concatenation, prefer_const_constructors, prefer_if_null_operators, prefer_interpolation_to_compose_strings, slash_for_doc_comments, sort_child_properties_last, unnecessary_const, unnecessary_constructor_name, unnecessary_late, unnecessary_new, unnecessary_null_aware_assignments, unnecessary_nullable_for_final_variable_declarations, unnecessary_string_interpolations, use_build_context_synchronously

import 'ModelProvider.dart';
import 'package:amplify_core/amplify_core.dart' as amplify_core;


/** This is an auto generated class representing the Call type in your schema. */
class Call extends amplify_core.Model {
  static const classType = const _CallModelType();
  final String id;
  final String? _blindUserId;
  final String? _blindUserName;
  final String? _volunteerId;
  final String? _volunteerName;
  final CallStatus? _status;
  final String? _meetingId;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  CallModelIdentifier get modelIdentifier {
      return CallModelIdentifier(
        id: id
      );
  }
  
  String get blindUserId {
    try {
      return _blindUserId!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get blindUserName {
    try {
      return _blindUserName!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String? get volunteerId {
    return _volunteerId;
  }
  
  String? get volunteerName {
    return _volunteerName;
  }
  
  CallStatus get status {
    try {
      return _status!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get meetingId {
    try {
      return _meetingId!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const Call._internal({required this.id, required blindUserId, required blindUserName, volunteerId, volunteerName, required status, required meetingId, createdAt, updatedAt}): _blindUserId = blindUserId, _blindUserName = blindUserName, _volunteerId = volunteerId, _volunteerName = volunteerName, _status = status, _meetingId = meetingId, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory Call({String? id, required String blindUserId, required String blindUserName, String? volunteerId, String? volunteerName, required CallStatus status, required String meetingId, amplify_core.TemporalDateTime? createdAt, amplify_core.TemporalDateTime? updatedAt}) {
    return Call._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      blindUserId: blindUserId,
      blindUserName: blindUserName,
      volunteerId: volunteerId,
      volunteerName: volunteerName,
      status: status,
      meetingId: meetingId,
      createdAt: createdAt,
      updatedAt: updatedAt);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Call &&
      id == other.id &&
      _blindUserId == other._blindUserId &&
      _blindUserName == other._blindUserName &&
      _volunteerId == other._volunteerId &&
      _volunteerName == other._volunteerName &&
      _status == other._status &&
      _meetingId == other._meetingId &&
      _createdAt == other._createdAt &&
      _updatedAt == other._updatedAt;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("Call {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("blindUserId=" + "$_blindUserId" + ", ");
    buffer.write("blindUserName=" + "$_blindUserName" + ", ");
    buffer.write("volunteerId=" + "$_volunteerId" + ", ");
    buffer.write("volunteerName=" + "$_volunteerName" + ", ");
    buffer.write("status=" + (_status != null ? amplify_core.enumToString(_status)! : "null") + ", ");
    buffer.write("meetingId=" + "$_meetingId" + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  Call copyWith({String? blindUserId, String? blindUserName, String? volunteerId, String? volunteerName, CallStatus? status, String? meetingId, amplify_core.TemporalDateTime? createdAt, amplify_core.TemporalDateTime? updatedAt}) {
    return Call._internal(
      id: id,
      blindUserId: blindUserId ?? this.blindUserId,
      blindUserName: blindUserName ?? this.blindUserName,
      volunteerId: volunteerId ?? this.volunteerId,
      volunteerName: volunteerName ?? this.volunteerName,
      status: status ?? this.status,
      meetingId: meetingId ?? this.meetingId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt);
  }
  
  Call copyWithModelFieldValues({
    ModelFieldValue<String>? blindUserId,
    ModelFieldValue<String>? blindUserName,
    ModelFieldValue<String?>? volunteerId,
    ModelFieldValue<String?>? volunteerName,
    ModelFieldValue<CallStatus>? status,
    ModelFieldValue<String>? meetingId,
    ModelFieldValue<amplify_core.TemporalDateTime?>? createdAt,
    ModelFieldValue<amplify_core.TemporalDateTime?>? updatedAt
  }) {
    return Call._internal(
      id: id,
      blindUserId: blindUserId == null ? this.blindUserId : blindUserId.value,
      blindUserName: blindUserName == null ? this.blindUserName : blindUserName.value,
      volunteerId: volunteerId == null ? this.volunteerId : volunteerId.value,
      volunteerName: volunteerName == null ? this.volunteerName : volunteerName.value,
      status: status == null ? this.status : status.value,
      meetingId: meetingId == null ? this.meetingId : meetingId.value,
      createdAt: createdAt == null ? this.createdAt : createdAt.value,
      updatedAt: updatedAt == null ? this.updatedAt : updatedAt.value
    );
  }
  
  Call.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _blindUserId = json['blindUserId'],
      _blindUserName = json['blindUserName'],
      _volunteerId = json['volunteerId'],
      _volunteerName = json['volunteerName'],
      _status = amplify_core.enumFromString<CallStatus>(json['status'], CallStatus.values),
      _meetingId = json['meetingId'],
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'blindUserId': _blindUserId, 'blindUserName': _blindUserName, 'volunteerId': _volunteerId, 'volunteerName': _volunteerName, 'status': amplify_core.enumToString(_status), 'meetingId': _meetingId, 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'blindUserId': _blindUserId,
    'blindUserName': _blindUserName,
    'volunteerId': _volunteerId,
    'volunteerName': _volunteerName,
    'status': _status,
    'meetingId': _meetingId,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<CallModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<CallModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final BLINDUSERID = amplify_core.QueryField(fieldName: "blindUserId");
  static final BLINDUSERNAME = amplify_core.QueryField(fieldName: "blindUserName");
  static final VOLUNTEERID = amplify_core.QueryField(fieldName: "volunteerId");
  static final VOLUNTEERNAME = amplify_core.QueryField(fieldName: "volunteerName");
  static final STATUS = amplify_core.QueryField(fieldName: "status");
  static final MEETINGID = amplify_core.QueryField(fieldName: "meetingId");
  static final CREATEDAT = amplify_core.QueryField(fieldName: "createdAt");
  static final UPDATEDAT = amplify_core.QueryField(fieldName: "updatedAt");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "Call";
    modelSchemaDefinition.pluralName = "Calls";
    
    modelSchemaDefinition.authRules = [
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.PUBLIC,
        provider: amplify_core.AuthRuleProvider.APIKEY,
        operations: const [
          amplify_core.ModelOperation.CREATE,
          amplify_core.ModelOperation.READ
        ]),
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.PRIVATE,
        operations: const [
          amplify_core.ModelOperation.READ,
          amplify_core.ModelOperation.UPDATE,
          amplify_core.ModelOperation.DELETE
        ])
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Call.BLINDUSERID,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Call.BLINDUSERNAME,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Call.VOLUNTEERID,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Call.VOLUNTEERNAME,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Call.STATUS,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.enumeration)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Call.MEETINGID,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Call.CREATEDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Call.UPDATEDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
  });
}

class _CallModelType extends amplify_core.ModelType<Call> {
  const _CallModelType();
  
  @override
  Call fromJson(Map<String, dynamic> jsonData) {
    return Call.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'Call';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [Call] in your schema.
 */
class CallModelIdentifier implements amplify_core.ModelIdentifier<Call> {
  final String id;

  /** Create an instance of CallModelIdentifier using [id] the primary key. */
  const CallModelIdentifier({
    required this.id});
  
  @override
  Map<String, dynamic> serializeAsMap() => (<String, dynamic>{
    'id': id
  });
  
  @override
  List<Map<String, dynamic>> serializeAsList() => serializeAsMap()
    .entries
    .map((entry) => (<String, dynamic>{ entry.key: entry.value }))
    .toList();
  
  @override
  String serializeAsString() => serializeAsMap().values.join('#');
  
  @override
  String toString() => 'CallModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is CallModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}