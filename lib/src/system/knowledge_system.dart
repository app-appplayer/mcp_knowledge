/// Knowledge System — the knowledge-domain complete core.
///
/// `KnowledgeSystem` is the **single entry point** for the knowledge stack.
/// It composes the five domain runtimes:
///
///   - `FactGraphRuntime` (mcp_fact_graph) — L0, required
///   - `SkillRuntime` (mcp_skill) — L1, opt-in
///   - `ProfileRuntime` (mcp_profile) — L2, opt-in
///   - `PhilosophyEngine` (mcp_philosophy) — L3, opt-in
///   - `OpsRuntime` (mcp_knowledge_ops) — opt-in
///
/// L0 FactGraph is a required layer. When the caller does not supply a
/// `FactGraphRuntime`, a default `FactGraphRuntime.inMemory()` is auto-
/// wired so the knowledge-accumulation cycle (evidence → candidates →
/// facts → queries) works with zero external adapters.
///
/// L1~L3 and Ops are opt-in. Their facades throw `StateError` when the
/// runtime is not activated. Infrastructure capabilities (LLM, KV,
/// MCP, Retrieval, Notification, Event, Metric) are injected via the
/// ports container; all other ports are core-internal.
library;

import 'package:mcp_fact_graph/mcp_fact_graph.dart' show FactGraphRuntime;
import 'package:mcp_philosophy/mcp_philosophy.dart' show PhilosophyEngine;

import 'knowledge_config.dart';
import 'knowledge_ports.dart';
import '../events/event_bus.dart';
import '../events/knowledge_event.dart';
import '../facade/fact_facade.dart';
import '../facade/skill_facade.dart';
import '../facade/profile_facade.dart';
import '../facade/philosophy_facade.dart';
import '../facade/ops_facade.dart';

/// Unified knowledge management orchestrator.
///
/// Composes the five domain runtimes and exposes them through thin
/// facades. The runtimes themselves are constructed and wired by the host
/// — `KnowledgeSystem` only orchestrates them.
class KnowledgeSystem {
  /// System configuration.
  final KnowledgeConfig config;

  /// Standard-port container — the host-supplied capabilities consumed
  /// across the orchestrator. May be empty when every runtime injected
  /// already carries its own ports.
  final KnowledgePorts ports;

  /// Event bus for cross-component observability events.
  final KnowledgeEventBus eventBus;

  // ── Optional runtimes (scenario H — partial orchestration) ──────────────

  /// Fact graph runtime (mcp_fact_graph). L0 is a required layer — when
  /// the constructor parameter is null, a default
  /// `FactGraphRuntime.inMemory()` is auto-wired so the system works
  /// with zero external adapters.
  final FactGraphRuntime factGraph;

  /// Skill runtime (mcp_skill). Null when skill execution is not in scope.
  final SkillRuntime? skillRuntime;

  /// Profile runtime (mcp_profile). Null when profile evaluation is not
  /// in scope.
  final ProfileRuntime? profileRuntime;

  /// Philosophy engine (mcp_philosophy). Null when philosophy evaluation
  /// is not in scope. When provided, the engine is also exposed through
  /// `ports.philosophy` so other components can consume it.
  final PhilosophyEngine? philosophyEngine;

  /// Ops runtime (mcp_knowledge_ops). Null when workflow/pipeline
  /// orchestration is not in scope.
  final OpsRuntime? opsRuntime;

  // ── Facades ──────────────────────────────────────────────────────────────

  /// Simplified fact graph operations.
  late final FactFacade facts;

  /// Simplified skill operations.
  late final SkillFacade skill;

  /// Simplified profile operations.
  late final ProfileFacade profile;

  /// Simplified philosophy operations.
  late final PhilosophyFacade philosophy;

  /// Simplified ops (workflow / pipeline / runbook) operations.
  late final OpsFacade ops;

  /// Create a new knowledge system.
  ///
  /// L0 FactGraph is required. When `factGraph` is null, a default
  /// `FactGraphRuntime.inMemory()` is auto-wired so the system works
  /// with zero external adapters out of the box.
  ///
  /// L1 Skill / L2 Profile / L3 Philosophy / Ops are opt-in. Pass only
  /// the runtimes for layers in scope. Inactive layer facades will throw
  /// `StateError` when invoked.
  KnowledgeSystem({
    required this.config,
    KnowledgePorts? ports,
    FactGraphRuntime? factGraph,
    this.skillRuntime,
    this.profileRuntime,
    this.philosophyEngine,
    this.opsRuntime,
    KnowledgeEventBus? eventBus,
  })  : ports = ports ?? const KnowledgePorts(),
        factGraph = factGraph ?? FactGraphRuntime.inMemory(
          defaultWorkspaceId: config.workspaceId,
        ),
        eventBus = eventBus ?? KnowledgeEventBus() {
    _initialize();
  }

  /// Default-config shorthand factory. L0 FactGraph is auto-wired.
  factory KnowledgeSystem.defaults({
    KnowledgePorts? ports,
    FactGraphRuntime? factGraph,
    SkillRuntime? skillRuntime,
    ProfileRuntime? profileRuntime,
    PhilosophyEngine? philosophyEngine,
    OpsRuntime? opsRuntime,
  }) {
    return KnowledgeSystem(
      config: KnowledgeConfig.defaults,
      ports: ports,
      factGraph: factGraph,
      skillRuntime: skillRuntime,
      profileRuntime: profileRuntime,
      philosophyEngine: philosophyEngine,
      opsRuntime: opsRuntime,
    );
  }

  /// Zero-config factory for tests and quick-starts. Auto-wires
  /// L0 `FactGraphRuntime.inMemory()` and `KnowledgePorts.stub()`
  /// (which provides `InMemoryKvStoragePort` and `InMemoryEventPort`).
  /// The L0 FactGraph cycle (evidence → candidates → facts → queries)
  /// works immediately without external adapters. L1~L3+Ops runtimes
  /// remain null; their facades throw `StateError` when invoked.
  factory KnowledgeSystem.stub() {
    return KnowledgeSystem(
      config: KnowledgeConfig.defaults,
      ports: KnowledgePorts.stub(),
    );
  }

  void _initialize() {
    facts = FactFacade(system: this);
    skill = SkillFacade(system: this);
    profile = ProfileFacade(system: this);
    philosophy = PhilosophyFacade(system: this);
    ops = OpsFacade(system: this);
  }

  /// Gracefully shutdown the system. Closes the L0 FactGraph runtime,
  /// emits `SystemShutdownEvent`, and closes the event bus. Host-owned
  /// opt-in runtimes (skill / profile / philosophy / ops) and external
  /// infrastructure adapters must be cleaned up by the host.
  Future<void> shutdown() async {
    await factGraph.close();
    eventBus.emit(SystemShutdownEvent(timestamp: DateTime.now()));
    await eventBus.close();
  }
}
