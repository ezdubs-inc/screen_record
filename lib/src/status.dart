abstract class ExportStatus {}

class Exporting extends ExportStatus {
  final double percent;

  Exporting(this.percent);
}

class Saving extends ExportStatus {}

class ExportSuccessful extends ExportStatus {}
