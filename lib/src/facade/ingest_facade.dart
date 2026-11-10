/// Ingest Facade - the entry from a file, stream or text into the knowledge
/// system.
///
/// Runs an `mcp_ingest` pipeline and stores the Evidence and Fragments it
/// produced in the system's fact graph. It owns no extraction logic and no
/// storage.
library;

import 'package:mcp_ingest/mcp_ingest.dart'
    show IngestInput, IngestOptions, IngestPipeline, IngestResult;

import '../system/knowledge_system.dart';

/// Thin facade over an [IngestPipeline] and the fact graph's evidence
/// storage.
class IngestFacade {
  IngestFacade({
    required KnowledgeSystem system,
    IngestPipeline? pipeline,
  })  : _system = system,
        _pipeline = pipeline ?? IngestPipeline.defaults();
  final KnowledgeSystem _system;
  final IngestPipeline _pipeline;

  /// Access the orchestrator.
  KnowledgeSystem get system => _system;

  /// The fact graph is mandatory and the pipeline has a default, so ingestion
  /// is always available.
  bool get isAvailable => true;

  /// Ingest [input] into [workspaceId] (default: the system's workspace).
  ///
  /// On success the Evidence and its Fragments are saved and the pipeline's
  /// result is returned. A failed ingestion saves nothing and returns the
  /// result carrying its error.
  Future<IngestResult> ingest(
    IngestInput input, {
    String? workspaceId,
    IngestOptions options = IngestOptions.defaults,
  }) async {
    final result = await _pipeline.ingest(
      input,
      options.copyWith(workspaceId: workspaceId ?? _system.config.workspaceId),
    );
    final evidence = result.evidence;
    if (result.error != null || evidence == null) return result;

    // The engine takes the evidence in as its own: the same audit chain and
    // graph edges as evidence it ingested itself.
    await _system.factGraph.evidenceService
        .adoptEvidence(evidence, fragments: result.fragments);
    return result;
  }

  /// Ingest [text] (UTF-8) into [workspaceId].
  Future<IngestResult> ingestText(
    String text, {
    String? workspaceId,
    String mimeType = 'text/plain',
    String? filename,
    IngestOptions options = IngestOptions.defaults,
  }) {
    return ingest(
      IngestInput.fromString(text, filename: filename, mimeType: mimeType),
      workspaceId: workspaceId,
      options: options,
    );
  }
}
