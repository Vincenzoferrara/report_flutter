## Unreleased

- "Save PDF" in the print center, the builder PDF export and the viewer
  CSV/Excel export ask where to save through the system save dialog (the XDG
  portal on Linux, so they work in Flatpak). `PrintController.shareSelected`
  is now `saveSelected` and returns the saved file, or null when cancelled.
- `ReportExportService.csvBytes`, `csvText` and `excelBytes` build the files
  without writing them.

## 1.0.0

- First public release on pub.dev, licensed under GPL-3.0.
- Drag-and-drop report builder, viewer, rendering engine and `.rpt` format.
- Print system (`PrintLibrary`, `PrintCenter`, designer, paper formats, PDF printing).
- CSV/JSON import, PDF, CSV and Excel export.
- English and Italian translations (`ReportLocalizations`) for every
  screen, designer and viewer included.
- Example app in the `example/` folder, in English.
- Screenshots of every screen in the README and on pub.dev.
