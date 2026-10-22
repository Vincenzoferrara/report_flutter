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
}
