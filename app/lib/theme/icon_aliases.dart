import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons_400.dart';

/// The only file that names an icon symbol. Everything else uses these
/// meaning-based aliases, so changing a symbol is a one-line edit here.
/// All symbols come from the weight 400 font (a 2.0 stroke), which is how the
/// stroke weight is fixed for the whole app. Icon data must stay constant so
/// release builds can tree-shake unused glyphs.
abstract final class AppIcons {
  // Navigation and actions
  static const IconData back = LucideIcons400.chevronLeft;
  static const IconData forward = LucideIcons400.chevronRight;
  static const IconData close = LucideIcons400.x;
  static const IconData check = LucideIcons400.check;
  static const IconData refresh = LucideIcons400.refreshCw;
  static const IconData externalLink = LucideIcons400.externalLink;
  static const IconData mail = LucideIcons400.mail;
  static const IconData home = LucideIcons400.house;
  static const IconData settings = LucideIcons400.settings;
  static const IconData play = LucideIcons400.play;
  static const IconData pause = LucideIcons400.pause;
  static const IconData retry = LucideIcons400.rotateCcw;

  // Status
  static const IconData info = LucideIcons400.info;
  static const IconData warning = LucideIcons400.triangleAlert;
  static const IconData error = LucideIcons400.circleAlert;
  static const IconData help = LucideIcons400.circleHelp;
  static const IconData locked = LucideIcons400.lock;
  static const IconData unlocked = LucideIcons400.lockOpen;

  // Settings
  static const IconData sound = LucideIcons400.volume2;
  static const IconData muted = LucideIcons400.volumeX;
  static const IconData haptics = LucideIcons400.vibrate;
  static const IconData notifications = LucideIcons400.bell;
  static const IconData notificationsOff = LucideIcons400.bellOff;
  static const IconData language = LucideIcons400.languages;
  static const IconData theme = LucideIcons400.palette;
  static const IconData themeDark = LucideIcons400.moon;
  static const IconData themeLight = LucideIcons400.sun;
  static const IconData accessibility = LucideIcons400.accessibility;
  static const IconData privacy = LucideIcons400.shieldCheck;

  // Game
  static const IconData fight = LucideIcons400.swords;
  static const IconData guard = LucideIcons400.shield;
  static const IconData slip = LucideIcons400.wind;
  static const IconData strike = LucideIcons400.zap;
  static const IconData breath = LucideIcons400.feather;
  static const IconData timing = LucideIcons400.timer;
  static const IconData target = LucideIcons400.target;
  static const IconData resolve = LucideIcons400.heart;
  static const IconData stamina = LucideIcons400.gauge;
  static const IconData weight = LucideIcons400.dumbbell;
  static const IconData journey = LucideIcons400.route;
  static const IconData daily = LucideIcons400.sunrise;
  static const IconData trials = LucideIcons400.mountain;
  static const IconData training = LucideIcons400.footprints;
  static const IconData endurance = LucideIcons400.flame;
  static const IconData star = LucideIcons400.star;
  static const IconData achievement = LucideIcons400.award;
  static const IconData trophy = LucideIcons400.trophy;
  static const IconData calendar = LucideIcons400.calendar;
  static const IconData verse = LucideIcons400.scrollText;
  static const IconData library = LucideIcons400.library;
  static const IconData card = LucideIcons400.layers;
  static const IconData removeAds = LucideIcons400.ticket;
}
