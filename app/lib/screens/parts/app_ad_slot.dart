import 'package:flutter/widgets.dart';

import '../../providers/app_providers.dart';
import '../../providers/app_scope.dart';
import '../../widgets/ad_slot.dart';

/// The banner at the foot of a screen. It shows only when the ad provider
/// allows it and the platform has a banner to show.
class AppAdSlot extends StatelessWidget {
  const AppAdSlot({super.key});

  @override
  Widget build(BuildContext context) {
    final AppProviders app = AppScope.of(context);
    return ListenableBuilder(
      listenable: app.ads,
      builder: (BuildContext context, Widget? _) => AdSlot(visible: app.ads.bannerVisible, banner: app.bannerBuilder?.call(context)),
    );
  }
}
