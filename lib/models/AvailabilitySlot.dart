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


/** This is an auto generated class representing the AvailabilitySlot type in your schema. */
class AvailabilitySlot {
  final String? _day;
  final amplify_core.TemporalTime? _startTime;
  final amplify_core.TemporalTime? _endTime;

  String get day {
    try {
      return _day!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  amplify_core.TemporalTime get startTime {
    try {
      return _startTime!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  amplify_core.TemporalTime get endTime {
    try {
      return _endTime!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  const AvailabilitySlot._internal({required day, required startTime, required endTime}): _day = day, _startTime = startTime, _endTime = endTime;
  
  factory AvailabilitySlot({required String day, required amplify_core.TemporalTime startTime, required amplify_core.TemporalTime endTime}) {
    return AvailabilitySlot._internal(
      day: day,
      startTime: startTime,
      endTime: endTime);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AvailabilitySlot &&
      _day == other._day &&
      _startTime == other._startTime &&
      _endTime == other._endTime;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("AvailabilitySlot {");
    buffer.write("day=" + "$_day" + ", ");
    buffer.write("startTime=" + (_startTime != null ? _startTime!.format() : "null") + ", ");
    buffer.write("endTime=" + (_endTime != null ? _endTime!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  AvailabilitySlot copyWith({String? day, amplify_core.TemporalTime? startTime, amplify_core.TemporalTime? endTime}) {
    return AvailabilitySlot._internal(
      day: day ?? this.day,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime);
  }
  
  AvailabilitySlot copyWithModelFieldValues({
    ModelFieldValue<String>? day,
    ModelFieldValue<amplify_core.TemporalTime>? startTime,
    ModelFieldValue<amplify_core.TemporalTime>? endTime
  }) {
    return AvailabilitySlot._internal(
      day: day == null ? this.day : day.value,
      startTime: startTime == null ? this.startTime : startTime.value,
      endTime: endTime == null ? this.endTime : endTime.value
    );
  }
  
  AvailabilitySlot.fromJson(Map<String, dynamic> json)  
    : _day = json['day'],
      _startTime = json['startTime'] != null ? amplify_core.TemporalTime.fromString(json['startTime']) : null,
      _endTime = json['endTime'] != null ? amplify_core.TemporalTime.fromString(json['endTime']) : null;
  
  Map<String, dynamic> toJson() => {
    'day': _day, 'startTime': _startTime?.format(), 'endTime': _endTime?.format()
  };
  
  Map<String, Object?> toMap() => {
    'day': _day,
    'startTime': _startTime,
    'endTime': _endTime
  };

  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "AvailabilitySlot";
    modelSchemaDefinition.pluralName = "AvailabilitySlots";
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.customTypeField(
      fieldName: 'day',
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.customTypeField(
      fieldName: 'startTime',
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.time)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.customTypeField(
      fieldName: 'endTime',
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.time)
    ));
  });
}