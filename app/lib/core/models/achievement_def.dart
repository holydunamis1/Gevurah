import 'model_utils.dart';

/// One local achievement. [ruleId] names the rule the achievements engine checks.
class AchievementDef {
  const AchievementDef({required this.id, required this.ruleId});

  factory AchievementDef.fromJson(Map<String, Object?> json) =>
      AchievementDef(id: readString(json, 'id'), ruleId: readString(json, 'ruleId'));

  final String id;
  final String ruleId;

  String get nameKey => 'achievement_$id';
  String get descriptionKey => 'achievement_${id}_desc';

  Map<String, Object?> toJson() => <String, Object?>{'id': id, 'ruleId': ruleId};

  @override
  bool operator ==(Object other) => other is AchievementDef && other.id == id && other.ruleId == ruleId;

  @override
  int get hashCode => Object.hash(id, ruleId);
}
