import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'report_localizations_en.dart';
import 'report_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of ReportLocalizations
/// returned by `ReportLocalizations.of(context)`.
///
/// Applications need to include `ReportLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/report_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: ReportLocalizations.localizationsDelegates,
///   supportedLocales: ReportLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the ReportLocalizations.supportedLocales
/// property.
abstract class ReportLocalizations {
  ReportLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static ReportLocalizations? of(BuildContext context) {
    return Localizations.of<ReportLocalizations>(context, ReportLocalizations);
  }

  static const LocalizationsDelegate<ReportLocalizations> delegate =
      _ReportLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
  ];

  /// Title of the labels, signs and reports screen
  ///
  /// In en, this message translates to:
  /// **'Templates and print'**
  String get printPrintCenterTitle;

  /// Title of wizard step 2
  ///
  /// In en, this message translates to:
  /// **'Choose a template'**
  String get printTemplateQuestion;

  /// Tooltip of the template menu
  ///
  /// In en, this message translates to:
  /// **'Template options'**
  String get printTemplateActions;

  /// Menu action that renames a template
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get printRename;

  /// Title of the delete template dialog
  ///
  /// In en, this message translates to:
  /// **'Delete template'**
  String get printDeleteTemplateTitle;

  /// Body of the delete template dialog
  ///
  /// In en, this message translates to:
  /// **'Delete the template \"{name}\"? The ready-made templates are not affected.'**
  String printDeleteTemplateMessage(String name);

  /// Label of the template name field
  ///
  /// In en, this message translates to:
  /// **'Template name'**
  String get printTemplateNameLabel;

  /// Confirmation after saving a template
  ///
  /// In en, this message translates to:
  /// **'Template \"{name}\" saved'**
  String printTemplateSaved(String name);

  /// Button saving or sharing the PDF
  ///
  /// In en, this message translates to:
  /// **'Save PDF'**
  String get printSavePdf;

  /// Error shown when printing or saving fails
  ///
  /// In en, this message translates to:
  /// **'Printing failed: {error}'**
  String printPrintError(String error);

  /// Title of the preview panel
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get printPreviewTitle;

  /// Preview switch: show a single label enlarged
  ///
  /// In en, this message translates to:
  /// **'One'**
  String get printPreviewOneLabel;

  /// Preview switch: show the whole sheet
  ///
  /// In en, this message translates to:
  /// **'Whole sheet'**
  String get printPreviewWholeSheet;

  /// Notice under the preview title
  ///
  /// In en, this message translates to:
  /// **'Example data: the print will look exactly like this.'**
  String get printPreviewSampleNotice;

  /// Notice under the preview title when the whole sheet is shown
  ///
  /// In en, this message translates to:
  /// **'Dashed lines and grey boxes show the label edges and the used positions: they are not printed.'**
  String get printPreviewSheetNotice;

  /// Editor section: number of copies
  ///
  /// In en, this message translates to:
  /// **'How many'**
  String get printSectionQuantity;

  /// Editor section: paper format
  ///
  /// In en, this message translates to:
  /// **'Paper format'**
  String get printSectionPaper;

  /// Label of the copies stepper
  ///
  /// In en, this message translates to:
  /// **'How many copies to print?'**
  String get printCopiesQuestion;

  /// Chip filling a whole sheet of labels
  ///
  /// In en, this message translates to:
  /// **'Whole sheet ({count})'**
  String printFullSheet(int count);

  /// Label of the skipped positions stepper
  ///
  /// In en, this message translates to:
  /// **'Positions already used on each sheet'**
  String get printSkipQuestion;

  /// Help of the skipped positions stepper
  ///
  /// In en, this message translates to:
  /// **'For each sheet, enter how many labels are missing at the start: printing on that sheet begins right after them. Rolls always start from the first label.'**
  String get printSkipHelp;

  /// Number of sheets the print needs
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 sheet to print} other{{count} sheets to print}}'**
  String printSheetsNeeded(int count);

  /// Tooltip of the minus button
  ///
  /// In en, this message translates to:
  /// **'Decrease'**
  String get printDecrease;

  /// Tooltip of the plus button
  ///
  /// In en, this message translates to:
  /// **'Increase'**
  String get printIncrease;

  /// Paper group title
  ///
  /// In en, this message translates to:
  /// **'Adhesive A4 sheets (normal printer)'**
  String get printPaperGroupSheets;

  /// Paper group title
  ///
  /// In en, this message translates to:
  /// **'Roll (label printer)'**
  String get printPaperGroupRolls;

  /// Paper format: adhesive A4 sheet
  ///
  /// In en, this message translates to:
  /// **'A4 sheet · {count} labels {size} mm'**
  String printPaperLabelSheet(int count, String size);

  /// Paper format: thermal roll
  ///
  /// In en, this message translates to:
  /// **'Roll · label {size} mm'**
  String printPaperRoll(String size);

  /// Paper format
  ///
  /// In en, this message translates to:
  /// **'A4 portrait · 1 per sheet'**
  String get printPaperSignA4Portrait;

  /// Paper format
  ///
  /// In en, this message translates to:
  /// **'A4 landscape · 1 per sheet'**
  String get printPaperSignA4Landscape;

  /// Paper format
  ///
  /// In en, this message translates to:
  /// **'A5 · 2 per A4 sheet'**
  String get printPaperSignA5;

  /// Paper format
  ///
  /// In en, this message translates to:
  /// **'A6 · 4 per A4 sheet'**
  String get printPaperSignA6;

  /// Button opening the drag-and-drop designer
  ///
  /// In en, this message translates to:
  /// **'Edit template'**
  String get printEditDesign;

  /// Title of the designer screen
  ///
  /// In en, this message translates to:
  /// **'Edit: {name}'**
  String printDesignerTitle(String name);

  /// Button closing the designer and applying the layout
  ///
  /// In en, this message translates to:
  /// **'Use these changes'**
  String get printApplyDesign;

  /// Title of the dialog shown when closing the designer with changes
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get printDiscardDesignTitle;

  /// Body of the discard changes dialog
  ///
  /// In en, this message translates to:
  /// **'The changes made in the designer will be lost.'**
  String get printDiscardDesignMessage;

  /// Button that keeps the designer open
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get printKeepEditing;

  /// Button that closes the designer without applying
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get printDiscardDesign;

  /// Tab that prints templates
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get printTabPrint;

  /// Tab that manages templates
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get printTabTemplates;

  /// Reloads the print library from the server
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get printReload;

  /// Shown when the print library cannot be loaded
  ///
  /// In en, this message translates to:
  /// **'Templates could not be loaded from the server. Check the connection and try again.'**
  String get printLoadError;

  /// Help of the Print tab
  ///
  /// In en, this message translates to:
  /// **'Tap a template to see the preview and print.'**
  String get printPrintHelp;

  /// Title of the Print tab when printing labels for products
  ///
  /// In en, this message translates to:
  /// **'Choose the label template'**
  String get printJobTemplateQuestion;

  /// Summary of the labels requested from the products list
  ///
  /// In en, this message translates to:
  /// **'Labels for {products, plural, =1{1 item} other{{products} items}}: {labels, plural, =1{1 label} other{{labels} labels}}'**
  String printJobSummary(int products, int labels);

  /// Discards the labels requested from the products list
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get printJobCancel;

  /// Section with the labels per product
  ///
  /// In en, this message translates to:
  /// **'Labels to print'**
  String get printJobLabelsTitle;

  /// Help of the labels per product
  ///
  /// In en, this message translates to:
  /// **'One label per piece in stock. Variants without pieces are not listed.'**
  String get printJobQuantityHelp;

  /// Back to the template list
  ///
  /// In en, this message translates to:
  /// **'Change template'**
  String get printChangeTemplate;

  /// Notice above the preview of real product labels
  ///
  /// In en, this message translates to:
  /// **'Product data: the print will look exactly like this.'**
  String get printPreviewRealNotice;

  /// Shown when the library has no templates
  ///
  /// In en, this message translates to:
  /// **'There are no templates yet.'**
  String get printNoTemplates;

  /// Group of templates without a category
  ///
  /// In en, this message translates to:
  /// **'No category'**
  String get printNoCategory;

  /// Shown under an empty category
  ///
  /// In en, this message translates to:
  /// **'No templates in this category.'**
  String get printEmptyCategory;

  /// Notice for staff without management rights
  ///
  /// In en, this message translates to:
  /// **'Only shop managers can create, change or delete templates, categories and paper formats.'**
  String get printManagersOnly;

  /// Button that creates a template
  ///
  /// In en, this message translates to:
  /// **'New template'**
  String get printNewTemplate;

  /// Button that creates a category
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get printNewCategory;

  /// Button and title of the paper formats page
  ///
  /// In en, this message translates to:
  /// **'Paper formats'**
  String get printPaperFormats;

  /// Template action
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get printDuplicate;

  /// Template action
  ///
  /// In en, this message translates to:
  /// **'Move to category'**
  String get printMoveToCategory;

  /// Name of a duplicated template
  ///
  /// In en, this message translates to:
  /// **'Copy of {name}'**
  String printCopyOf(String name);

  /// Confirmation after deleting a template
  ///
  /// In en, this message translates to:
  /// **'Template \"{name}\" deleted'**
  String printTemplateDeleted(String name);

  /// Error when a change is refused by the server
  ///
  /// In en, this message translates to:
  /// **'Not saved on the server: {error}'**
  String printSaveError(String error);

  /// Tooltip of the category menu
  ///
  /// In en, this message translates to:
  /// **'Category options'**
  String get printCategoryActions;

  /// Category action
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get printMoveUp;

  /// Category action
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get printMoveDown;

  /// Label of the category name field
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get printCategoryNameLabel;

  /// Confirmation after saving a category
  ///
  /// In en, this message translates to:
  /// **'Category \"{name}\" saved'**
  String printCategorySaved(String name);

  /// Confirmation after deleting a category
  ///
  /// In en, this message translates to:
  /// **'Category \"{name}\" deleted'**
  String printCategoryDeleted(String name);

  /// Title of the delete category dialog
  ///
  /// In en, this message translates to:
  /// **'Delete category'**
  String get printDeleteCategoryTitle;

  /// Body of the delete category dialog
  ///
  /// In en, this message translates to:
  /// **'Delete the category \"{name}\"? Its templates are kept and listed under \"No category\".'**
  String printDeleteCategoryMessage(String name);

  /// Label of the category choice
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get printCategoryLabel;

  /// Creates the template and opens the designer
  ///
  /// In en, this message translates to:
  /// **'Open the designer'**
  String get printOpenDesigner;

  /// Help of the paper formats page
  ///
  /// In en, this message translates to:
  /// **'Sheets and rolls used by the templates. Every measure is in millimetres.'**
  String get printPaperFormatsHelp;

  /// Button and dialog title
  ///
  /// In en, this message translates to:
  /// **'New paper format'**
  String get printNewPaperFormat;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Edit paper format'**
  String get printEditPaperFormat;

  /// Confirmation after saving a paper format
  ///
  /// In en, this message translates to:
  /// **'Paper format \"{name}\" saved'**
  String printPaperFormatSaved(String name);

  /// Title of the delete paper format dialog
  ///
  /// In en, this message translates to:
  /// **'Delete paper format'**
  String get printDeletePaperFormatTitle;

  /// Body of the delete paper format dialog
  ///
  /// In en, this message translates to:
  /// **'Delete the paper format \"{name}\"?'**
  String printDeletePaperFormatMessage(String name);

  /// Body of the delete dialog when templates use the format
  ///
  /// In en, this message translates to:
  /// **'Delete the paper format \"{name}\"? {count, plural, =1{1 template uses it and will print} other{{count} templates use it and will print}} on a page the size of the template until you choose another format.'**
  String printDeletePaperFormatUsedMessage(String name, int count);

  /// Shown when a type has no paper format
  ///
  /// In en, this message translates to:
  /// **'No paper format for this type: add one in Paper formats.'**
  String get printPaperMissing;

  /// Label of the paper format name
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get printPaperNameLabel;

  /// Helper of the paper format name
  ///
  /// In en, this message translates to:
  /// **'Leave empty to show the measures.'**
  String get printPaperNameHelp;

  /// Paper feed option
  ///
  /// In en, this message translates to:
  /// **'Sheet'**
  String get printPaperFeedSheet;

  /// Paper feed option
  ///
  /// In en, this message translates to:
  /// **'Roll'**
  String get printPaperFeedRoll;

  /// Section title in the paper format dialog
  ///
  /// In en, this message translates to:
  /// **'Label size (mm)'**
  String get printPaperLabelSizeTitle;

  /// Section title in the paper format dialog
  ///
  /// In en, this message translates to:
  /// **'Size of each label or sign (mm)'**
  String get printPaperCellSizeTitle;

  /// Section title in the paper format dialog
  ///
  /// In en, this message translates to:
  /// **'Sheet size (mm)'**
  String get printPaperPageTitle;

  /// Section title in the paper format dialog
  ///
  /// In en, this message translates to:
  /// **'Layout on the sheet'**
  String get printPaperGridTitle;

  /// Paper format field
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get printPaperWidth;

  /// Paper format field
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get printPaperHeight;

  /// Paper format field
  ///
  /// In en, this message translates to:
  /// **'Columns'**
  String get printPaperColumns;

  /// Paper format field
  ///
  /// In en, this message translates to:
  /// **'Rows'**
  String get printPaperRows;

  /// Paper format field
  ///
  /// In en, this message translates to:
  /// **'Top margin'**
  String get printPaperMarginTop;

  /// Paper format field
  ///
  /// In en, this message translates to:
  /// **'Left margin'**
  String get printPaperMarginLeft;

  /// Paper format field
  ///
  /// In en, this message translates to:
  /// **'Gap between columns'**
  String get printPaperGapX;

  /// Paper format field
  ///
  /// In en, this message translates to:
  /// **'Gap between rows'**
  String get printPaperGapY;

  /// Paper format validation error
  ///
  /// In en, this message translates to:
  /// **'Enter the size of the sheet and of each label.'**
  String get printPaperErrorSize;

  /// Paper format validation error
  ///
  /// In en, this message translates to:
  /// **'Columns must be 1 to 20 and rows 1 to 40.'**
  String get printPaperErrorGrid;

  /// Paper format validation error
  ///
  /// In en, this message translates to:
  /// **'The labels do not fit on the sheet: check sizes, margins and gaps.'**
  String get printPaperErrorOutside;

  /// Description of a sheet paper format
  ///
  /// In en, this message translates to:
  /// **'Sheet {page} mm · {count} × {cell} mm'**
  String printPaperSheetDescription(String page, int count, String cell);

  /// Labels printed for one product or variant
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 label} other{{count} labels}}'**
  String printJobLabelCount(int count);

  /// Tooltip of the button removing a product or variant from the labels
  ///
  /// In en, this message translates to:
  /// **'Remove from the labels'**
  String get printJobRemove;

  /// Shown when every line was removed
  ///
  /// In en, this message translates to:
  /// **'No labels left to print.'**
  String get printJobEmpty;

  /// Label of one sheet in the positions already used list
  ///
  /// In en, this message translates to:
  /// **'Sheet {number}'**
  String printSheetNumber(int number);

  /// Help above the add label button when printing example labels
  ///
  /// In en, this message translates to:
  /// **'To print labels of real products, add them from the catalogue.'**
  String get printAddLabelsHelp;

  /// Shown when every chosen variant is already listed
  ///
  /// In en, this message translates to:
  /// **'The chosen products are already in the labels.'**
  String get printAddLabelsAlreadyListed;

  /// Common action label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get printCancel;

  /// Common action label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get printDelete;

  /// Common action label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get printSave;

  /// Common action label
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get printPrint;

  /// Common action label
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get printClose;

  /// Error shown in the preview panel
  ///
  /// In en, this message translates to:
  /// **'Preview not available: {error}'**
  String printPreviewError(String error);

  /// Opens the product picker to add products to the labels
  ///
  /// In en, this message translates to:
  /// **'Add label'**
  String get printAddLabels;
}

class _ReportLocalizationsDelegate
    extends LocalizationsDelegate<ReportLocalizations> {
  const _ReportLocalizationsDelegate();

  @override
  Future<ReportLocalizations> load(Locale locale) {
    return SynchronousFuture<ReportLocalizations>(
      lookupReportLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_ReportLocalizationsDelegate old) => false;
}

ReportLocalizations lookupReportLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return ReportLocalizationsEn();
    case 'it':
      return ReportLocalizationsIt();
  }

  throw FlutterError(
    'ReportLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
