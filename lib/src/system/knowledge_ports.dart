/// Knowledge Ports — flat standard-port container per REDESIGN-PLAN Phase 8.
///
/// `mcp_knowledge` is an orchestrator, not a port provider. This container
/// only aggregates the standard ports defined in `mcp_bundle` and consumed
/// by the runtimes that `KnowledgeSystem` orchestrates. Every field maps
/// directly to a capability-named port from `mcp_bundle` — no wrappers,
/// no shims, no consumer-sliced legacy ports.
library;

import 'package:mcp_bundle/mcp_bundle.dart';

// Re-export the standard port surface so consumers do not have to import
// `package:mcp_bundle/...` directly. Only the ports actually carried in
// `KnowledgePorts` are exposed here.
export 'package:mcp_bundle/mcp_bundle.dart'
    show
        // Data / fact-graph capabilities
        FactsPort,
        StubFactsPort,
        FactRecord,
        FactQuery,
        ClaimsPort,
        StubClaimsPort,
        ClaimQuery,
        ClaimValidationReport,
        EntitiesPort,
        StubEntitiesPort,
        EntityRecord,
        EntityQuery,
        CandidatesPort,
        StubCandidatesPort,
        CandidateRecord,
        CandidateStatus,
        EvidencePort,
        StubEvidencePort,
        EvidenceFragment,
        PatternsPort,
        StubPatternsPort,
        PatternRecord,
        PatternQuery,
        SummariesPort,
        StubSummariesPort,
        SummaryRecord,
        RunsPort,
        StubRunsPort,
        ContextBundlePort,
        StubContextBundlePort,
        RetrievalPort,
        StubRetrievalPort,
        AssetPort,
        StubAssetPort,
        IndexPort,
        // Execution
        SkillRuntimePort,
        StubSkillRuntimePort,
        SkillRunHandle,
        SkillRegistryPort,
        McpPort,
        StubMcpPort,
        ToolResult,
        ToolInfo,
        ResourceInfo,
        LlmPort,
        StubLlmPort,
        EmptyLlmPort,
        LlmRequest,
        LlmResponse,
        LlmMessage,
        LlmCapabilities,
        LlmUsage,
        LlmChunk,
        LlmTool,
        LlmToolCall,
        // Evaluation (mcp_profile capabilities)
        MetricsPort,
        StubMetricsPort,
        AppraisalPort,
        StubAppraisalPort,
        DecisionPort,
        StubDecisionPort,
        ExpressionPort,
        StubExpressionPort,
        ProfileSummariesPort,
        StubProfileSummariesPort,
        // Philosophy
        PhilosophyPort,
        StubPhilosophyPort,
        EthosStorePort,
        StubEthosStorePort,
        // Ops capabilities (provided by mcp_knowledge_ops)
        WorkflowPort,
        StubWorkflowPort,
        WorkflowRunHandle,
        WorkflowDescriptor,
        PipelinePort,
        StubPipelinePort,
        PipelineRunHandle,
        ScheduleTriggerPort,
        StubScheduleTriggerPort,
        AuditPort,
        StubAuditPort,
        RunbookPort,
        StubRunbookPort,
        // Cross-cutting
        KvStoragePort,
        InMemoryKvStoragePort,
        ApprovalPort,
        StubApprovalPort,
        NotificationPort,
        StubNotificationPort,
        EventPort,
        InMemoryEventPort,
        PortEvent,
        MetricPort,
        StubMetricPort,
        MetricValue,
        // Shared types used by hosts wiring runtimes
        Period,
        RelativePeriod,
        AbsolutePeriod,
        PeriodUnit,
        PeriodDirection,
        DateRange;

/// Flat container of standard ports consumed by `KnowledgeSystem`.
///
/// REDESIGN-PLAN Phase 8 §3.1: `mcp_knowledge` exposes **no** ports of its
/// own. This class is purely a DI bundle so hosts can pass a single value
/// to [KnowledgeSystem] instead of fifteen positional parameters.
///
/// All fields are optional. Hosts wire only the ports they need; the
/// orchestrator gracefully degrades when a capability is absent.
class KnowledgePorts {
  // ── Data / fact-graph capabilities ──────────────────────────────────────
  final FactsPort? facts;
  final ClaimsPort? claims;
  final EntitiesPort? entities;
  final CandidatesPort? candidates;
  final EvidencePort? evidence;
  final PatternsPort? patterns;
  final SummariesPort? summaries;
  final RunsPort? runs;
  final ContextBundlePort? contextBundle;
  final RetrievalPort? retrieval;
  final AssetPort? asset;
  final IndexPort? index;

  // ── Execution capabilities ──────────────────────────────────────────────
  final SkillRuntimePort? skillRuntime;
  final SkillRegistryPort? skillRegistry;
  final McpPort? mcp;
  final LlmPort? llm;

  // ── Evaluation (profile) capabilities ───────────────────────────────────
  final MetricsPort? metrics;
  final AppraisalPort? appraisal;
  final DecisionPort? decision;
  final ExpressionPort? expression;
  final ProfileSummariesPort? profileSummaries;

  // ── Philosophy capabilities ─────────────────────────────────────────────
  final PhilosophyPort? philosophy;
  final EthosStorePort? ethosStore;

  // ── Ops capabilities ────────────────────────────────────────────────────
  final WorkflowPort? workflow;
  final PipelinePort? pipeline;
  final ScheduleTriggerPort? scheduler;
  final AuditPort? audit;
  final RunbookPort? runbook;

