import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path_provider/path_provider.dart';

import '../core/config/app_config.dart';
import '../core/models/settings_model.dart';
import '../core/ports/clock_port.dart';
import '../core/verses/verse_repository.dart';
import '../l10n/app_localizations.dart';
import '../platform/ad_service.dart';
import '../platform/ad_unit_ids.dart';
import '../platform/audio_service.dart';
import '../platform/banner_ad_view.dart';
import '../platform/billing_service.dart';
import '../platform/consent_service.dart';
import '../platform/flags_service.dart';
import '../platform/haptics_service.dart';
import '../platform/log_service.dart';
import '../platform/notification_service.dart';
import '../platform/storage_service.dart';
import '../platform/url_service.dart';
import '../providers/app_providers.dart';
import '../screens/error_screen.dart';
import '../theme/app_theme.dart';
import '../utils/global_error_handler.dart';
import 'fatal_error.dart';
import 'gevurah_app.dart';

/// Everything the running app owns.
class AppRuntime {
  AppRuntime({required this.providers, required this.urls, required this.notifications, required this.log, required this.fatal});

  final AppProviders providers;
  final UrlService urls;
  final NotificationService notifications;
  final LogService log;
  final FatalErrorHost fatal;
}

/// Builds the real adapters and the providers, and starts them up.
Future<AppRuntime> buildRuntime() async {
  const SystemClock clock = SystemClock();
  final LogService log = LogService(directory: getApplicationSupportDirectory);
  final FatalErrorHost fatal = FatalErrorHost();
  GlobalErrorHandler.install(fatalErrorSink(fatal, log));
  final StorageService storage = StorageService.create();
  final NotificationService notifications = NotificationService();
  await notifications.initialize();
  final bool android = defaultTargetPlatform == TargetPlatform.android;
  final AdUnitIds ids = AdUnitIds.select(android: android, release: kReleaseMode);
  final HapticsService haptics = HapticsService();
  final AudioService audio = AudioService(log: log);
  final ConsentService consent = ConsentService();

  late final AppProviders providers;
  final AdService ads = AdService(
    driver: GoogleAdsDriver(),
    unitIds: ids,
    canRequestAds: () => providers.consent.canRequestAds,
    adsRemoved: () => providers.entitlement.value.adsRemoved,
    clock: clock,
    log: log,
  );
  providers = AppProviders.create(
    storage: storage,
    clock: clock,
    billing: BillingService(driver: GoogleStoreDriver(), productId: AppConfig.removeAdsProductId, storage: storage, log: log),
    consent: consent,
    ads: ads,
    notifications: notifications,
    verseRepository: VerseRepository(rootBundle.loadString),
    fetchFlags: FlagsService(storage: storage, url: AppConfig.flagsUrl, log: log).load,
    deviceLanguages: WidgetsBinding.instance.platformDispatcher.locales.map((Locale l) => l.languageCode).toList(),
    haptics: haptics,
    audio: audio,
    bannerBuilder: (BuildContext _) => BannerAdView(unitId: ids.banner),
  );
  await providers.startUp();

  void applySettings() {
    final SettingsModel s = providers.settings.settings;
    haptics.enabled = s.hapticsOn;
    audio.setMuted(!s.soundOn);
  }

  providers.settings.addListener(applySettings);
  applySettings();
  return AppRuntime(
    providers: providers,
    urls: UrlService(supportEmail: AppConfig.supportEmail),
    notifications: notifications,
    log: log,
    fatal: fatal,
  );
}

/// Shows nothing while the app starts, the app when it is ready, and the
/// error screen with Retry if start-up fails.
class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key, this.build = buildRuntime});

  final Future<AppRuntime> Function() build;

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  late Future<AppRuntime> _future = _start();

  /// A failure is shown by the builder below, so the future counts as handled.
  Future<AppRuntime> _start() => widget.build()..ignore();

  void _retry() {
    final Future<AppRuntime> next = _start();
    setState(() {
      _future = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppRuntime>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<AppRuntime> snapshot) {
        final AppRuntime? runtime = snapshot.data;
        if (runtime != null) {
          return GevurahApp(
            providers: runtime.providers,
            urls: runtime.urls,
            dailyTaps: runtime.notifications.dailyTaps,
            launchedFromReminder: runtime.notifications.launchedFromNotification,
            fatalErrors: runtime.fatal,
            exportLog: runtime.log.exportText,
          );
        }
        if (snapshot.hasError) {
          return _Plain(
            child: ErrorScreen(
              onRetry: _retry,
              onReport: () => UrlService(supportEmail: AppConfig.supportEmail).openMail(subject: 'Gevurah Boxing problem'),
            ),
          );
        }
        return const _Plain(child: SizedBox.shrink());
      },
    );
  }
}

/// A bare frame for the moments before the app exists: theme, language and
/// direction from the phone.
class _Plain extends StatelessWidget {
  const _Plain({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: const Color(0xFF000000),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[AppLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
      pageRouteBuilder: <T>(RouteSettings s, WidgetBuilder b) => PageRouteBuilder<T>(settings: s, pageBuilder: (BuildContext c, Animation<double> a, Animation<double> x) => b(c)),
      builder: (BuildContext context, Widget? _) => AppTheme.forBrightness(
        brightness: MediaQuery.platformBrightnessOf(context),
        child: child,
      ),
      home: const SizedBox.shrink(),
    );
  }
}
