/// Fact Facade — thin wrapper over the fact-graph standard ports.
///
/// REDESIGN-PLAN Phase 8 §4 step 6: this facade no longer reaches into a
/// generic collection-storage port. It consumes the capability-named
/// standard ports defined in `mcp_bundle` and provided by
/// `mcp_fact_graph`'s `FactGraphRuntime`:
///
///   - `FactsPort` — fact CRUD
///   - `ClaimsPort` — claim lifecycle
///   - `EntitiesPort` — entity CRUD/linking
///   - `CandidatesPort` — pending fact review
///   - `EvidencePort` — evidence fragment extraction
///   - `PatternsPort` — pattern CRUD
///   - `SummariesPort` — fact-level summaries
///
/// Each method requires the corresponding port to be configured. If
/// `system.factGraph` is wired, ports are taken from there; otherwise
/// they fall back to `system.ports`. Methods throw `StateError` when
/// the requested capability is missing.
library;

import 'package:mcp_bundle/mcp_bundle.dart'
    show
        FactsPort,
        FactRecord,
        FactQuery,
        ClaimsPort,
        Claim,
        ClaimQuery,
        EntitiesPort,
        EntityRecord,
        CandidatesPort,
        CandidateRecord,
        EvidencePort,
        EvidenceFragment,
        PatternsPort,
        PatternRecord,
        PatternQuery,
        SummariesPort,
        SummaryRecord,
        Period;

import '../system/knowledge_system.dart';
import '../events/knowledge_event.dart';

// Re-export FactRecord/ClaimRecord/etc. so consumers can use them without
// importing mcp_bundle directly.
export 'package:mcp_bundle/mcp_bundle.dart'
    show
        FactRecord,
        FactQuery,
        Claim,
        ClaimQuery,
        ClaimType,
        ClaimStatus,
        ClaimValidationReport,
        EntityRecord,
        EntityQuery,
        CandidateRecord,
        CandidateStatus,
        EvidenceFragment,
        PatternRecord,
        PatternQuery,
        SummaryRecord;

/// Thin facade over the fact-graph standard ports.
class FactFacade {
  FactFacade({required KnowledgeSystem system}) : _system = system;
  final KnowledgeSystem _system;

  /// Access the orchestrator.
  KnowledgeSystem get system => _system;

  /// Whether the fact-graph layer is available. L0 is required, so this
  /// is always true — a default `FactGraphRuntime.inMemory()` is auto-
  /// wired when no runtime is supplied explicitly.
  bool get isAvailable => true;

  // The fact-graph runtime is core-mandatory, so every port is present.
  FactsPort get _facts => _system.factGraph.facts;
  ClaimsPort get _claims => _system.factGraph.claims;
  EntitiesPort get _entities => _system.factGraph.entities;
  CandidatesPort get _candidates => _system.factGraph.candidates;
  EvidencePort get _evidence => _system.factGraph.evidence;
  PatternsPort get _patterns => _system.factGraph.patterns;
  SummariesPort get _summaries => _system.factGraph.summaries;

  // ── L0: Evidence ─────────────────────────────────────────────────────────

  /// Extract evidence fragments from raw content.
  Future<List<EvidenceFragment>> extractFragments(
    String content,
    String mimeType,
  ) async {
    final port = _evidence;
    return port.extractFragments(content, mimeType);
  }

  /// Compute confidence for a fragment.
  Future<double> computeFragmentConfidence(String fragment) async {
    final port = _evidence;
    return port.computeConfidence(fragment);
  }

  /// Classify a fragment.
  Future<String> classifyFragment(String fragment) async {
    final port = _evidence;
    return port.classifyFragment(fragment);
  }

  // ── L1: Candidates ───────────────────────────────────────────────────────

  /// Create a batch of candidate facts pending review.
  Future<List<String>> createCandidates(
    List<CandidateRecord> candidates,
  ) async {
    final port = _candidates;
    final ids = await port.createCandidates(candidates);
    for (var i = 0; i < candidates.length; i++) {
      _system.eventBus.emit(CandidateCreatedEvent(
        candidateId: ids.length > i ? ids[i] : candidates[i].id,
        confidence: candidates[i].confidence ?? 0.0,
        timestamp: DateTime.now(),
      ));
    }
    return ids;
  }

  /// Get pending candidates for a workspace.
  Future<List<CandidateRecord>> getPendingCandidates({
    String? workspaceId,
    int? limit,
  }) async {
    final port = _candidates;
    return port.getPendingCandidates(
      workspaceId ?? _system.config.workspaceId,
      limit: limit,
    );
  }

