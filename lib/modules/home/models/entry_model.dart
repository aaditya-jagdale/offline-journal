import 'package:freezed_annotation/freezed_annotation.dart';

part 'entry_model.freezed.dart';
part 'entry_model.g.dart';

@freezed
class EntryModel with _$EntryModel {
  const factory EntryModel({
    required String id,
    @Default("") String body,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _EntryModel;

  factory EntryModel.fromJson(Map<String, dynamic> json) =>
      _$EntryModelFromJson(json);
}
