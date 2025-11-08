class SurrealExportOptions {
  final bool users;
  final bool accesses;
  final bool params;
  final bool functions;
  final bool analyzers;
  final bool tables;
  final bool versions;
  final bool records;
  final bool sequences;

  SurrealExportOptions({
    this.users = true,
    this.accesses = true,
    this.params = true,
    this.functions = true,
    this.analyzers = true,
    this.tables = true,
    this.versions = true,
    this.records = true,
    this.sequences = true,
  });
}
