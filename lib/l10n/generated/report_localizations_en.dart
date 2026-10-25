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
  String printPdfSaved(String file) {
    return 'PDF saved: $file';
  }

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

  @override
  String get builderTabDesigner => 'Designer';

  @override
  String get builderNoElements => 'No elements in the template';

  @override
  String get builderNoElementsHelp =>
      'Add elements in the Designer to see the preview';

  @override
  String get builderElements => 'Elements';

  @override
  String get builderText => 'Text';

  @override
  String get builderStaticText => 'Static text';

  @override
  String get builderGroupCodes => 'Codes';

  @override
  String get builderGroupShapes => 'Shapes';

  @override
  String get builderLine => 'Line';

  @override
  String get builderRectangle => 'Rectangle';

  @override
  String get builderCircle => 'Circle';

  @override
  String get builderGroupControls => 'Controls';

  @override
  String get builderTextbox => 'Text box';

  @override
  String get builderGroupOther => 'Other';

  @override
  String get builderImage => 'Image';

  @override
  String get builderDate => 'Date';

  @override
  String get builderGroupDataFields => 'Data fields';

  @override
  String get builderGenericField => 'Generic field';

  @override
  String get reportFitToScreen => 'Fit to screen';

  @override
  String get reportActualSize => 'Actual size';

  @override
  String get builderUndo => 'Undo (Ctrl+Z)';

  @override
  String get builderRedo => 'Redo (Ctrl+Y)';

  @override
  String get builderLoadTemplate => 'Load template';

  @override
  String get builderSaveTemplate => 'Save template';

  @override
  String get builderExportPdf => 'Export PDF';

  @override
  String get builderProperties => 'Properties';

  @override
  String get builderSelectElement => 'Select an element';

  @override
  String get builderSectionId => 'Identifier';

  @override
  String get builderSectionPosition => 'Position';

  @override
  String get builderSectionSize => 'Size';

  @override
  String get builderWidthMm => 'Width (mm)';

  @override
  String get builderHeightMm => 'Height (mm)';

  @override
  String get builderSectionFormatting => 'Formatting';

  @override
  String get builderFontSizeMm => 'Font size (mm)';

  @override
  String get builderFontWeight => 'Font weight';

  @override
  String get builderHorizontalAlignment => 'Horizontal alignment';

  @override
  String get builderVerticalAlignment => 'Vertical alignment';

  @override
  String get builderTextColor => 'Text color';

  @override
  String get builderBackgroundColor => 'Background color';

  @override
  String get builderUseMarkdown => 'Use Markdown';

  @override
  String get builderSectionBorder => 'Border';

  @override
  String get builderBorderWidthMm => 'Border width (mm)';

  @override
  String get builderBorderColor => 'Border color';

  @override
  String get builderSectionContent => 'Content';

  @override
  String get builderDataField => 'Data field';

  @override
  String get builderNoDataFieldsSchema =>
      'No data fields available. Link a data schema to the template.';

  @override
  String get builderField => 'Field';

  @override
  String get builderPrefix => 'Prefix';

  @override
  String get builderSuffix => 'Suffix';

  @override
  String get builderType => 'Type';

  @override
  String get builderShowText => 'Show text';

  @override
  String get builderBorderRadiusMm => 'Corner radius (mm)';

  @override
  String get builderFillColor => 'Fill color';

  @override
  String get builderThicknessMm => 'Thickness (mm)';

  @override
  String get builderColor => 'Color';

  @override
  String get builderSource => 'Source';

  @override
  String get builderNoDataFields => 'No data fields available.';

  @override
  String get builderImageField => 'Image field';

  @override
  String get builderAssetPath => 'Asset path';

  @override
  String get builderImageUrl => 'Image URL';

  @override
  String get builderFit => 'Fit';

  @override
  String get builderBooleanField => 'Boolean field';

  @override
  String get builderLabel => 'Label';

  @override
  String get builderSizeMm => 'Size (mm)';

  @override
  String get builderMaxLines => 'Max lines';

  @override
  String get builderNone => 'None';

  @override
  String get builderSelectColor => 'Select color';

  @override
  String get builderPageSize => 'Page size';

  @override
  String get builderPortrait => 'Portrait';

  @override
  String get builderLandscape => 'Landscape';

  @override
  String get builderCard => 'Card';

  @override
  String get builderApply => 'Apply';

  @override
  String get builderTemplateLoaded => 'Template loaded';

  @override
  String builderTemplateLoadError(String error) {
    return 'Could not load the template: $error';
  }

  @override
  String get builderPdfExported => 'PDF exported';

  @override
  String builderPdfExportError(String error) {
    return 'Could not export the PDF: $error';
  }

  @override
  String builderFormulaHelp(String example) {
    return 'Excel-like syntax, with $example for the data';
  }

  @override
  String get builderVariables => 'Variables:';

  @override
  String get builderOutputFormat => 'Output format';

  @override
  String get builderErrorValue => 'Error value';

  @override
  String get builderErrorValueHint => 'Value shown on error';

  @override
  String get builderNoFields => 'No fields available';

  @override
  String get builderAddVariable => 'Add variable';

  @override
  String get builderEnableMarkdown => 'Enable Markdown rendering';

  @override
  String get builderMarkdownContent => 'Markdown content';

  @override
  String get builderMarkdownHint => '# Title\n\n**Bold** text';

  @override
  String get builderAutoToc => 'Automatic table of contents';

  @override
  String get builderAutoTocHelp =>
      'Builds a table of contents from the headings';

  @override
  String get builderSyntaxHighlighting => 'Syntax highlighting';

  @override
  String get builderSyntaxHighlightingHelp => 'Highlights code blocks';

  @override
  String get builderTheme => 'Theme';

  @override
  String get builderConditionalFormatting => 'Conditional formatting';

  @override
  String get builderEnableConditionalFormatting =>
      'Enable conditional formatting';

  @override
  String get builderConditionalFormattingHelp =>
      'Changes the style based on the value';

  @override
  String get builderAddRule => 'Add rule';

  @override
  String builderRuleNumber(int number) {
    return 'Rule $number';
  }

  @override
  String get builderCondition => 'Condition';

  @override
  String get builderValue => 'Value';

  @override
  String get builderSearchText => 'Text to find';

  @override
  String get builderConditionalImages => 'Conditional images:';

  @override
  String get builderAddImageRule => 'Add image rule';

  @override
  String builderImageRuleNumber(int number) {
    return 'Image rule $number';
  }

  @override
  String get builderImageFieldIfTrue => 'Image field (if true)';

  @override
  String get builderImageFieldIfTrueHint => 'Data field that holds the image';

  @override
  String get builderFallbackImage => 'Fallback image (if false)';

  @override
  String get builderFallbackImageHint => 'Default asset path';

  @override
  String viewerValidationFailed(String error) {
    return 'Data validation failed: $error';
  }

  @override
  String get viewerLoadingTemplate => 'Loading template...';

  @override
  String get viewerError => 'Error';

  @override
  String get viewerRetry => 'Retry';

  @override
  String get viewerNoTemplate => 'No template loaded';

  @override
  String get viewerNoData => 'No data to display';

  @override
  String get viewerPreviousPage => 'Previous page';

  @override
  String get viewerNextPage => 'Next page';

  @override
  String get viewerZoomOut => 'Zoom out';

  @override
  String get viewerZoomIn => 'Zoom in';

  @override
  String get viewerMenu => 'Menu';

  @override
  String get viewerRefreshData => 'Refresh data';

  @override
  String get viewerExportReport => 'Export report';

  @override
  String get viewerSettings => 'Settings';

  @override
  String get viewerSinglePage => 'Single page';

  @override
  String get viewerContinuousScroll => 'Continuous scroll';

  @override
  String get viewerTwoPages => 'Two-page view';

  @override
  String get viewerRefreshing => 'Refreshing...';

  @override
  String get viewerExport => 'Export';

  @override
  String get viewerAnnotations => 'Annotations';

  @override
  String get viewerSidebar => 'Sidebar';

  @override
  String viewerRecordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count records',
      one: '1 record',
    );
    return '$_temp0';
  }

  @override
  String viewerActiveFilters(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active filters',
      one: '1 active filter',
    );
    return '$_temp0';
  }

  @override
  String get viewerFirstPage => 'First page';

  @override
  String get viewerLastPage => 'Last page';

  @override
  String viewerDataRefreshed(String source) {
    return 'Data refreshed from $source';
  }

  @override
  String viewerRefreshError(String error) {
    return 'Could not refresh the data: $error';
  }

  @override
  String get viewerExportPdfHelp => 'Export as a PDF document';

  @override
  String get viewerExportExcelHelp => 'Export as a spreadsheet';

  @override
  String get viewerExportCsvHelp => 'Export as a CSV file';

  @override
  String get viewerPdfExportNotReady => 'PDF export is not available yet';

  @override
  String viewerExportDone(String format, String file) {
    return '$format saved: $file';
  }

  @override
  String get viewerOpen => 'Open';

  @override
  String viewerExportError(String format, String error) {
    return '$format export failed: $error';
  }

  @override
  String get viewerPrintNotReady => 'Printing is not available yet';

  @override
  String get viewerSettingsTitle => 'Viewer settings';

  @override
  String get viewerSettingsNotReady => 'Settings are not available yet';

  @override
  String viewerActiveAnnotations(int count) {
    return 'Active annotations ($count)';
  }

  @override
  String get viewerManage => 'Manage';

  @override
  String get viewerReportAnnotations => 'Report annotations';

  @override
  String get viewerNoAnnotations => 'No annotations';

  @override
  String get viewerAnnotationDeleted => 'Annotation deleted';

  @override
  String viewerDeleteError(String error) {
    return 'Could not delete: $error';
  }

  @override
  String viewerErrorDetail(String error) {
    return 'Error: $error';
  }

  @override
  String get viewerTemplateNotFound => 'Template not found';

  @override
  String get sidebarTitle => 'Report panel';

  @override
  String get sidebarFilters => 'Filters';

  @override
  String get sidebarParameters => 'Parameters';

  @override
  String get sidebarPages => 'Pages';

  @override
  String get sidebarFiltersDisabled => 'Filters are not enabled';

  @override
  String get sidebarDataFilters => 'Data filters';

  @override
  String get sidebarClear => 'Clear';

  @override
  String get sidebarAddFilter => 'Add filter';

  @override
  String get sidebarNoFilters => 'No filters set';

  @override
  String get sidebarNoFiltersHelp => 'Add filters to narrow the report data';

  @override
  String get sidebarParametersDisabled => 'Parameters are not enabled';

  @override
  String get sidebarReportParameters => 'Report parameters';

  @override
  String get sidebarAddParameter => 'Add parameter';

  @override
  String get sidebarNoParameters => 'No parameters set';

  @override
  String get sidebarNoParametersHelp =>
      'Add parameters to customize the report';

  @override
  String get sidebarPageThumbnails => 'Page thumbnails';

  @override
  String get sidebarNoPages => 'No pages available';

  @override
  String sidebarPageNumber(int number) {
    return 'Page $number';
  }

  @override
  String get sidebarOpEquals => 'Equals';

  @override
  String get sidebarOpContains => 'Contains';

  @override
  String get sidebarOpGreater => 'Greater than';

  @override
  String get sidebarOpLess => 'Less than';

  @override
  String get sidebarOpBetween => 'Between';

  @override
  String get sidebarNotReady => 'Not available yet';

  @override
  String sidebarEditParameter(String name) {
    return 'Edit $name';
  }

  @override
  String sidebarCurrentValue(String value) {
    return 'Current value: $value';
  }

  @override
  String tableSelected(int count) {
    return '$count selected';
  }

  @override
  String tableSortedBy(String column) {
    return 'Sorted by $column';
  }

  @override
  String tableTotalRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rows',
      one: '1 row',
    );
    return '$_temp0';
  }

  @override
  String get tableExportSelected => 'Export selected';

  @override
  String get tableClickToSort => 'Click to sort';

  @override
  String tableExportNotReady(int count) {
    return 'Exporting $count records is not available yet';
  }

  @override
  String get chartNoData => 'No data available';

  @override
  String get chartBar => 'Bar chart';

  @override
  String get chartLine => 'Line chart';

  @override
  String get chartPie => 'Pie chart';

  @override
  String get chartArea => 'Area chart';

  @override
  String get chartScatter => 'Scatter chart';

  @override
  String get chartDataPoint => 'Data point';

  @override
  String get annotationDefaultAuthor => 'User';

  @override
  String get annotationNewTitle => 'New annotation (temporary)';

  @override
  String get annotationEditTitle => 'Edit annotation';

  @override
  String get annotationTemporaryNotice =>
      'This annotation is temporary and is lost when you close the report';

  @override
  String get annotationContentHint => 'Write your annotation here...';

  @override
  String get annotationAuthor => 'Author';

  @override
  String get annotationAdd => 'Add';

  @override
  String get annotationContentRequired => 'The content cannot be empty';

  @override
  String get annotationTypeNote => 'Note';

  @override
  String get annotationTypeHighlight => 'Highlight';

  @override
  String get annotationTypeComment => 'Comment';

  @override
  String get annotationTypeQuestion => 'Question';

  @override
  String get annotationTypeIssue => 'Issue';
}
