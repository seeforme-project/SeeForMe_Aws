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


/** This is an auto generated class representing the Notification type in your schema. */
class Notification extends amplify_core.Model {
  static const classType = const _NotificationModelType();
  final String id;
  final String? _userId;
  final String? _title;
  final String? _message;
  final NotificationType? _type;
  final bool? _isRead;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  NotificationModelIdentifier get modelIdentifier {
      return NotificationModelIdentifier(
        id: id
      );
  }
  
  String get userId {
    try {
      return _userId!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get title {
    try {
      return _title!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get message {
    try {
      return _message!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  NotificationType get type {
    try {
      return _type!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  bool? get isRead {
    return _isRead;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const Notification._internal({required this.id, required userId, required title, required message, required type, isRead, createdAt, updatedAt}): _userId = userId, _title = title, _message = message, _type = type, _isRead = isRead, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory Notification({String? id, required String userId, required String title, required String message, required NotificationType type, bool? isRead, amplify_core.TemporalDateTime? createdAt}) {
    return Notification._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      userId: userId,
      title: title,
      message: message,
      type: type,
      isRead: isRead,
      createdAt: createdAt);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Notification &&
      id == other.id &&
      _userId == other._userId &&
      _title == other._title &&
      _message == other._message &&
      _type == other._type &&
      _isRead == other._isRead &&
      _createdAt == other._createdAt;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("Notification {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("userId=" + "$_userId" + ", ");
    buffer.write("title=" + "$_title" + ", ");
    buffer.write("message=" + "$_message" + ", ");
    buffer.write("type=" + (_type != null ? amplify_core.enumToString(_type)! : "null") + ", ");
    buffer.write("isRead=" + (_isRead != null ? _isRead!.toString() : "null") + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  Notification copyWith({String? userId, String? title, String? message, NotificationType? type, bool? isRead, amplify_core.TemporalDateTime? createdAt}) {
    return Notification._internal(
      id: id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt);
  }
  
  Notification copyWithModelFieldValues({
    ModelFieldValue<String>? userId,
    ModelFieldValue<String>? title,
    ModelFieldValue<String>? message,
    ModelFieldValue<NotificationType>? type,
    ModelFieldValue<bool?>? isRead,
    ModelFieldValue<amplify_core.TemporalDateTime?>? createdAt
  }) {
    return Notification._internal(
      id: id,
      userId: userId == null ? this.userId : userId.value,
      title: title == null ? this.title : title.value,
      message: message == null ? this.message : message.value,
      type: type == null ? this.type : type.value,
      isRead: isRead == null ? this.isRead : isRead.value,
      createdAt: createdAt == null ? this.createdAt : createdAt.value
    );
  }
  
  Notification.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _userId = json['userId'],
      _title = json['title'],
      _message = json['message'],
      _type = amplify_core.enumFromString<NotificationType>(json['type'], NotificationType.values),
      _isRead = json['isRead'],
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'userId': _userId, 'title': _title, 'message': _message, 'type': amplify_core.enumToString(_type), 'isRead': _isRead, 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'userId': _userId,
    'title': _title,
    'message': _message,
    'type': _type,
    'isRead': _isRead,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<NotificationModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<NotificationModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final USERID = amplify_core.QueryField(fieldName: "userId");
  static final TITLE = amplify_core.QueryField(fieldName: "title");
  static final MESSAGE = amplify_core.QueryField(fieldName: "message");
  static final TYPE = amplify_core.QueryField(fieldName: "type");
  static final ISREAD = amplify_core.QueryField(fieldName: "isRead");
  static final CREATEDAT = amplify_core.QueryField(fieldName: "createdAt");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "Notification";
    modelSchemaDefinition.pluralName = "Notifications";
    
    modelSchemaDefinition.authRules = [
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.GROUPS,
        groupClaim: "cognito:groups",
        groups: [ "Admins" ],
        provider: amplify_core.AuthRuleProvider.USERPOOLS,
        operations: const [
          amplify_core.ModelOperation.CREATE,
          amplify_core.ModelOperation.READ,
          amplify_core.ModelOperation.UPDATE,
          amplify_core.ModelOperation.DELETE
        ]),
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.OWNER,
        ownerField: "userId",
        identityClaim: "cognito:username",
        provider: amplify_core.AuthRuleProvider.USERPOOLS,
        operations: const [
          amplify_core.ModelOperation.READ,
          amplify_core.ModelOperation.UPDATE
        ])
    ];
    
    modelSchemaDefinition.indexes = [
      amplify_core.ModelIndex(fields: const ["userId"], name: "byUser")
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Notification.USERID,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Notification.TITLE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Notification.MESSAGE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Notification.TYPE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.enumeration)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Notification.ISREAD,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.bool)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Notification.CREATEDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.nonQueryField(
      fieldName: 'updatedAt',
      isRequired: false,
      isReadOnly: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
  });
}

class _NotificationModelType extends amplify_core.ModelType<Notification> {
  const _NotificationModelType();
  
  @override
  Notification fromJson(Map<String, dynamic> jsonData) {
    return Notification.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'Notification';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [Notification] in your schema.
 */
class NotificationModelIdentifier implements amplify_core.ModelIdentifier<Notification> {
  final String id;

  /** Create an instance of NotificationModelIdentifier using [id] the primary key. */
  const NotificationModelIdentifier({
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
  String toString() => 'NotificationModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is NotificationModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}