  /// Confirm a candidate, promoting it to a fact.
  Future<void> confirmCandidate(
    String candidateId, {
    String? reviewerId,
  }) async {
    final port = _candidates;
    await port.confirmCandidate(candidateId, reviewerId: reviewerId);
    _system.eventBus.emit(FactConfirmedEvent(
      factId: candidateId,
      entityId: '',
      factType: 'unknown',
      timestamp: DateTime.now(),
    ));
  }

  /// Reject a candidate.
  Future<void> rejectCandidate(
    String candidateId,
    String reason, {
    String? reviewerId,
  }) async {
    final port = _candidates;
    await port.rejectCandidate(
      candidateId,
      reason,
      reviewerId: reviewerId,
    );
  }

  // ── L1: Facts ────────────────────────────────────────────────────────────

  /// Query facts with a typed query.
  Future<List<FactRecord>> queryFacts(FactQuery query) async {
    final port = _facts;
    return port.queryFacts(query);
  }

  /// Get a single fact by ID.
  Future<FactRecord?> getFact(String id) async {
    final port = _facts;
    return port.getFact(id);
  }

  /// Get all facts for an entity.
  Future<List<FactRecord>> getFactsForEntity(
    String entityId, {
    String? workspaceId,
    Period? period,
    int? limit,
  }) async {
    final port = _facts;
    return port.queryFacts(FactQuery(
      workspaceId: workspaceId ?? _system.config.workspaceId,
      entityId: entityId,
      period: period,
      limit: limit,
    ));
  }

  /// Write a batch of facts.
  Future<void> writeFacts(List<FactRecord> facts) async {
    final port = _facts;
    await port.writeFacts(facts);
  }

  /// Delete facts by ID.
  Future<void> deleteFacts(List<String> ids) async {
    final port = _facts;
    await port.deleteFacts(ids);
  }

  // ── L1: Entities ─────────────────────────────────────────────────────────

  /// Get an entity by ID.
  Future<EntityRecord?> getEntity(String entityId) async {
    final port = _entities;
    return port.getEntity(entityId);
  }

  /// Merge two entities.
  Future<EntityRecord> mergeEntities(String surviving, String absorbed) async {
    final port = _entities;
    return port.mergeEntities(surviving, absorbed);
  }

  // ── L2: Claims ───────────────────────────────────────────────────────────

  /// Write claims with optional evidence references.
  Future<void> writeClaims(
    List<Claim> claims, {
    List<String>? evidenceRefs,
  }) async {
    final port = _claims;
    await port.writeClaims(claims, evidenceRefs: evidenceRefs);
    _system.eventBus.emit(ClaimsRecordedEvent(
      skillId: '',
      claimIds: claims.map((c) => c.id).toList(),
      entityId: claims.isNotEmpty ? (claims.first.subject ?? '') : '',
      timestamp: DateTime.now(),
    ));
  }

  /// Query claims with a typed query.
  Future<List<Claim>> queryClaims(ClaimQuery query) async {
    final port = _claims;
    return port.queryClaims(query);
  }

  // ── L2: Summaries ────────────────────────────────────────────────────────

  /// Get a summary for an entity.
  Future<SummaryRecord?> getSummary(
    String entityId,
    String summaryType, {
    Period? period,
  }) async {
    final port = _summaries;
    return port.getSummary(entityId, summaryType, period: period);
  }

  /// Refresh a summary on demand.
  Future<SummaryRecord> refreshSummary(
    String entityId,
    String summaryType, {
    Period? period,
  }) async {
    final port = _summaries;
    final result = await port.refreshSummary(
      entityId,
      summaryType,
      period: period,
    );
    _system.eventBus.emit(SummaryRefreshedEvent(
      summaryId: result.id,
      entityId: entityId,
      timestamp: DateTime.now(),
    ));
    return result;
  }

  /// Mark summaries as stale (worker will refresh asynchronously).
  Future<void> markSummariesStale(
    List<String> entityIds, {
    String? summaryType,
  }) async {
    final port = _summaries;
    return port.markSummariesStale(entityIds, summaryType: summaryType);
  }

  // ── L3: Patterns ─────────────────────────────────────────────────────────

  /// Store a pattern.
  Future<String> storePattern(PatternRecord pattern) async {
    final port = _patterns;
    return port.storePattern(pattern);
  }

  /// Query patterns.
  Future<List<PatternRecord>> queryPatterns(PatternQuery query) async {
    final port = _patterns;
    return port.queryPatterns(query);
  }

  /// Get a pattern by ID.
  Future<PatternRecord?> getPattern(String id) async {
    final port = _patterns;
    return port.getPattern(id);
  }
}
