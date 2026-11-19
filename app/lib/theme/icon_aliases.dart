import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The only file that names an icon symbol. Everything else uses these
/// meaning-based aliases, so changing a symbol is a one-line edit here.
abstract final class AppIcons {
  // Navigation and actions
  static const IconData back = LucideIcons.chevronLeft;
  static const IconData forward = LucideIcons.chevronRight;
  static const IconData close = LucideIcons.x;
  static const IconData check = LucideIcons.check;
  static const IconData refresh = LucideIcons.refreshCw;
  static const IconData externalLink = LucideIcons.externalLink;
  static const IconData mail = LucideIcons.mail;
  static const IconData home = LucideIcons.house;
  static const IconData settings = LucideIcons.settings;
  static const IconData play = LucideIcons.play;
  static const IconData pause = LucideIcons.pause;
  static const IconData retry = LucideIcons.rotateCcw;

  // Status
  static const IconData info = LucideIcons.info;
  static const IconData warning = LucideIcons.triangleAlert;
  static const IconData error = LucideIcons.circleAlert;
  static const IconData help = LucideIcons.circleHelp;
  static const IconData locked = LucideIcons.lock;
  static const IconData unlocked = LucideIcons.lockOpen;

  // Settings
  static const IconData sound = LucideIcons.volume2;
  static const IconData muted = LucideIcons.volumeX;
  static const IconData haptics = LucideIcons.vibrate;
  static const IconData notifications = LucideIcons.bell;
  static const IconData notificationsOff = LucideIcons.bellOff;
  static const IconData language = LucideIcons.languages;
  static const IconData theme = LucideIcons.palette;
  static const IconData themeDark = LucideIcons.moon;
  static const IconData themeLight = LucideIcons.sun;
  static const IconData accessibility = LucideIcons.accessibility;
  static const IconData privacy = LucideIcons.shieldCheck;

  // Game
  static const IconData fight = LucideIcons.swords;
  static const IconData guard = LucideIcons.shield;
  static const IconData slip = LucideIcons.wind;
  static const IconData strike = LucideIcons.zap;
  static const IconData breath = LucideIcons.feather;
  static const IconData timing = LucideIcons.timer;
  static const IconData target = LucideIcons.target;
  static const IconData resolve = LucideIcons.heart;
  static const IconData stamina = LucideIcons.gauge;
  static const IconData weight = LucideIcons.dumbbell;
  static const IconData journey = LucideIcons.route;
  static const IconData daily = LucideIcons.sunrise;
  static const IconData trials = LucideIcons.mountain;
  static const IconData training = LucideIcons.footprints;
  static const IconData endurance = LucideIcons.flame;
  static const IconData star = LucideIcons.star;
  static const IconData achievement = LucideIcons.award;
  static const IconData trophy = LucideIcons.trophy;
  static const IconData calendar = LucideIcons.calendar;
  static const IconData verse = LucideIcons.scrollText;
  static const IconData library = LucideIcons.library;
  static const IconData card = LucideIcons.layers;
  static const IconData removeAds = LucideIcons.ticket;
}
