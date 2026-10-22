import 'package:flutter/widgets.dart';

import 'generated/report_localizations.dart';
import 'generated/report_localizations_en.dart';

export 'generated/report_localizations.dart';

/// Access to the library texts: `context.reportL10n.printTitle`.
///
/// Apps add [ReportLocalizations.delegate] to their localization delegates.
/// When they do not, the English texts are used instead of failing.
extension ReportL10nContext on BuildContext {
  ReportLocalizations get reportL10n =>
      ReportLocalizations.of(this) ?? ReportLocalizationsEn();
}
