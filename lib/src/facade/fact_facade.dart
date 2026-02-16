/// Fact Facade - Simplified API for fact operations.
library;

/// Result of ingesting content.
class IngestResult {
  /// Evidence ID.
  final String evidenceId;

  /// Fragment IDs.
  final List<String> fragmentIds;

  /// Candidate IDs.
  final List<String> candidateIds;

  const IngestResult({
    required this.evidenceId,
    required this.fragmentIds,
    required this.candidateIds,
  });
}

/// Simplified API for fact operations.
class FactFacade {
  final dynamic _system;

  /// Create facade with system reference.
  FactFacade({required dynamic system}) : _system = system;

  /// Ingest raw content and create candidates.
  Future<IngestResult> ingest(
    String content, {
    required String sourceType,
    String? mimeType,
    Map<String, dynamic>? metadata,
  }) async {
    // Implementation will use _system.factGraph
    throw UnimplementedError('FactFacade.ingest not implemented');
  }

  /// Get entity context bundle.
  Future<Map<String, dynamic>> getContext(
    String entityId, {
    DateTime? asOf,
  }) async {
    // Implementation will use _system.factGraph
    throw UnimplementedError('FactFacade.getContext not implemented');
  }

  /// Get summary for entity.
  Future<String?> getSummary(
    String entityId, {
    String? type,
  }) async {
    // Implementation will use _system.factGraph
    throw UnimplementedError('FactFacade.getSummary not implemented');
  }

  /// Query facts.
  Future<List<dynamic>> query({
    required String entityId,
    String? domain,
    Duration? period,
    int? limit,
  }) async {
    // Implementation will use _system.factGraph
    throw UnimplementedError('FactFacade.query not implemented');
  }

  /// Confirm a candidate.
  Future<dynamic> confirm(String candidateId) async {
    // Implementation will use _system.factGraph
    throw UnimplementedError('FactFacade.confirm not implemented');
  }
}
