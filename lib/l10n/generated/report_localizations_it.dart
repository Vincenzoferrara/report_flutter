// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'report_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class ReportLocalizationsIt extends ReportLocalizations {
  ReportLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get printPrintCenterTitle => 'Template e stampa';

  @override
  String get printTemplateQuestion => 'Scegli un modello';

  @override
  String get printTemplateActions => 'Opzioni modello';

  @override
  String get printRename => 'Rinomina';

  @override
  String get printDeleteTemplateTitle => 'Elimina modello';

  @override
  String printDeleteTemplateMessage(String name) {
    return 'Eliminare il modello \"$name\"? I modelli pronti non vengono toccati.';
  }

  @override
  String get printTemplateNameLabel => 'Nome del modello';

  @override
  String printTemplateSaved(String name) {
    return 'Modello \"$name\" salvato';
  }

  @override
  String get printSavePdf => 'Salva PDF';

  @override
  String printPdfSaved(String file) {
    return 'PDF salvato: $file';
  }

  @override
  String printPrintError(String error) {
    return 'Stampa non riuscita: $error';
  }

  @override
  String get printPreviewTitle => 'Anteprima';

  @override
  String get printPreviewOneLabel => 'Una';

  @override
  String get printPreviewWholeSheet => 'Foglio intero';

  @override
  String get printPreviewSampleNotice =>
      'Dati di esempio: la stampa sarà esattamente cosi.';

  @override
  String get printPreviewSheetNotice =>
      'Le linee tratteggiate e i riquadri grigi mostrano i bordi delle etichette e le posizioni già usate: non vengono stampati.';

  @override
  String get printSectionQuantity => 'Quante';

  @override
  String get printSectionPaper => 'Formato carta';

  @override
  String get printCopiesQuestion => 'Quante copie stampare?';

  @override
  String printFullSheet(int count) {
    return 'Foglio intero ($count)';
  }

  @override
  String get printSkipQuestion => 'Posti già usati su ogni foglio';

  @override
  String get printSkipHelp =>
      'Per ogni foglio indica quante etichette mancano all\'inizio: la stampa su quel foglio parte subito dopo. I rotoli partono sempre dalla prima etichetta.';

  @override
  String printSheetsNeeded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fogli da stampare',
      one: '1 foglio da stampare',
    );
    return '$_temp0';
  }

  @override
  String get printDecrease => 'Diminuisci';

  @override
  String get printIncrease => 'Aumenta';

  @override
  String get printPaperGroupSheets => 'Fogli A4 adesivi (stampante normale)';

  @override
  String get printPaperGroupRolls => 'Rotolo (stampante per etichette)';

  @override
  String printPaperLabelSheet(int count, String size) {
    return 'Foglio A4 · $count etichette $size mm';
  }

  @override
  String printPaperRoll(String size) {
    return 'Rotolo · etichetta $size mm';
  }

  @override
  String get printPaperSignA4Portrait => 'A4 verticale · 1 per foglio';

  @override
  String get printPaperSignA4Landscape => 'A4 orizzontale · 1 per foglio';

  @override
  String get printPaperSignA5 => 'A5 · 2 per foglio A4';

  @override
  String get printPaperSignA6 => 'A6 · 4 per foglio A4';

  @override
  String get printEditDesign => 'Modifica modello';

  @override
  String printDesignerTitle(String name) {
    return 'Modifica: $name';
  }

  @override
  String get printApplyDesign => 'Usa queste modifiche';

  @override
  String get printDiscardDesignTitle => 'Annullare le modifiche?';

  @override
  String get printDiscardDesignMessage =>
      'Le modifiche fatte nel designer andranno perse.';

  @override
  String get printKeepEditing => 'Continua a modificare';

  @override
  String get printDiscardDesign => 'Annulla modifiche';

  @override
  String get printTabPrint => 'Stampa';

  @override
  String get printTabTemplates => 'Template';

  @override
  String get printReload => 'Ricarica';

  @override
  String get printLoadError =>
      'Non è stato possibile caricare i modelli dal server. Controlla la connessione e riprova.';

  @override
  String get printPrintHelp =>
      'Tocca un modello per vedere l\'anteprima e stampare.';

  @override
  String get printJobTemplateQuestion => 'Scegli il modello di etichetta';

  @override
  String printJobSummary(int products, int labels) {
    String _temp0 = intl.Intl.pluralLogic(
      products,
      locale: localeName,
      other: '$products articoli',
      one: '1 articolo',
    );
    String _temp1 = intl.Intl.pluralLogic(
      labels,
      locale: localeName,
      other: '$labels etichette',
      one: '1 etichetta',
    );
    return 'Etichette per $_temp0: $_temp1';
  }

  @override
  String get printJobCancel => 'Annulla';

  @override
  String get printJobLabelsTitle => 'Etichette da stampare';

  @override
  String get printJobQuantityHelp =>
      'Un\'etichetta per ogni pezzo in magazzino. Le varianti senza pezzi non sono elencate.';

  @override
  String get printChangeTemplate => 'Cambia modello';

  @override
  String get printPreviewRealNotice =>
      'Dati dei prodotti: la stampa sarà esattamente così.';

  @override
  String get printNoTemplates => 'Non ci sono ancora modelli.';

  @override
  String get printNoCategory => 'Senza categoria';

  @override
  String get printEmptyCategory => 'Nessun modello in questa categoria.';

  @override
  String get printManagersOnly =>
      'Solo i responsabili possono creare, modificare o eliminare modelli, categorie e formati carta.';

  @override
  String get printNewTemplate => 'Nuovo modello';

  @override
  String get printNewCategory => 'Nuova categoria';

  @override
  String get printPaperFormats => 'Formati carta';

  @override
  String get printDuplicate => 'Duplica';

  @override
  String get printMoveToCategory => 'Sposta in categoria';

  @override
  String printCopyOf(String name) {
    return 'Copia di $name';
  }

  @override
  String printTemplateDeleted(String name) {
    return 'Modello \"$name\" eliminato';
  }

  @override
  String printSaveError(String error) {
    return 'Non salvato sul server: $error';
  }

  @override
  String get printCategoryActions => 'Opzioni categoria';

  @override
  String get printMoveUp => 'Sposta su';

  @override
  String get printMoveDown => 'Sposta giù';

  @override
  String get printCategoryNameLabel => 'Nome della categoria';

  @override
  String printCategorySaved(String name) {
    return 'Categoria \"$name\" salvata';
  }

  @override
  String printCategoryDeleted(String name) {
    return 'Categoria \"$name\" eliminata';
  }

  @override
  String get printDeleteCategoryTitle => 'Elimina categoria';

  @override
  String printDeleteCategoryMessage(String name) {
    return 'Eliminare la categoria \"$name\"? I suoi modelli restano e finiscono in \"Senza categoria\".';
  }

  @override
  String get printCategoryLabel => 'Categoria';

  @override
  String get printOpenDesigner => 'Apri il designer';

  @override
  String get printPaperFormatsHelp =>
      'Fogli e rotoli usati dai modelli. Tutte le misure sono in millimetri.';

  @override
  String get printNewPaperFormat => 'Nuovo formato carta';

  @override
  String get printEditPaperFormat => 'Modifica formato carta';

  @override
  String printPaperFormatSaved(String name) {
    return 'Formato carta \"$name\" salvato';
  }

  @override
  String get printDeletePaperFormatTitle => 'Elimina formato carta';

  @override
  String printDeletePaperFormatMessage(String name) {
    return 'Eliminare il formato carta \"$name\"?';
  }

  @override
  String printDeletePaperFormatUsedMessage(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modelli lo usano e stamperanno',
      one: '1 modello lo usa e stamperà',
    );
    return 'Eliminare il formato carta \"$name\"? $_temp0 su una pagina grande quanto il modello finché non scegli un altro formato.';
  }

  @override
  String get printPaperMissing =>
      'Nessun formato carta per questo tipo: aggiungine uno in Formati carta.';

  @override
  String get printPaperNameLabel => 'Nome';

  @override
  String get printPaperNameHelp => 'Lascia vuoto per mostrare le misure.';

  @override
  String get printPaperFeedSheet => 'Foglio';

  @override
  String get printPaperFeedRoll => 'Rotolo';

  @override
  String get printPaperLabelSizeTitle => 'Misura etichetta (mm)';

  @override
  String get printPaperCellSizeTitle =>
      'Misura di ogni etichetta o cartello (mm)';

  @override
  String get printPaperPageTitle => 'Misura del foglio (mm)';

  @override
  String get printPaperGridTitle => 'Disposizione sul foglio';

  @override
  String get printPaperWidth => 'Larghezza';

  @override
  String get printPaperHeight => 'Altezza';

  @override
  String get printPaperColumns => 'Colonne';

  @override
  String get printPaperRows => 'Righe';

  @override
  String get printPaperMarginTop => 'Margine sopra';

  @override
  String get printPaperMarginLeft => 'Margine sinistro';

  @override
  String get printPaperGapX => 'Spazio tra colonne';

  @override
  String get printPaperGapY => 'Spazio tra righe';

  @override
  String get printPaperErrorSize =>
      'Inserisci la misura del foglio e di ogni etichetta.';

  @override
  String get printPaperErrorGrid =>
      'Le colonne devono essere da 1 a 20 e le righe da 1 a 40.';

  @override
  String get printPaperErrorOutside =>
      'Le etichette non stanno nel foglio: controlla misure, margini e spazi.';

  @override
  String printPaperSheetDescription(String page, int count, String cell) {
    return 'Foglio $page mm · $count × $cell mm';
  }

  @override
  String printJobLabelCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count etichette',
      one: '1 etichetta',
    );
    return '$_temp0';
  }

  @override
  String get printJobRemove => 'Togli dalle etichette';

  @override
  String get printJobEmpty => 'Non ci sono più etichette da stampare.';

  @override
  String printSheetNumber(int number) {
    return 'Foglio $number';
  }

  @override
  String get printAddLabelsHelp =>
      'Per stampare le etichette di prodotti veri, aggiungili dal catalogo.';

  @override
  String get printAddLabelsAlreadyListed =>
      'I prodotti scelti sono già tra le etichette.';

  @override
  String get printCancel => 'Annulla';

  @override
  String get printDelete => 'Elimina';

  @override
  String get printSave => 'Salva';

  @override
  String get printPrint => 'Stampa';

  @override
  String get printClose => 'Chiudi';

  @override
  String printPreviewError(String error) {
    return 'Anteprima non disponibile: $error';
  }

  @override
  String get printAddLabels => 'Aggiungi etichetta';

  @override
  String get builderTabDesigner => 'Designer';

  @override
  String get builderNoElements => 'Nessun elemento nel template';

  @override
  String get builderNoElementsHelp =>
      'Aggiungi elementi nel Designer per vedere l\'anteprima';

  @override
  String get builderElements => 'Elementi';

  @override
  String get builderText => 'Testo';

  @override
  String get builderStaticText => 'Testo statico';

  @override
  String get builderGroupCodes => 'Codici';

  @override
  String get builderGroupShapes => 'Forme';

  @override
  String get builderLine => 'Linea';

  @override
  String get builderRectangle => 'Rettangolo';

  @override
  String get builderCircle => 'Cerchio';

  @override
  String get builderGroupControls => 'Controlli';

  @override
  String get builderTextbox => 'Casella di testo';

  @override
  String get builderGroupOther => 'Altri';

  @override
  String get builderImage => 'Immagine';

  @override
  String get builderDate => 'Data';

  @override
  String get builderGroupDataFields => 'Campi dati';

  @override
  String get builderGenericField => 'Campo generico';

  @override
  String get reportFitToScreen => 'Adatta allo schermo';

  @override
  String get reportActualSize => 'Dimensione reale';

  @override
  String get builderUndo => 'Annulla (Ctrl+Z)';

  @override
  String get builderRedo => 'Ripeti (Ctrl+Y)';

  @override
  String get builderLoadTemplate => 'Carica template';

  @override
  String get builderSaveTemplate => 'Salva template';

  @override
  String get builderExportPdf => 'Esporta PDF';

  @override
  String get builderProperties => 'Proprietà';

  @override
  String get builderSelectElement => 'Seleziona un elemento';

  @override
  String get builderSectionId => 'Identificativo';

  @override
  String get builderSectionPosition => 'Posizione';

  @override
  String get builderSectionSize => 'Dimensioni';

  @override
  String get builderWidthMm => 'Larghezza (mm)';

  @override
  String get builderHeightMm => 'Altezza (mm)';

  @override
  String get builderSectionFormatting => 'Formattazione';

  @override
  String get builderFontSizeMm => 'Dimensione font (mm)';

  @override
  String get builderFontWeight => 'Peso font';

  @override
  String get builderHorizontalAlignment => 'Allineamento orizzontale';

  @override
  String get builderVerticalAlignment => 'Allineamento verticale';

  @override
  String get builderTextColor => 'Colore testo';

  @override
  String get builderBackgroundColor => 'Colore sfondo';

  @override
  String get builderUseMarkdown => 'Usa Markdown';

  @override
  String get builderSectionBorder => 'Bordo';

  @override
  String get builderBorderWidthMm => 'Spessore bordo (mm)';

  @override
  String get builderBorderColor => 'Colore bordo';

  @override
  String get builderSectionContent => 'Contenuto';

  @override
  String get builderDataField => 'Campo dati';

  @override
  String get builderNoDataFieldsSchema =>
      'Nessun campo dati disponibile. Associa uno schema dati al template.';

  @override
  String get builderField => 'Campo';

  @override
  String get builderPrefix => 'Prefisso';

  @override
  String get builderSuffix => 'Suffisso';

  @override
  String get builderType => 'Tipo';

  @override
  String get builderShowText => 'Mostra testo';

  @override
  String get builderBorderRadiusMm => 'Raggio bordo (mm)';

  @override
  String get builderFillColor => 'Colore riempimento';

  @override
  String get builderThicknessMm => 'Spessore (mm)';

  @override
  String get builderColor => 'Colore';

  @override
  String get builderSource => 'Sorgente';

  @override
  String get builderNoDataFields => 'Nessun campo dati disponibile.';

  @override
  String get builderImageField => 'Campo immagine';

  @override
  String get builderAssetPath => 'Percorso asset';

  @override
  String get builderImageUrl => 'URL immagine';

  @override
  String get builderFit => 'Adattamento';

  @override
  String get builderBooleanField => 'Campo booleano';

  @override
  String get builderLabel => 'Etichetta';

  @override
  String get builderSizeMm => 'Dimensione (mm)';

  @override
  String get builderMaxLines => 'Righe max';

  @override
  String get builderNone => 'Nessuno';

  @override
  String get builderSelectColor => 'Seleziona colore';

  @override
  String get builderPageSize => 'Dimensioni pagina';

  @override
  String get builderPortrait => 'Verticale';

  @override
  String get builderLandscape => 'Orizzontale';

  @override
  String get builderCard => 'Biglietto';

  @override
  String get builderApply => 'Applica';

  @override
  String get builderTemplateLoaded => 'Template caricato';

  @override
  String builderTemplateLoadError(String error) {
    return 'Errore nel caricare il template: $error';
  }

  @override
  String get builderPdfExported => 'PDF esportato';

  @override
  String builderPdfExportError(String error) {
    return 'Errore nell\'esportare il PDF: $error';
  }

  @override
  String builderFormulaHelp(String example) {
    return 'Sintassi Excel-like, con $example per i dati';
  }

  @override
  String get builderVariables => 'Variabili:';

  @override
  String get builderOutputFormat => 'Formato output';

  @override
  String get builderErrorValue => 'Valore errore';

  @override
  String get builderErrorValueHint => 'Valore da mostrare in caso di errore';

  @override
  String get builderNoFields => 'Nessun campo disponibile';

  @override
  String get builderAddVariable => 'Aggiungi variabile';

  @override
  String get builderEnableMarkdown => 'Abilita il rendering Markdown';

  @override
  String get builderMarkdownContent => 'Contenuto Markdown';

  @override
  String get builderMarkdownHint => '# Titolo\n\nTesto **grassetto**';

  @override
  String get builderAutoToc => 'Indice automatico';

  @override
  String get builderAutoTocHelp => 'Genera l\'indice dai titoli';

  @override
  String get builderSyntaxHighlighting => 'Evidenziazione sintassi';

  @override
  String get builderSyntaxHighlightingHelp => 'Evidenzia i blocchi di codice';

  @override
  String get builderTheme => 'Tema';

  @override
  String get builderConditionalFormatting => 'Formattazione condizionale';

  @override
  String get builderEnableConditionalFormatting =>
      'Abilita formattazione condizionale';

  @override
  String get builderConditionalFormattingHelp =>
      'Cambia stile in base al valore';

  @override
  String get builderAddRule => 'Aggiungi regola';

  @override
  String builderRuleNumber(int number) {
    return 'Regola $number';
  }

  @override
  String get builderCondition => 'Condizione';

  @override
  String get builderValue => 'Valore';

  @override
  String get builderSearchText => 'Testo da cercare';

  @override
  String get builderConditionalImages => 'Immagini condizionali:';

  @override
  String get builderAddImageRule => 'Aggiungi regola immagine';

  @override
  String builderImageRuleNumber(int number) {
    return 'Regola immagine $number';
  }

  @override
  String get builderImageFieldIfTrue => 'Campo immagine (se vero)';

  @override
  String get builderImageFieldIfTrueHint =>
      'Campo dati che contiene l\'immagine';

  @override
  String get builderFallbackImage => 'Immagine di riserva (se falso)';

  @override
  String get builderFallbackImageHint => 'Percorso asset predefinito';

  @override
  String viewerValidationFailed(String error) {
    return 'Validazione dati fallita: $error';
  }

  @override
  String get viewerLoadingTemplate => 'Caricamento template...';

  @override
  String get viewerError => 'Errore';

  @override
  String get viewerRetry => 'Riprova';

  @override
  String get viewerNoTemplate => 'Nessun template caricato';

  @override
  String get viewerNoData => 'Nessun dato da visualizzare';

  @override
  String get viewerPreviousPage => 'Pagina precedente';

  @override
  String get viewerNextPage => 'Pagina successiva';

  @override
  String get viewerZoomOut => 'Zoom indietro';

  @override
  String get viewerZoomIn => 'Zoom avanti';

  @override
  String get viewerMenu => 'Menu';

  @override
  String get viewerRefreshData => 'Aggiorna dati';

  @override
  String get viewerExportReport => 'Esporta report';

  @override
  String get viewerSettings => 'Impostazioni';

  @override
  String get viewerSinglePage => 'Pagina singola';

  @override
  String get viewerContinuousScroll => 'Scorrimento continuo';

  @override
  String get viewerTwoPages => 'Vista a due pagine';

  @override
  String get viewerRefreshing => 'Aggiornamento in corso...';

  @override
  String get viewerExport => 'Esporta';

  @override
  String get viewerAnnotations => 'Annotazioni';

  @override
  String get viewerSidebar => 'Barra laterale';

  @override
  String viewerRecordCount(int count) {
    return '$count record';
  }

  @override
  String viewerActiveFilters(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filtri attivi',
      one: '1 filtro attivo',
    );
    return '$_temp0';
  }

  @override
  String get viewerFirstPage => 'Prima pagina';

  @override
  String get viewerLastPage => 'Ultima pagina';

  @override
  String viewerDataRefreshed(String source) {
    return 'Dati aggiornati da $source';
  }

  @override
  String viewerRefreshError(String error) {
    return 'Errore aggiornamento dati: $error';
  }

  @override
  String get viewerExportPdfHelp => 'Esporta come documento PDF';

  @override
  String get viewerExportExcelHelp => 'Esporta come foglio di calcolo';

  @override
  String get viewerExportCsvHelp => 'Esporta come file CSV';

  @override
  String get viewerPdfExportNotReady =>
      'Esportazione PDF non ancora disponibile';

  @override
  String viewerExportDone(String format, String file) {
    return '$format salvato: $file';
  }

  @override
  String get viewerOpen => 'Apri';

  @override
  String viewerExportError(String format, String error) {
    return 'Errore esportazione $format: $error';
  }

  @override
  String get viewerPrintNotReady => 'Stampa non ancora disponibile';

  @override
  String get viewerSettingsTitle => 'Impostazioni visualizzatore';

  @override
  String get viewerSettingsNotReady => 'Impostazioni non ancora disponibili';

  @override
  String viewerActiveAnnotations(int count) {
    return 'Annotazioni attive ($count)';
  }

  @override
  String get viewerManage => 'Gestisci';

  @override
  String get viewerReportAnnotations => 'Annotazioni del report';

  @override
  String get viewerNoAnnotations => 'Nessuna annotazione presente';

  @override
  String get viewerAnnotationDeleted => 'Annotazione eliminata';

  @override
  String viewerDeleteError(String error) {
    return 'Errore eliminazione: $error';
  }

  @override
  String viewerErrorDetail(String error) {
    return 'Errore: $error';
  }

  @override
  String get viewerTemplateNotFound => 'Template non trovato';

  @override
  String get sidebarTitle => 'Pannello report';

  @override
  String get sidebarFilters => 'Filtri';

  @override
  String get sidebarParameters => 'Parametri';

  @override
  String get sidebarPages => 'Pagine';

  @override
  String get sidebarFiltersDisabled => 'Filtri non abilitati';

  @override
  String get sidebarDataFilters => 'Filtri dati';

  @override
  String get sidebarClear => 'Cancella';

  @override
  String get sidebarAddFilter => 'Aggiungi filtro';

  @override
  String get sidebarNoFilters => 'Nessun filtro configurato';

  @override
  String get sidebarNoFiltersHelp =>
      'Aggiungi filtri per filtrare i dati del report';

  @override
  String get sidebarParametersDisabled => 'Parametri non abilitati';

  @override
  String get sidebarReportParameters => 'Parametri del report';

  @override
  String get sidebarAddParameter => 'Aggiungi parametro';

  @override
  String get sidebarNoParameters => 'Nessun parametro configurato';

  @override
  String get sidebarNoParametersHelp =>
      'Aggiungi parametri per personalizzare il report';

  @override
  String get sidebarPageThumbnails => 'Miniature pagine';

  @override
  String get sidebarNoPages => 'Nessuna pagina disponibile';

  @override
  String sidebarPageNumber(int number) {
    return 'Pagina $number';
  }

  @override
  String get sidebarOpEquals => 'Uguale';

  @override
  String get sidebarOpContains => 'Contiene';

  @override
  String get sidebarOpGreater => 'Maggiore';

  @override
  String get sidebarOpLess => 'Minore';

  @override
  String get sidebarOpBetween => 'Tra';

  @override
  String get sidebarNotReady => 'Funzionalità non ancora disponibile';

  @override
  String sidebarEditParameter(String name) {
    return 'Modifica $name';
  }

  @override
  String sidebarCurrentValue(String value) {
    return 'Valore attuale: $value';
  }

  @override
  String tableSelected(int count) {
    return '$count selezionati';
  }

  @override
  String tableSortedBy(String column) {
    return 'Ordinato per $column';
  }

  @override
  String tableTotalRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count righe',
      one: '1 riga',
    );
    return '$_temp0';
  }

  @override
  String get tableExportSelected => 'Esporta selezionati';

  @override
  String get tableClickToSort => 'Clicca per ordinare';

  @override
  String tableExportNotReady(int count) {
    return 'Esportazione di $count record non ancora disponibile';
  }

  @override
  String get chartNoData => 'Nessun dato disponibile';

  @override
  String get chartBar => 'Grafico a barre';

  @override
  String get chartLine => 'Grafico a linee';

  @override
  String get chartPie => 'Grafico a torta';

  @override
  String get chartArea => 'Grafico ad area';

  @override
  String get chartScatter => 'Grafico a dispersione';

  @override
  String get chartDataPoint => 'Dato';

  @override
  String get annotationDefaultAuthor => 'Utente';

  @override
  String get annotationNewTitle => 'Nuova annotazione (temporanea)';

  @override
  String get annotationEditTitle => 'Modifica annotazione';

  @override
  String get annotationTemporaryNotice =>
      'Questa annotazione è temporanea e sarà persa alla chiusura';

  @override
  String get annotationContentHint => 'Inserisci qui la tua annotazione...';

  @override
  String get annotationAuthor => 'Autore';

  @override
  String get annotationAdd => 'Aggiungi';

  @override
  String get annotationContentRequired => 'Il contenuto non può essere vuoto';

  @override
  String get annotationTypeNote => 'Nota';

  @override
  String get annotationTypeHighlight => 'Evidenziazione';

  @override
  String get annotationTypeComment => 'Commento';

  @override
  String get annotationTypeQuestion => 'Domanda';

  @override
  String get annotationTypeIssue => 'Problema';
}
