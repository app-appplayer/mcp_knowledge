/// MCP Knowledge — orchestration facade for the MakeMind knowledge stack.
///
/// 0.2.0 redesign per `REDESIGN-PLAN.md` Phase 8:
///
///   - **Orchestrator only.** `mcp_knowledge` defines no ports of its own.
///     It composes the runtimes provided by `mcp_fact_graph`,
///     `mcp_skill`, `mcp_profile`, `mcp_philosophy`, and
///     `mcp_knowledge_ops`, and exposes them through thin facades.
///   - **Standard ports only.** All consumed capabilities are the
///     capability-named standard ports defined in `mcp_bundle`. No
///     consumer-sliced legacy ports remain.
///   - **No bridges.** The six legacy `bridge/` files were deleted —
///     consumers query the standard ports directly.
///   - **No raw-accessor adapters.** The five legacy `adapters/` files
///     were deleted; the runtimes expose their adapters themselves.
///
/// ## Quick start (scenario G — full orchestration)
///
/// ```dart
/// import 'package:mcp_knowledge/mcp_knowledge.dart';
///
/// final factGraph = FactGraphRuntime.inMemory();
/// await factGraph.initialize();
///
/// final system = KnowledgeSystem(
///   config: KnowledgeConfig.defaults,
///   ports: KnowledgePorts(
///     facts: factGraph.facts,
///     claims: factGraph.claims,
///     // ... other capabilities
///     llm: StubLlmPort(),
///     mcp: const StubMcpPort(),
///   ),
///   factGraph: factGraph,
///   // skillRuntime: ...
///   // profileRuntime: ...
///   // philosophyEngine: ...
///   // opsRuntime: ...
/// );
///
/// final result = await system.profile.apply('p1', entityId: 'e1');
/// ```
///
/// ## Scenario H — partial orchestration
///
/// ```dart
/// final system = KnowledgeSystem(
///   config: KnowledgeConfig.defaults,
///   factGraph: factGraph,
///   skillRuntime: skillRuntime,
///   // philosophyEngine and opsRuntime intentionally omitted
/// );
/// ```
library mcp_knowledge;

// === Core system ===
export 'src/system/knowledge_system.dart';
export 'src/system/knowledge_config.dart';
export 'src/system/knowledge_ports.dart';

// === Facades ===
export 'src/facade/fact_facade.dart';
export 'src/facade/skill_facade.dart';
export 'src/facade/profile_facade.dart';
export 'src/facade/philosophy_facade.dart';
export 'src/facade/ops_facade.dart';

// === Events ===
export 'src/events/knowledge_event.dart';
export 'src/events/event_bus.dart';

// === Sub-package barrel re-exports — complete technical facade (FR-EXPORT-*) ===
//
// Consumers get every public type of the five knowledge sub-packages through
// this single import. Name collisions are resolved below with `hide` on one
// side; rationale is recorded in `docs/07_CHANGELOG/CHANGELOG.md` under the
// 0.3.0 entry.
//
// Collision policy
// ----------------
// The following symbols appear in more than one sub-package barrel. For
// each, `hide` is applied on one side so the knowledge barrel compiles
// unambiguously. Kept side is the one a consumer is most likely to reach
// for through the knowledge facade; dropped side remains accessible via
// a direct import of the owning package when needed.
//
// * `CandidateStatus`     — kept: `mcp_bundle` port enum (surfaces via
//                           mcp_fact_graph). Hidden: mcp_fact_graph's own.
// * `Claim` / `ClaimType` — kept: mcp_bundle port-level contract via
//                           mcp_fact_graph's transitive chain. Hidden:
//                           mcp_fact_graph's own duplicate re-export.
// * `ContextBundle`       — kept: mcp_bundle port-level class. Hidden:
//                           mcp_fact_graph's alias.
// * `Artifact`            — kept: `mcp_knowledge_ops` execution artifact.
//                           Hidden: mcp_fact_graph's entity (renamed at
//                           callsite if needed).
// * `SkillException`      — kept: `mcp_skill` domain exception. Hidden:
//                           the facade-local exception (internal only).
// * `ExecutionContext`    — kept: `mcp_knowledge_ops` pipeline context.
//                           Hidden: mcp_skill's (use SkillRuntime types).
// * `ConflictResolution`  — kept: `mcp_philosophy` semantics. Hidden:
//                           mcp_profile's (guidance-internal).
// * `ExpressionFunction`  — kept: `mcp_profile` expression function type.
//                           Hidden: mcp_skill's registry entry.
// * `EvaluationException` — kept: `mcp_philosophy`'s (ethos evaluation).
//                           Hidden: mcp_skill's expression exception.
// * `Period` / `Skill`    — kept: `mcp_bundle` port types (surface via
//                           mcp_fact_graph's re-export of the bundle layer).
//                           Hidden: mcp_fact_graph's domain duplicates.
// * `SkillStep`           — kept: `mcp_skill`'s authoritative definition.
//                           Hidden: mcp_fact_graph's domain duplicate.
// * `ConflictResolver`    — kept: `mcp_philosophy`'s resolver. Hidden:
//                           mcp_profile's (guidance-internal).
// * `ExpressionEvaluator` — kept: `mcp_knowledge_ops` gate evaluator.
//                           Hidden: mcp_skill's and mcp_profile's.
// * `LogLevel`            — kept: this package's `knowledge_config.dart`
//                           config enum. Hidden: mcp_knowledge_ops's
//                           observability enum.
export 'package:mcp_fact_graph/mcp_fact_graph.dart'
    hide
        CandidateStatus,
        ClaimType,
        ClaimStatus,
        ContextBundle,
        Artifact,
        Period,
        RetryPolicy,
        Skill,
        SummaryScope,
        PatternScope,
        FeatureVector,
        ValidationResult,
        SkillStep,
        QualityGate,
        LogEntry,
        VerificationResult,
        SkillExecutionResult,
        StepExecution,
        Finding;
export 'package:mcp_skill/mcp_skill.dart'
    hide
        SkillException,
        ExecutionContext,
        ExpressionFunction,
        ExpressionEvaluator,
        EvaluationException,
        ProfileRuntime,
        ProfileRegistry,
        Profile,
        ProfileContext,
        DecisionAction,
        DecisionGuidance,
        ExpressionStyle,
        SkillConfig,
        FeatureFlags,
        ConflictReport,
        ConflictResolution,
        ProfileRuntimeHook,
        CircuitOpenException,
        CircuitBreaker,
        EdgeType,
        Rubric,
        RubricDimension,
        ScoreLevel,
        EvaluationInput,
        EvaluationContext,
        EvaluationResult,
        VersionConstraint,
        RetryExecutor,
        ErrorAggregator,
        RecoveryStrategy,
        RecoveryResult,
        RetryPolicy,
        TimeoutException,
        RetryConfig;
export 'package:mcp_profile/mcp_profile.dart'
    hide ConflictResolution, ConflictResolver, ExpressionEvaluator;
export 'package:mcp_philosophy/mcp_philosophy.dart';
export 'package:mcp_knowledge_ops/mcp_knowledge_ops.dart'
    hide
        LogLevel,
        RunbookExecution,
        PipelineConfig,
        Artifact,
        PipelineContext,
        SkillBundle,
        PipelineCompletedEvent,
        SkillExecutedEvent,
        ProfileAppliedEvent,
        EventConfig,
        TriggerType,
        ExecutionResult;
