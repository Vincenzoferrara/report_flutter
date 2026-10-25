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

  /// Button saving the PDF where the user chooses; also the title of the save dialog
  ///
  /// In en, this message translates to:
  /// **'Save PDF'**
  String get printSavePdf;

  /// Shown after the PDF was saved through the save dialog
  ///
  /// In en, this message translates to:
  /// **'PDF saved: {file}'**
  String printPdfSaved(String file);

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

  /// builderTabDesigner (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Designer'**
  String get builderTabDesigner;

  /// builderNoElements (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'No elements in the template'**
  String get builderNoElements;

  /// builderNoElementsHelp (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Add elements in the Designer to see the preview'**
  String get builderNoElementsHelp;

  /// builderElements (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Elements'**
  String get builderElements;

  /// builderText (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get builderText;

  /// builderStaticText (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Static text'**
  String get builderStaticText;

  /// builderGroupCodes (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Codes'**
  String get builderGroupCodes;

  /// builderGroupShapes (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Shapes'**
  String get builderGroupShapes;

  /// builderLine (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get builderLine;

  /// builderRectangle (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Rectangle'**
  String get builderRectangle;

  /// builderCircle (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Circle'**
  String get builderCircle;

  /// builderGroupControls (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Controls'**
  String get builderGroupControls;

  /// builderTextbox (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Text box'**
  String get builderTextbox;

  /// builderGroupOther (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get builderGroupOther;

  /// builderImage (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get builderImage;

  /// builderDate (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get builderDate;

  /// builderGroupDataFields (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Data fields'**
  String get builderGroupDataFields;

  /// builderGenericField (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Generic field'**
  String get builderGenericField;

  /// reportFitToScreen (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Fit to screen'**
  String get reportFitToScreen;

  /// reportActualSize (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Actual size'**
  String get reportActualSize;

  /// builderUndo (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Undo (Ctrl+Z)'**
  String get builderUndo;

  /// builderRedo (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Redo (Ctrl+Y)'**
  String get builderRedo;

  /// builderLoadTemplate (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Load template'**
  String get builderLoadTemplate;

  /// builderSaveTemplate (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Save template'**
  String get builderSaveTemplate;

  /// builderExportPdf (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get builderExportPdf;

  /// builderProperties (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Properties'**
  String get builderProperties;

  /// builderSelectElement (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Select an element'**
  String get builderSelectElement;

  /// builderSectionId (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Identifier'**
  String get builderSectionId;

  /// builderSectionPosition (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get builderSectionPosition;

  /// builderSectionSize (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get builderSectionSize;

  /// builderWidthMm (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Width (mm)'**
  String get builderWidthMm;

  /// builderHeightMm (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Height (mm)'**
  String get builderHeightMm;

  /// builderSectionFormatting (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Formatting'**
  String get builderSectionFormatting;

  /// builderFontSizeMm (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Font size (mm)'**
  String get builderFontSizeMm;

  /// builderFontWeight (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Font weight'**
  String get builderFontWeight;

  /// builderHorizontalAlignment (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Horizontal alignment'**
  String get builderHorizontalAlignment;

  /// builderVerticalAlignment (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Vertical alignment'**
  String get builderVerticalAlignment;

  /// builderTextColor (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Text color'**
  String get builderTextColor;

  /// builderBackgroundColor (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Background color'**
  String get builderBackgroundColor;

  /// builderUseMarkdown (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Use Markdown'**
  String get builderUseMarkdown;

  /// builderSectionBorder (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Border'**
  String get builderSectionBorder;

  /// builderBorderWidthMm (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Border width (mm)'**
  String get builderBorderWidthMm;

  /// builderBorderColor (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Border color'**
  String get builderBorderColor;

  /// builderSectionContent (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get builderSectionContent;

  /// builderDataField (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Data field'**
  String get builderDataField;

  /// builderNoDataFieldsSchema (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'No data fields available. Link a data schema to the template.'**
  String get builderNoDataFieldsSchema;

  /// builderField (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Field'**
  String get builderField;

  /// builderPrefix (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Prefix'**
  String get builderPrefix;

  /// builderSuffix (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Suffix'**
  String get builderSuffix;

  /// builderType (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get builderType;

  /// builderShowText (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Show text'**
  String get builderShowText;

  /// builderBorderRadiusMm (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Corner radius (mm)'**
  String get builderBorderRadiusMm;

  /// builderFillColor (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Fill color'**
  String get builderFillColor;

  /// builderThicknessMm (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Thickness (mm)'**
  String get builderThicknessMm;

  /// builderColor (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get builderColor;

  /// builderSource (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get builderSource;

  /// builderNoDataFields (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'No data fields available.'**
  String get builderNoDataFields;

  /// builderImageField (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Image field'**
  String get builderImageField;

  /// builderAssetPath (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Asset path'**
  String get builderAssetPath;

  /// builderImageUrl (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Image URL'**
  String get builderImageUrl;

  /// builderFit (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Fit'**
  String get builderFit;

  /// builderBooleanField (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Boolean field'**
  String get builderBooleanField;

  /// builderLabel (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get builderLabel;

  /// builderSizeMm (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Size (mm)'**
  String get builderSizeMm;

  /// builderMaxLines (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Max lines'**
  String get builderMaxLines;

  /// builderNone (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get builderNone;

  /// builderSelectColor (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Select color'**
  String get builderSelectColor;

  /// builderPageSize (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Page size'**
  String get builderPageSize;

  /// builderPortrait (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Portrait'**
  String get builderPortrait;

  /// builderLandscape (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Landscape'**
  String get builderLandscape;

  /// builderCard (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get builderCard;

  /// builderApply (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get builderApply;

  /// builderTemplateLoaded (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Template loaded'**
  String get builderTemplateLoaded;

  /// builderTemplateLoadError (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Could not load the template: {error}'**
  String builderTemplateLoadError(String error);

  /// builderPdfExported (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'PDF exported'**
  String get builderPdfExported;

  /// builderPdfExportError (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Could not export the PDF: {error}'**
  String builderPdfExportError(String error);

  /// builderFormulaHelp (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Excel-like syntax, with {example} for the data'**
  String builderFormulaHelp(String example);

  /// builderVariables (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Variables:'**
  String get builderVariables;

  /// builderOutputFormat (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Output format'**
  String get builderOutputFormat;

  /// builderErrorValue (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Error value'**
  String get builderErrorValue;

  /// builderErrorValueHint (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Value shown on error'**
  String get builderErrorValueHint;

  /// builderNoFields (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'No fields available'**
  String get builderNoFields;

  /// builderAddVariable (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Add variable'**
  String get builderAddVariable;

  /// builderEnableMarkdown (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Enable Markdown rendering'**
  String get builderEnableMarkdown;

  /// builderMarkdownContent (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Markdown content'**
  String get builderMarkdownContent;

  /// builderMarkdownHint (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'# Title\n\n**Bold** text'**
  String get builderMarkdownHint;

  /// builderAutoToc (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Automatic table of contents'**
  String get builderAutoToc;

  /// builderAutoTocHelp (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Builds a table of contents from the headings'**
  String get builderAutoTocHelp;

  /// builderSyntaxHighlighting (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Syntax highlighting'**
  String get builderSyntaxHighlighting;

  /// builderSyntaxHighlightingHelp (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Highlights code blocks'**
  String get builderSyntaxHighlightingHelp;

  /// builderTheme (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get builderTheme;

  /// builderConditionalFormatting (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Conditional formatting'**
  String get builderConditionalFormatting;

  /// builderEnableConditionalFormatting (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Enable conditional formatting'**
  String get builderEnableConditionalFormatting;

  /// builderConditionalFormattingHelp (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Changes the style based on the value'**
  String get builderConditionalFormattingHelp;

  /// builderAddRule (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Add rule'**
  String get builderAddRule;

  /// builderRuleNumber (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Rule {number}'**
  String builderRuleNumber(int number);

  /// builderCondition (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get builderCondition;

  /// builderValue (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get builderValue;

  /// builderSearchText (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Text to find'**
  String get builderSearchText;

  /// builderConditionalImages (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Conditional images:'**
  String get builderConditionalImages;

  /// builderAddImageRule (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Add image rule'**
  String get builderAddImageRule;

  /// builderImageRuleNumber (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Image rule {number}'**
  String builderImageRuleNumber(int number);

  /// builderImageFieldIfTrue (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Image field (if true)'**
  String get builderImageFieldIfTrue;

  /// builderImageFieldIfTrueHint (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Data field that holds the image'**
  String get builderImageFieldIfTrueHint;

  /// builderFallbackImage (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Fallback image (if false)'**
  String get builderFallbackImage;

  /// builderFallbackImageHint (report_builder.dart)
  ///
  /// In en, this message translates to:
  /// **'Default asset path'**
  String get builderFallbackImageHint;

  /// viewerValidationFailed (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'Data validation failed: {error}'**
  String viewerValidationFailed(String error);

  /// viewerLoadingTemplate (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'Loading template...'**
  String get viewerLoadingTemplate;

  /// viewerError (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get viewerError;

  /// viewerRetry (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get viewerRetry;

  /// viewerNoTemplate (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'No template loaded'**
  String get viewerNoTemplate;

  /// viewerNoData (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'No data to display'**
  String get viewerNoData;

  /// viewerPreviousPage (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get viewerPreviousPage;

  /// viewerNextPage (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get viewerNextPage;

  /// viewerZoomOut (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get viewerZoomOut;

  /// viewerZoomIn (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get viewerZoomIn;

  /// viewerMenu (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get viewerMenu;

  /// viewerRefreshData (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'Refresh data'**
  String get viewerRefreshData;

  /// viewerExportReport (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'Export report'**
  String get viewerExportReport;

  /// viewerSettings (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get viewerSettings;

  /// viewerSinglePage (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'Single page'**
  String get viewerSinglePage;

  /// viewerContinuousScroll (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'Continuous scroll'**
  String get viewerContinuousScroll;

  /// viewerTwoPages (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'Two-page view'**
  String get viewerTwoPages;

  /// viewerRefreshing (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'Refreshing...'**
  String get viewerRefreshing;

  /// viewerExport (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get viewerExport;

  /// viewerAnnotations (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'Annotations'**
  String get viewerAnnotations;

  /// viewerSidebar (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'Sidebar'**
  String get viewerSidebar;

  /// viewerRecordCount (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 record} other{{count} records}}'**
  String viewerRecordCount(int count);

  /// viewerActiveFilters (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 active filter} other{{count} active filters}}'**
  String viewerActiveFilters(int count);

  /// viewerFirstPage (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'First page'**
  String get viewerFirstPage;

  /// viewerLastPage (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'Last page'**
  String get viewerLastPage;

  /// viewerDataRefreshed (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'Data refreshed from {source}'**
  String viewerDataRefreshed(String source);

  /// viewerRefreshError (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'Could not refresh the data: {error}'**
  String viewerRefreshError(String error);

  /// viewerExportPdfHelp (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'Export as a PDF document'**
  String get viewerExportPdfHelp;

  /// viewerExportExcelHelp (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'Export as a spreadsheet'**
  String get viewerExportExcelHelp;

  /// viewerExportCsvHelp (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'Export as a CSV file'**
  String get viewerExportCsvHelp;

  /// viewerPdfExportNotReady (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'PDF export is not available yet'**
  String get viewerPdfExportNotReady;

  /// viewerExportDone (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'{format} saved: {file}'**
  String viewerExportDone(String format, String file);

  /// viewerOpen (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get viewerOpen;

  /// viewerExportError (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'{format} export failed: {error}'**
  String viewerExportError(String format, String error);

  /// viewerPrintNotReady (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'Printing is not available yet'**
  String get viewerPrintNotReady;

  /// viewerSettingsTitle (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'Viewer settings'**
  String get viewerSettingsTitle;

  /// viewerSettingsNotReady (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'Settings are not available yet'**
  String get viewerSettingsNotReady;

  /// viewerActiveAnnotations (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'Active annotations ({count})'**
  String viewerActiveAnnotations(int count);

  /// viewerManage (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get viewerManage;

  /// viewerReportAnnotations (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'Report annotations'**
  String get viewerReportAnnotations;

  /// viewerNoAnnotations (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'No annotations'**
  String get viewerNoAnnotations;

  /// viewerAnnotationDeleted (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'Annotation deleted'**
  String get viewerAnnotationDeleted;

  /// viewerDeleteError (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'Could not delete: {error}'**
  String viewerDeleteError(String error);

  /// viewerErrorDetail (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String viewerErrorDetail(String error);

  /// viewerTemplateNotFound (report_viewer.dart)
  ///
  /// In en, this message translates to:
  /// **'Template not found'**
  String get viewerTemplateNotFound;

  /// sidebarTitle (report_sidebar.dart)
  ///
  /// In en, this message translates to:
  /// **'Report panel'**
  String get sidebarTitle;

  /// sidebarFilters (report_sidebar.dart)
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get sidebarFilters;

  /// sidebarParameters (report_sidebar.dart)
  ///
  /// In en, this message translates to:
  /// **'Parameters'**
  String get sidebarParameters;

  /// sidebarPages (report_sidebar.dart)
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get sidebarPages;

  /// sidebarFiltersDisabled (report_sidebar.dart)
  ///
  /// In en, this message translates to:
  /// **'Filters are not enabled'**
  String get sidebarFiltersDisabled;

  /// sidebarDataFilters (report_sidebar.dart)
  ///
  /// In en, this message translates to:
  /// **'Data filters'**
  String get sidebarDataFilters;

  /// sidebarClear (report_sidebar.dart)
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get sidebarClear;

  /// sidebarAddFilter (report_sidebar.dart)
  ///
  /// In en, this message translates to:
  /// **'Add filter'**
  String get sidebarAddFilter;

  /// sidebarNoFilters (report_sidebar.dart)
  ///
  /// In en, this message translates to:
  /// **'No filters set'**
  String get sidebarNoFilters;

  /// sidebarNoFiltersHelp (report_sidebar.dart)
  ///
  /// In en, this message translates to:
  /// **'Add filters to narrow the report data'**
  String get sidebarNoFiltersHelp;

  /// sidebarParametersDisabled (report_sidebar.dart)
  ///
  /// In en, this message translates to:
  /// **'Parameters are not enabled'**
  String get sidebarParametersDisabled;

  /// sidebarReportParameters (report_sidebar.dart)
  ///
  /// In en, this message translates to:
  /// **'Report parameters'**
  String get sidebarReportParameters;

  /// sidebarAddParameter (report_sidebar.dart)
  ///
  /// In en, this message translates to:
  /// **'Add parameter'**
  String get sidebarAddParameter;

  /// sidebarNoParameters (report_sidebar.dart)
  ///
  /// In en, this message translates to:
  /// **'No parameters set'**
  String get sidebarNoParameters;

  /// sidebarNoParametersHelp (report_sidebar.dart)
  ///
  /// In en, this message translates to:
  /// **'Add parameters to customize the report'**
  String get sidebarNoParametersHelp;

  /// sidebarPageThumbnails (report_sidebar.dart)
  ///
  /// In en, this message translates to:
  /// **'Page thumbnails'**
  String get sidebarPageThumbnails;

  /// sidebarNoPages (report_sidebar.dart)
  ///
  /// In en, this message translates to:
  /// **'No pages available'**
  String get sidebarNoPages;

  /// sidebarPageNumber (report_sidebar.dart)
  ///
  /// In en, this message translates to:
  /// **'Page {number}'**
  String sidebarPageNumber(int number);

  /// sidebarOpEquals (report_sidebar.dart)
  ///
  /// In en, this message translates to:
  /// **'Equals'**
  String get sidebarOpEquals;

  /// sidebarOpContains (report_sidebar.dart)
  ///
  /// In en, this message translates to:
  /// **'Contains'**
  String get sidebarOpContains;

  /// sidebarOpGreater (report_sidebar.dart)
  ///
  /// In en, this message translates to:
  /// **'Greater than'**
  String get sidebarOpGreater;

  /// sidebarOpLess (report_sidebar.dart)
  ///
  /// In en, this message translates to:
  /// **'Less than'**
  String get sidebarOpLess;

  /// sidebarOpBetween (report_sidebar.dart)
  ///
  /// In en, this message translates to:
  /// **'Between'**
  String get sidebarOpBetween;

  /// sidebarNotReady (report_sidebar.dart)
  ///
  /// In en, this message translates to:
  /// **'Not available yet'**
  String get sidebarNotReady;

  /// sidebarEditParameter (report_sidebar.dart)
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String sidebarEditParameter(String name);

  /// sidebarCurrentValue (report_sidebar.dart)
  ///
  /// In en, this message translates to:
  /// **'Current value: {value}'**
  String sidebarCurrentValue(String value);

  /// tableSelected (interactive_table.dart)
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String tableSelected(int count);

  /// tableSortedBy (interactive_table.dart)
  ///
  /// In en, this message translates to:
  /// **'Sorted by {column}'**
  String tableSortedBy(String column);

  /// tableTotalRows (interactive_table.dart)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 row} other{{count} rows}}'**
  String tableTotalRows(int count);

  /// tableExportSelected (interactive_table.dart)
  ///
  /// In en, this message translates to:
  /// **'Export selected'**
  String get tableExportSelected;

  /// tableClickToSort (interactive_table.dart)
  ///
  /// In en, this message translates to:
  /// **'Click to sort'**
  String get tableClickToSort;

  /// tableExportNotReady (interactive_table.dart)
  ///
  /// In en, this message translates to:
  /// **'Exporting {count} records is not available yet'**
  String tableExportNotReady(int count);

  /// chartNoData (interactive_chart.dart)
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get chartNoData;

  /// chartBar (interactive_chart.dart)
  ///
  /// In en, this message translates to:
  /// **'Bar chart'**
  String get chartBar;

  /// chartLine (interactive_chart.dart)
  ///
  /// In en, this message translates to:
  /// **'Line chart'**
  String get chartLine;

  /// chartPie (interactive_chart.dart)
  ///
  /// In en, this message translates to:
  /// **'Pie chart'**
  String get chartPie;

  /// chartArea (interactive_chart.dart)
  ///
  /// In en, this message translates to:
  /// **'Area chart'**
  String get chartArea;

  /// chartScatter (interactive_chart.dart)
  ///
  /// In en, this message translates to:
  /// **'Scatter chart'**
  String get chartScatter;

  /// chartDataPoint (interactive_chart.dart)
  ///
  /// In en, this message translates to:
  /// **'Data point'**
  String get chartDataPoint;

  /// annotationDefaultAuthor (annotation_service.dart)
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get annotationDefaultAuthor;

  /// annotationNewTitle (annotation_service.dart)
  ///
  /// In en, this message translates to:
  /// **'New annotation (temporary)'**
  String get annotationNewTitle;

  /// annotationEditTitle (annotation_service.dart)
  ///
  /// In en, this message translates to:
  /// **'Edit annotation'**
  String get annotationEditTitle;

  /// annotationTemporaryNotice (annotation_service.dart)
  ///
  /// In en, this message translates to:
  /// **'This annotation is temporary and is lost when you close the report'**
  String get annotationTemporaryNotice;

  /// annotationContentHint (annotation_service.dart)
  ///
  /// In en, this message translates to:
  /// **'Write your annotation here...'**
  String get annotationContentHint;

  /// annotationAuthor (annotation_service.dart)
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get annotationAuthor;

  /// annotationAdd (annotation_service.dart)
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get annotationAdd;

  /// annotationContentRequired (annotation_service.dart)
  ///
  /// In en, this message translates to:
  /// **'The content cannot be empty'**
  String get annotationContentRequired;

  /// annotationTypeNote (annotation_service.dart)
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get annotationTypeNote;

  /// annotationTypeHighlight (annotation_service.dart)
  ///
  /// In en, this message translates to:
  /// **'Highlight'**
  String get annotationTypeHighlight;

  /// annotationTypeComment (annotation_service.dart)
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get annotationTypeComment;

  /// annotationTypeQuestion (annotation_service.dart)
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get annotationTypeQuestion;

  /// annotationTypeIssue (annotation_service.dart)
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get annotationTypeIssue;
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
