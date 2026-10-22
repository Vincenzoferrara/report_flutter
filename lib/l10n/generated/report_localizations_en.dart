// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'report_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class ReportLocalizationsEn extends ReportLocalizations {
  ReportLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get printPrintCenterTitle => 'Templates and print';

  @override
  String get printTemplateQuestion => 'Choose a template';

  @override
  String get printTemplateActions => 'Template options';

  @override
  String get printRename => 'Rename';

  @override
  String get printDeleteTemplateTitle => 'Delete template';

  @override
  String printDeleteTemplateMessage(String name) {
    return 'Delete the template \"$name\"? The ready-made templates are not affected.';
  }

  @override
  String get printTemplateNameLabel => 'Template name';

  @override
  String printTemplateSaved(String name) {
    return 'Template \"$name\" saved';
  }

  @override
  String get printSavePdf => 'Save PDF';

  @override
  String printPrintError(String error) {
    return 'Printing failed: $error';
  }

  @override
  String get printPreviewTitle => 'Preview';

  @override
  String get printPreviewOneLabel => 'One';

  @override
  String get printPreviewWholeSheet => 'Whole sheet';

  @override
  String get printPreviewSampleNotice =>
      'Example data: the print will look exactly like this.';

  @override
  String get printPreviewSheetNotice =>
      'Dashed lines and grey boxes show the label edges and the used positions: they are not printed.';

  @override
  String get printSectionQuantity => 'How many';

  @override
  String get printSectionPaper => 'Paper format';

  @override
  String get printCopiesQuestion => 'How many copies to print?';

  @override
  String printFullSheet(int count) {
    return 'Whole sheet ($count)';
  }

  @override
  String get printSkipQuestion => 'Positions already used on each sheet';

  @override
  String get printSkipHelp =>
      'For each sheet, enter how many labels are missing at the start: printing on that sheet begins right after them. Rolls always start from the first label.';

  @override
  String printSheetsNeeded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sheets to print',
      one: '1 sheet to print',
    );
    return '$_temp0';
  }

  @override
  String get printDecrease => 'Decrease';

  @override
  String get printIncrease => 'Increase';

  @override
  String get printPaperGroupSheets => 'Adhesive A4 sheets (normal printer)';

  @override
  String get printPaperGroupRolls => 'Roll (label printer)';

  @override
  String printPaperLabelSheet(int count, String size) {
    return 'A4 sheet · $count labels $size mm';
  }

  @override
  String printPaperRoll(String size) {
    return 'Roll · label $size mm';
  }

  @override
  String get printPaperSignA4Portrait => 'A4 portrait · 1 per sheet';

  @override
  String get printPaperSignA4Landscape => 'A4 landscape · 1 per sheet';

  @override
  String get printPaperSignA5 => 'A5 · 2 per A4 sheet';

  @override
  String get printPaperSignA6 => 'A6 · 4 per A4 sheet';

  @override
  String get printEditDesign => 'Edit template';

  @override
  String printDesignerTitle(String name) {
    return 'Edit: $name';
  }

  @override
  String get printApplyDesign => 'Use these changes';

  @override
  String get printDiscardDesignTitle => 'Discard changes?';

  @override
  String get printDiscardDesignMessage =>
      'The changes made in the designer will be lost.';

  @override
  String get printKeepEditing => 'Keep editing';

  @override
  String get printDiscardDesign => 'Discard';

  @override
  String get printTabPrint => 'Print';

  @override
  String get printTabTemplates => 'Templates';

  @override
  String get printReload => 'Reload';

  @override
  String get printLoadError =>
      'Templates could not be loaded from the server. Check the connection and try again.';

  @override
  String get printPrintHelp => 'Tap a template to see the preview and print.';

  @override
  String get printJobTemplateQuestion => 'Choose the label template';

  @override
  String printJobSummary(int products, int labels) {
    String _temp0 = intl.Intl.pluralLogic(
      products,
      locale: localeName,
      other: '$products items',
      one: '1 item',
    );
    String _temp1 = intl.Intl.pluralLogic(
      labels,
      locale: localeName,
      other: '$labels labels',
      one: '1 label',
    );
    return 'Labels for $_temp0: $_temp1';
  }

  @override
  String get printJobCancel => 'Cancel';

  @override
  String get printJobLabelsTitle => 'Labels to print';

  @override
  String get printJobQuantityHelp =>
      'One label per piece in stock. Variants without pieces are not listed.';

  @override
  String get printChangeTemplate => 'Change template';

  @override
  String get printPreviewRealNotice =>
      'Product data: the print will look exactly like this.';

  @override
  String get printNoTemplates => 'There are no templates yet.';

  @override
  String get printNoCategory => 'No category';

  @override
  String get printEmptyCategory => 'No templates in this category.';

  @override
  String get printManagersOnly =>
      'Only shop managers can create, change or delete templates, categories and paper formats.';

  @override
  String get printNewTemplate => 'New template';

  @override
  String get printNewCategory => 'New category';

  @override
  String get printPaperFormats => 'Paper formats';

  @override
  String get printDuplicate => 'Duplicate';

  @override
  String get printMoveToCategory => 'Move to category';

  @override
  String printCopyOf(String name) {
    return 'Copy of $name';
  }

  @override
  String printTemplateDeleted(String name) {
    return 'Template \"$name\" deleted';
  }

  @override
  String printSaveError(String error) {
    return 'Not saved on the server: $error';
  }

  @override
  String get printCategoryActions => 'Category options';

  @override
  String get printMoveUp => 'Move up';

  @override
  String get printMoveDown => 'Move down';

  @override
  String get printCategoryNameLabel => 'Category name';

  @override
  String printCategorySaved(String name) {
    return 'Category \"$name\" saved';
  }

  @override
  String printCategoryDeleted(String name) {
    return 'Category \"$name\" deleted';
  }

  @override
  String get printDeleteCategoryTitle => 'Delete category';

  @override
  String printDeleteCategoryMessage(String name) {
    return 'Delete the category \"$name\"? Its templates are kept and listed under \"No category\".';
  }

  @override
  String get printCategoryLabel => 'Category';

  @override
  String get printOpenDesigner => 'Open the designer';

  @override
  String get printPaperFormatsHelp =>
      'Sheets and rolls used by the templates. Every measure is in millimetres.';

  @override
  String get printNewPaperFormat => 'New paper format';

  @override
  String get printEditPaperFormat => 'Edit paper format';

  @override
  String printPaperFormatSaved(String name) {
    return 'Paper format \"$name\" saved';
  }

  @override
  String get printDeletePaperFormatTitle => 'Delete paper format';

  @override
  String printDeletePaperFormatMessage(String name) {
    return 'Delete the paper format \"$name\"?';
  }

  @override
  String printDeletePaperFormatUsedMessage(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count templates use it and will print',
      one: '1 template uses it and will print',
    );
    return 'Delete the paper format \"$name\"? $_temp0 on a page the size of the template until you choose another format.';
  }

  @override
  String get printPaperMissing =>
      'No paper format for this type: add one in Paper formats.';

  @override
  String get printPaperNameLabel => 'Name';

  @override
  String get printPaperNameHelp => 'Leave empty to show the measures.';

  @override
  String get printPaperFeedSheet => 'Sheet';

  @override
  String get printPaperFeedRoll => 'Roll';

  @override
  String get printPaperLabelSizeTitle => 'Label size (mm)';

  @override
  String get printPaperCellSizeTitle => 'Size of each label or sign (mm)';

  @override
  String get printPaperPageTitle => 'Sheet size (mm)';

  @override
  String get printPaperGridTitle => 'Layout on the sheet';

  @override
  String get printPaperWidth => 'Width';

  @override
  String get printPaperHeight => 'Height';

  @override
  String get printPaperColumns => 'Columns';

  @override
  String get printPaperRows => 'Rows';

  @override
  String get printPaperMarginTop => 'Top margin';

  @override
  String get printPaperMarginLeft => 'Left margin';

  @override
  String get printPaperGapX => 'Gap between columns';

  @override
  String get printPaperGapY => 'Gap between rows';

  @override
  String get printPaperErrorSize =>
      'Enter the size of the sheet and of each label.';

  @override
  String get printPaperErrorGrid => 'Columns must be 1 to 20 and rows 1 to 40.';

  @override
  String get printPaperErrorOutside =>
      'The labels do not fit on the sheet: check sizes, margins and gaps.';

  @override
  String printPaperSheetDescription(String page, int count, String cell) {
    return 'Sheet $page mm · $count × $cell mm';
  }

  @override
  String printJobLabelCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count labels',
      one: '1 label',
    );
    return '$_temp0';
  }

  @override
  String get printJobRemove => 'Remove from the labels';

  @override
  String get printJobEmpty => 'No labels left to print.';

  @override
  String printSheetNumber(int number) {
    return 'Sheet $number';
  }

  @override
  String get printAddLabelsHelp =>
      'To print labels of real products, add them from the catalogue.';

  @override
  String get printAddLabelsAlreadyListed =>
      'The chosen products are already in the labels.';

  @override
  String get printCancel => 'Cancel';

  @override
  String get printDelete => 'Delete';

  @override
  String get printSave => 'Save';

  @override
  String get printPrint => 'Print';

  @override
  String get printClose => 'Close';

  @override
  String printPreviewError(String error) {
    return 'Preview not available: $error';
  }

  @override
  String get printAddLabels => 'Add label';
}
