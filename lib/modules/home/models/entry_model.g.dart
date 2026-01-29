// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entry_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EntryModelImpl _$$EntryModelImplFromJson(Map<String, dynamic> json) =>
    _$EntryModelImpl(
      id: json['id'] as String,
      body: json['body'] as String? ?? "",
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$EntryModelImplToJson(_$EntryModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'body': instance.body,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
