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


/** This is an auto generated class representing the Report type in your schema. */
class Report extends amplify_core.Model {
  static const classType = const _ReportModelType();
  final String id;
  final String? _callId;
  final String? _reportedBy;
  final ReportCategory? _category;
  final String? _description;
  final ReportStatus? _status;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  ReportModelIdentifier get modelIdentifier {
      return ReportModelIdentifier(
        id: id
      );
  }
  
  String get callId {
    try {
      return _callId!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get reportedBy {
    try {
      return _reportedBy!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  ReportCategory get category {
    try {
      return _category!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String? get description {
    return _description;
  }
  
  ReportStatus get status {
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
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const Report._internal({required this.id, required callId, required reportedBy, required category, description, required status, createdAt, updatedAt}): _callId = callId, _reportedBy = reportedBy, _category = category, _description = description, _status = status, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory Report({String? id, required String callId, required String reportedBy, required ReportCategory category, String? description, required ReportStatus status, amplify_core.TemporalDateTime? createdAt}) {
    return Report._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      callId: callId,
      reportedBy: reportedBy,
      category: category,
      description: description,
      status: status,
      createdAt: createdAt);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Report &&
      id == other.id &&
      _callId == other._callId &&
      _reportedBy == other._reportedBy &&
      _category == other._category &&
      _description == other._description &&
      _status == other._status &&
      _createdAt == other._createdAt;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("Report {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("callId=" + "$_callId" + ", ");
    buffer.write("reportedBy=" + "$_reportedBy" + ", ");
    buffer.write("category=" + (_category != null ? amplify_core.enumToString(_category)! : "null") + ", ");
    buffer.write("description=" + "$_description" + ", ");
    buffer.write("status=" + (_status != null ? amplify_core.enumToString(_status)! : "null") + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  Report copyWith({String? callId, String? reportedBy, ReportCategory? category, String? description, ReportStatus? status, amplify_core.TemporalDateTime? createdAt}) {
    return Report._internal(
      id: id,
      callId: callId ?? this.callId,
      reportedBy: reportedBy ?? this.reportedBy,
      category: category ?? this.category,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt);
  }
  
  Report copyWithModelFieldValues({
    ModelFieldValue<String>? callId,
    ModelFieldValue<String>? reportedBy,
    ModelFieldValue<ReportCategory>? category,
    ModelFieldValue<String?>? description,
    ModelFieldValue<ReportStatus>? status,
    ModelFieldValue<amplify_core.TemporalDateTime?>? createdAt
  }) {
    return Report._internal(
      id: id,
      callId: callId == null ? this.callId : callId.value,
      reportedBy: reportedBy == null ? this.reportedBy : reportedBy.value,
      category: category == null ? this.category : category.value,
      description: description == null ? this.description : description.value,
      status: status == null ? this.status : status.value,
      createdAt: createdAt == null ? this.createdAt : createdAt.value
    );
  }
  
  Report.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _callId = json['callId'],
      _reportedBy = json['reportedBy'],
      _category = amplify_core.enumFromString<ReportCategory>(json['category'], ReportCategory.values),
      _description = json['description'],
      _status = amplify_core.enumFromString<ReportStatus>(json['status'], ReportStatus.values),
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'callId': _callId, 'reportedBy': _reportedBy, 'category': amplify_core.enumToString(_category), 'description': _description, 'status': amplify_core.enumToString(_status), 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'callId': _callId,
    'reportedBy': _reportedBy,
    'category': _category,
    'description': _description,
    'status': _status,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<ReportModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<ReportModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final CALLID = amplify_core.QueryField(fieldName: "callId");
  static final REPORTEDBY = amplify_core.QueryField(fieldName: "reportedBy");
  static final CATEGORY = amplify_core.QueryField(fieldName: "category");
  static final DESCRIPTION = amplify_core.QueryField(fieldName: "description");
  static final STATUS = amplify_core.QueryField(fieldName: "status");
  static final CREATEDAT = amplify_core.QueryField(fieldName: "createdAt");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "Report";
    modelSchemaDefinition.pluralName = "Reports";
    
    modelSchemaDefinition.authRules = [
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.PUBLIC,
        provider: amplify_core.AuthRuleProvider.APIKEY,
        operations: const [
          amplify_core.ModelOperation.CREATE
        ]),
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.PRIVATE,
        operations: const [
          amplify_core.ModelOperation.CREATE
        ]),
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
        ])
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Report.CALLID,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Report.REPORTEDBY,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Report.CATEGORY,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.enumeration)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Report.DESCRIPTION,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Report.STATUS,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.enumeration)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Report.CREATEDAT,
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

class _ReportModelType extends amplify_core.ModelType<Report> {
  const _ReportModelType();
  
  @override
  Report fromJson(Map<String, dynamic> jsonData) {
    return Report.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'Report';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [Report] in your schema.
 */
class ReportModelIdentifier implements amplify_core.ModelIdentifier<Report> {
  final String id;

  /** Create an instance of ReportModelIdentifier using [id] the primary key. */
  const ReportModelIdentifier({
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
  String toString() => 'ReportModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is ReportModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}