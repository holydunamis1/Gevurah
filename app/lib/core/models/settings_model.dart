import 'model_utils.dart';

/// Theme choice: follow the device, or force light or dark.
enum ThemeChoice { system, light, dark }

/// User settings, stored as key-value pairs.
class SettingsModel {
  const SettingsModel({
    this.themeChoice = ThemeChoice.system,
    this.localeCode,
    this.timingAssist = false,
    this.soundOn = true,
    this.musicOn = true,
    this.hapticsOn = true,
    this.remindersOn = false,
    this.reminderMinuteOfDay = defaultReminderMinute,
    this.onboardingDone = false,
  });

  factory SettingsModel.fromJson(Map<String, Object?> json) {
    final int minute = readInt(json, 'reminderMinuteOfDay');
    if (minute < 0 || minute >= 24 * 60) {
      throw FormatException('Reminder minute out of range: $minute');
    }
    return SettingsModel(
      themeChoice: readEnum(ThemeChoice.values, json, 'themeChoice'),
      localeCode: readOptString(json, 'localeCode'),
      timingAssist: readBool(json, 'timingAssist'),
      soundOn: readBool(json, 'soundOn'),
      musicOn: readBool(json, 'musicOn'),
      hapticsOn: readBool(json, 'hapticsOn'),
      remindersOn: readBool(json, 'remindersOn'),
      reminderMinuteOfDay: minute,
      onboardingDone: json['onboardingDone'] == true,
    );
  }

  /// 20:00.
  static const int defaultReminderMinute = 20 * 60;

  final ThemeChoice themeChoice;

  /// Null follows the device language.
  final String? localeCode;

  /// Widens every timing window by 40 ms.
  final bool timingAssist;
  final bool soundOn;
  final bool musicOn;
  final bool hapticsOn;

  /// The opt-in Daily Bout reminder.
  final bool remindersOn;
  final int reminderMinuteOfDay;

  /// Whether the first-run screen has been completed. Optional in older
  /// saves, which read as not done.
  final bool onboardingDone;

  SettingsModel copyWith({
    ThemeChoice? themeChoice,
    String? localeCode,
    bool clearLocale = false,
    bool? timingAssist,
    bool? soundOn,
    bool? musicOn,
    bool? hapticsOn,
    bool? remindersOn,
    int? reminderMinuteOfDay,
    bool? onboardingDone,
  }) {
    return SettingsModel(
      themeChoice: themeChoice ?? this.themeChoice,
      localeCode: clearLocale ? null : (localeCode ?? this.localeCode),
      timingAssist: timingAssist ?? this.timingAssist,
      soundOn: soundOn ?? this.soundOn,
      musicOn: musicOn ?? this.musicOn,
      hapticsOn: hapticsOn ?? this.hapticsOn,
      remindersOn: remindersOn ?? this.remindersOn,
      reminderMinuteOfDay: reminderMinuteOfDay ?? this.reminderMinuteOfDay,
      onboardingDone: onboardingDone ?? this.onboardingDone,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'themeChoice': themeChoice.name,
        'localeCode': localeCode,
        'timingAssist': timingAssist,
        'soundOn': soundOn,
        'musicOn': musicOn,
        'hapticsOn': hapticsOn,
        'remindersOn': remindersOn,
        'reminderMinuteOfDay': reminderMinuteOfDay,
        'onboardingDone': onboardingDone,
      };

  @override
  bool operator ==(Object other) =>
      other is SettingsModel &&
      other.themeChoice == themeChoice &&
      other.localeCode == localeCode &&
      other.timingAssist == timingAssist &&
      other.soundOn == soundOn &&
      other.musicOn == musicOn &&
      other.hapticsOn == hapticsOn &&
      other.remindersOn == remindersOn &&
      other.reminderMinuteOfDay == reminderMinuteOfDay &&
      other.onboardingDone == onboardingDone;

  @override
  int get hashCode => Object.hash(
        themeChoice,
        localeCode,
        timingAssist,
        soundOn,
        musicOn,
        hapticsOn,
        remindersOn,
        reminderMinuteOfDay,
        onboardingDone,
      );
}