  // ── Cross-cutting capabilities ──────────────────────────────────────────
  final KvStoragePort? kvStorage;
  final ApprovalPort? approval;
  final NotificationPort? notification;
  final EventPort? event;
  final MetricPort? metric;

  const KnowledgePorts({
    this.facts,
    this.claims,
    this.entities,
    this.candidates,
    this.evidence,
    this.patterns,
    this.summaries,
    this.runs,
    this.contextBundle,
    this.retrieval,
    this.asset,
    this.index,
    this.skillRuntime,
    this.skillRegistry,
    this.mcp,
    this.llm,
    this.metrics,
    this.appraisal,
    this.decision,
    this.expression,
    this.profileSummaries,
    this.philosophy,
    this.ethosStore,
    this.workflow,
    this.pipeline,
    this.scheduler,
    this.audit,
    this.runbook,
    this.kvStorage,
    this.approval,
    this.notification,
    this.event,
    this.metric,
  });

  /// Test-only stub factory wiring every port to its in-memory stub.
  factory KnowledgePorts.stub() {
    return KnowledgePorts(
      facts: const StubFactsPort(),
      claims: const StubClaimsPort(),
      entities: const StubEntitiesPort(),
      candidates: const StubCandidatesPort(),
      evidence: const StubEvidencePort(),
      patterns: const StubPatternsPort(),
      summaries: const StubSummariesPort(),
      runs: const StubRunsPort(),
      contextBundle: const StubContextBundlePort(),
      retrieval: const StubRetrievalPort(),
      asset: const StubAssetPort(),
      skillRuntime: const StubSkillRuntimePort(),
      mcp: const StubMcpPort(),
      llm: StubLlmPort(),
      metrics: const StubMetricsPort(),
      appraisal: const StubAppraisalPort(),
      decision: const StubDecisionPort(),
      expression: const StubExpressionPort(),
      profileSummaries: const StubProfileSummariesPort(),
      philosophy: const StubPhilosophyPort(),
      ethosStore: const StubEthosStorePort(),
      workflow: const StubWorkflowPort(),
      pipeline: const StubPipelinePort(),
      scheduler: const StubScheduleTriggerPort(),
      audit: const StubAuditPort(),
      runbook: const StubRunbookPort(),
      kvStorage: InMemoryKvStoragePort(),
      approval: StubApprovalPort(),
      notification: StubNotificationPort(),
      event: InMemoryEventPort(),
      metric: StubMetricPort(),
    );
  }

  /// Return a copy with the supplied fields replaced.
  KnowledgePorts copyWith({
    FactsPort? facts,
    ClaimsPort? claims,
    EntitiesPort? entities,
    CandidatesPort? candidates,
    EvidencePort? evidence,
    PatternsPort? patterns,
    SummariesPort? summaries,
    RunsPort? runs,
    ContextBundlePort? contextBundle,
    RetrievalPort? retrieval,
    AssetPort? asset,
    IndexPort? index,
    SkillRuntimePort? skillRuntime,
    SkillRegistryPort? skillRegistry,
    McpPort? mcp,
    LlmPort? llm,
    MetricsPort? metrics,
    AppraisalPort? appraisal,
    DecisionPort? decision,
    ExpressionPort? expression,
    ProfileSummariesPort? profileSummaries,
    PhilosophyPort? philosophy,
    EthosStorePort? ethosStore,
    WorkflowPort? workflow,
    PipelinePort? pipeline,
    ScheduleTriggerPort? scheduler,
    AuditPort? audit,
    RunbookPort? runbook,
    KvStoragePort? kvStorage,
    ApprovalPort? approval,
    NotificationPort? notification,
    EventPort? event,
    MetricPort? metric,
  }) {
    return KnowledgePorts(
      facts: facts ?? this.facts,
      claims: claims ?? this.claims,
      entities: entities ?? this.entities,
      candidates: candidates ?? this.candidates,
      evidence: evidence ?? this.evidence,
      patterns: patterns ?? this.patterns,
      summaries: summaries ?? this.summaries,
      runs: runs ?? this.runs,
      contextBundle: contextBundle ?? this.contextBundle,
      retrieval: retrieval ?? this.retrieval,
      asset: asset ?? this.asset,
      index: index ?? this.index,
      skillRuntime: skillRuntime ?? this.skillRuntime,
      skillRegistry: skillRegistry ?? this.skillRegistry,
      mcp: mcp ?? this.mcp,
      llm: llm ?? this.llm,
      metrics: metrics ?? this.metrics,
      appraisal: appraisal ?? this.appraisal,
      decision: decision ?? this.decision,
      expression: expression ?? this.expression,
      profileSummaries: profileSummaries ?? this.profileSummaries,
      philosophy: philosophy ?? this.philosophy,
      ethosStore: ethosStore ?? this.ethosStore,
      workflow: workflow ?? this.workflow,
      pipeline: pipeline ?? this.pipeline,
      scheduler: scheduler ?? this.scheduler,
      audit: audit ?? this.audit,
      runbook: runbook ?? this.runbook,
      kvStorage: kvStorage ?? this.kvStorage,
      approval: approval ?? this.approval,
      notification: notification ?? this.notification,
      event: event ?? this.event,
      metric: metric ?? this.metric,
    );
  }
}
