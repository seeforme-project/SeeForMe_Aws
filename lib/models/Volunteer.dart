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
import 'package:collection/collection.dart';


/** This is an auto generated class representing the Volunteer type in your schema. */
class Volunteer extends amplify_core.Model {
  static const classType = const _VolunteerModelType();
  final String id;
  final String? _owner;
  final String? _name;
  final String? _email;
  final String? _gender;
  final bool? _isAvailableNow;
  final List<AvailabilitySlot>? _availabilitySchedule;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  VolunteerModelIdentifier get modelIdentifier {
      return VolunteerModelIdentifier(
        id: id
      );
  }
  
  String? get owner {
    return _owner;
  }
  
  String get name {
    try {
      return _name!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get email {
    try {
      return _email!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get gender {
    try {
      return _gender!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  bool? get isAvailableNow {
    return _isAvailableNow;
  }
  
  List<AvailabilitySlot>? get availabilitySchedule {
    return _availabilitySchedule;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const Volunteer._internal({required this.id, owner, required name, required email, required gender, isAvailableNow, availabilitySchedule, createdAt, updatedAt}): _owner = owner, _name = name, _email = email, _gender = gender, _isAvailableNow = isAvailableNow, _availabilitySchedule = availabilitySchedule, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory Volunteer({String? id, String? owner, required String name, required String email, required String gender, bool? isAvailableNow, List<AvailabilitySlot>? availabilitySchedule}) {
    return Volunteer._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      owner: owner,
      name: name,
      email: email,
      gender: gender,
      isAvailableNow: isAvailableNow,
      availabilitySchedule: availabilitySchedule != null ? List<AvailabilitySlot>.unmodifiable(availabilitySchedule) : availabilitySchedule);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Volunteer &&
      id == other.id &&
      _owner == other._owner &&
      _name == other._name &&
      _email == other._email &&
      _gender == other._gender &&
      _isAvailableNow == other._isAvailableNow &&
      DeepCollectionEquality().equals(_availabilitySchedule, other._availabilitySchedule);
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("Volunteer {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("owner=" + "$_owner" + ", ");
    buffer.write("name=" + "$_name" + ", ");
    buffer.write("email=" + "$_email" + ", ");
    buffer.write("gender=" + "$_gender" + ", ");
    buffer.write("isAvailableNow=" + (_isAvailableNow != null ? _isAvailableNow!.toString() : "null") + ", ");
    buffer.write("availabilitySchedule=" + (_availabilitySchedule != null ? _availabilitySchedule!.toString() : "null") + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  Volunteer copyWith({String? owner, String? name, String? email, String? gender, bool? isAvailableNow, List<AvailabilitySlot>? availabilitySchedule}) {
    return Volunteer._internal(
      id: id,
      owner: owner ?? this.owner,
      name: name ?? this.name,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      isAvailableNow: isAvailableNow ?? this.isAvailableNow,
      availabilitySchedule: availabilitySchedule ?? this.availabilitySchedule);
  }
  
  Volunteer copyWithModelFieldValues({
    ModelFieldValue<String?>? owner,
    ModelFieldValue<String>? name,
    ModelFieldValue<String>? email,
    ModelFieldValue<String>? gender,
    ModelFieldValue<bool?>? isAvailableNow,
    ModelFieldValue<List<AvailabilitySlot>?>? availabilitySchedule
  }) {
    return Volunteer._internal(
      id: id,
      owner: owner == null ? this.owner : owner.value,
      name: name == null ? this.name : name.value,
      email: email == null ? this.email : email.value,
      gender: gender == null ? this.gender : gender.value,
      isAvailableNow: isAvailableNow == null ? this.isAvailableNow : isAvailableNow.value,
      availabilitySchedule: availabilitySchedule == null ? this.availabilitySchedule : availabilitySchedule.value
    );
  }
  
  Volunteer.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _owner = json['owner'],
      _name = json['name'],
      _email = json['email'],
      _gender = json['gender'],
      _isAvailableNow = json['isAvailableNow'],
      _availabilitySchedule = json['availabilitySchedule'] is List
        ? (json['availabilitySchedule'] as List)
          .where((e) => e != null)
          .map((e) => AvailabilitySlot.fromJson(new Map<String, dynamic>.from(e['serializedData'] ?? e)))
          .toList()
        : null,
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'owner': _owner, 'name': _name, 'email': _email, 'gender': _gender, 'isAvailableNow': _isAvailableNow, 'availabilitySchedule': _availabilitySchedule?.map((AvailabilitySlot? e) => e?.toJson()).toList(), 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'owner': _owner,
    'name': _name,
    'email': _email,
    'gender': _gender,
    'isAvailableNow': _isAvailableNow,
    'availabilitySchedule': _availabilitySchedule,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<VolunteerModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<VolunteerModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final OWNER = amplify_core.QueryField(fieldName: "owner");
  static final NAME = amplify_core.QueryField(fieldName: "name");
  static final EMAIL = amplify_core.QueryField(fieldName: "email");
  static final GENDER = amplify_core.QueryField(fieldName: "gender");
  static final ISAVAILABLENOW = amplify_core.QueryField(fieldName: "isAvailableNow");
  static final AVAILABILITYSCHEDULE = amplify_core.QueryField(fieldName: "availabilitySchedule");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "Volunteer";
    modelSchemaDefinition.pluralName = "Volunteers";
    
    modelSchemaDefinition.authRules = [
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.OWNER,
        ownerField: "owner",
        identityClaim: "cognito:username",
        provider: amplify_core.AuthRuleProvider.USERPOOLS,
        operations: const [
          amplify_core.ModelOperation.CREATE,
          amplify_core.ModelOperation.READ,
          amplify_core.ModelOperation.UPDATE
        ])
    ];
    
    modelSchemaDefinition.indexes = [
      amplify_core.ModelIndex(fields: const ["owner", "id"], name: "byOwner")
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Volunteer.OWNER,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Volunteer.NAME,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Volunteer.EMAIL,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Volunteer.GENDER,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Volunteer.ISAVAILABLENOW,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.bool)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.embedded(
      fieldName: 'availabilitySchedule',
      isRequired: false,
      isArray: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.embeddedCollection, ofCustomTypeName: 'AvailabilitySlot')
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.nonQueryField(
      fieldName: 'createdAt',
      isRequired: false,
      isReadOnly: true,
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

class _VolunteerModelType extends amplify_core.ModelType<Volunteer> {
  const _VolunteerModelType();
  
  @override
  Volunteer fromJson(Map<String, dynamic> jsonData) {
    return Volunteer.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'Volunteer';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [Volunteer] in your schema.
 */
class VolunteerModelIdentifier implements amplify_core.ModelIdentifier<Volunteer> {
  final String id;

  /** Create an instance of VolunteerModelIdentifier using [id] the primary key. */
  const VolunteerModelIdentifier({
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
  String toString() => 'VolunteerModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is VolunteerModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}