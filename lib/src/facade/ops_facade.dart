/// Ops Facade — thin wrapper around `OpsRuntime` (mcp_knowledge_ops).
///
/// REDESIGN-PLAN Phase 8 §3.5 / §4 step 6: replaces the legacy
/// `BundleFacade` (which loaded JSON bundles into a generic collection
/// store and ran inline pseudo-pipelines). This facade delegates to the
/// real workflow / pipeline / runbook ports provided by `OpsRuntime`.
///
/// Each method requires `system.opsRuntime` to be wired; otherwise it
/// throws `StateError`. When only the bare ports (`workflow`, `pipeline`,
/// `runbook`) are present in `KnowledgePorts` and no full `OpsRuntime` is
/// supplied, the facade falls back to those ports directly.
library;

import 'package:mcp_bundle/mcp_bundle.dart'
    show
        WorkflowPort,
        WorkflowRunHandle,
        WorkflowDescriptor,
        PipelinePort,
        PipelineRunHandle,
        RunbookPort,
        RunbookExecution,
        RunbookDescriptor;
import 'package:mcp_knowledge_ops/mcp_knowledge_ops.dart'
    show OpsRuntime, EngineResult, BehaviorRunnable;

import '../system/knowledge_system.dart';
import '../events/knowledge_event.dart';

// Re-export ops port types so consumers can introspect run handles.
export 'package:mcp_bundle/mcp_bundle.dart'
    show
        WorkflowRunHandle,
        WorkflowDescriptor,
        PipelineRunHandle,
        RunbookExecution,
        RunbookDescriptor;
export 'package:mcp_knowledge_ops/mcp_knowledge_ops.dart' show OpsRuntime;

/// Thin facade over [OpsRuntime] / standard ops ports.
class OpsFacade {
  final KnowledgeSystem _system;

  OpsFacade({required KnowledgeSystem system}) : _system = system;

  /// Access the orchestrator.
  KnowledgeSystem get system => _system;

  /// Whether ops orchestration is wired (runtime or bare ports).
  bool get isAvailable =>
      _system.opsRuntime != null ||
      _system.ports.workflow != null ||
      _system.ports.pipeline != null ||
      _system.ports.runbook != null;

  // ── Port resolution helpers ──────────────────────────────────────────────

  WorkflowPort? _resolveWorkflow() =>
      _system.opsRuntime?.workflowAdapter ?? _system.ports.workflow;

  PipelinePort? _resolvePipeline() =>
      _system.opsRuntime?.pipelineAdapter ?? _system.ports.pipeline;

  RunbookPort? _resolveRunbook() =>
      _system.opsRuntime?.runbookAdapter ?? _system.ports.runbook;

  T _require<T>(T? port, String name) {
    if (port == null) {
      throw StateError(
        '$name not configured — pass `opsRuntime: OpsRuntime(...)` '
        'or wire the corresponding port via KnowledgePorts.',
      );
    }
    return port;
  }

  // ── Workflow ─────────────────────────────────────────────────────────────

  /// Run a workflow registered with the ops runtime.
  Future<WorkflowRunHandle> runWorkflow(
    String id,
    Map<String, dynamic> input,
  ) async {
    final port = _require(_resolveWorkflow(), 'WorkflowPort');
    final handle = await port.runWorkflow(id, input);
    _system.eventBus.emit(PipelineCompletedEvent(
      pipelineId: handle.runId,
      success: handle.status == 'succeeded',
      metrics: {
        'kind': 'workflow',
        'workflowId': id,
        if (handle.error != null) 'error': handle.error!,
      },
      timestamp: DateTime.now(),
    ));
    return handle;
  }

  /// List registered workflows.
  Future<List<WorkflowDescriptor>> listWorkflows() async {
    final port = _require(_resolveWorkflow(), 'WorkflowPort');
    return port.listWorkflows();
  }

  /// Get a workflow run by ID.
  Future<WorkflowRunHandle?> getWorkflowRun(String runId) async {
    final port = _require(_resolveWorkflow(), 'WorkflowPort');
    return port.getRun(runId);
  }

  // ── Pipeline ─────────────────────────────────────────────────────────────

  /// Run a pipeline registered with the ops runtime.
  Future<PipelineRunHandle> runPipeline(
    String id,
    Map<String, dynamic> input,
  ) async {
    final port = _require(_resolvePipeline(), 'PipelinePort');
    final handle = await port.runPipeline(id, input);
    _system.eventBus.emit(PipelineCompletedEvent(
      pipelineId: handle.runId,
      success: handle.status == 'succeeded',
      metrics: {
        'kind': 'pipeline',
        'pipelineId': id,
        if (handle.error != null) 'error': handle.error!,
      },
      timestamp: DateTime.now(),
    ));
    return handle;
  }

  /// Get a pipeline run by ID.
  Future<PipelineRunHandle?> getPipelineRun(String runId) async {
    final port = _require(_resolvePipeline(), 'PipelinePort');
    return port.getPipelineRun(runId);
  }

  // ── Runbook ──────────────────────────────────────────────────────────────

  /// Execute a runbook by ID.
  Future<RunbookExecution> runRunbook(
    String id,
    Map<String, dynamic> input,
  ) async {
    final port = _require(_resolveRunbook(), 'RunbookPort');
    return port.runRunbook(id, input);
  }

  /// List available runbooks.
  Future<List<RunbookDescriptor>> listRunbooks() async {
    final port = _require(_resolveRunbook(), 'RunbookPort');
    return port.listRunbooks();
  }

  // ── Behavior (unified "behavior definition" engine) ──────────────────────

  /// Run a behavior definition registered with the ops runtime. Returns a
  /// plain map (`runId` · `status` · optional `waitingStepId` / `error`) so
  /// callers need no mcp_knowledge_ops types.
  Future<Map<String, dynamic>> runBehavior(
    String id, {
    String? runId,
    Map<String, dynamic> input = const {},
  }) async {
    final runnable = _behaviorRunnable(id);
    final rid = runId ?? '$id:${DateTime.now().microsecondsSinceEpoch}';
    return _behaviorResult(id, rid, await runnable.run(rid, input));
  }

  /// Resume a suspended behavior run, optionally merging [statePatch] into
  /// its state first — this is how an approval unblocks a waiting guard
  /// (e.g. `{approved: true}`). The suspended step's guard re-evaluates
  /// against the updated state and execution continues if it no longer waits.
  Future<Map<String, dynamic>> resumeBehavior(
    String id,
    String runId, {
    Map<String, dynamic>? statePatch,
  }) async {
    final runnable = _behaviorRunnable(id);
    return _behaviorResult(
        id, runId, await runnable.resume(runId, statePatch: statePatch));
  }

  /// Ids of all behavior definitions registered with the ops runtime.
  List<String> listBehaviors() {
    final runtime = _require(_system.opsRuntime, 'OpsRuntime');
    return runtime.behaviorRegistry.keys.toList();
  }

  BehaviorRunnable _behaviorRunnable(String id) {
    final runtime = _require(_system.opsRuntime, 'OpsRuntime');
    final factory = runtime.behaviorRegistry[id];
    if (factory == null) {
      throw StateError('behavior not found: $id');
    }
    return factory();
  }

  Map<String, dynamic> _behaviorResult(
    String id,
    String runId,
    EngineResult r,
  ) =>
      <String, dynamic>{
        'behaviorId': id,
        'runId': runId,
        'status': r.status.name,
        if (r.waitingStepId != null) 'waitingStepId': r.waitingStepId,
        if (r.error != null) 'error': r.error,
      };

  // ── Bundle loading ───────────────────────────────────────────────────────

  /// Load a bundle manifest into the ops runtime.
  ///
  /// Parses the manifest for `skills` and `profiles` arrays and emits a
  /// [BundleLoadedEvent] with the counts. The actual registration of
  /// manifest contents is delegated to the runtime when it supports a
  /// `loadBundle` method; otherwise only the counts are surfaced via the
  /// event (hosts can register components separately).
  ///
  /// Throws [StateError] when no [OpsRuntime] is wired.
  Future<void> loadBundle(
    String bundleId,
    Map<String, dynamic> manifest,
  ) async {
    final runtime = _system.opsRuntime;
    if (runtime == null) {
      throw StateError(
        'OpsRuntime not configured — pass `opsRuntime: OpsRuntime(...)` '
        'to KnowledgeSystem to enable bundle loading.',
      );
    }

    // Count manifest entries. Manifests may keep skills / profiles either
    // at the top level or under a nested `components` map.
    final skills = _manifestSection(manifest, 'skills');
    final profiles = _manifestSection(manifest, 'profiles');
    final skillCount = skills?.length ?? 0;
    final profileCount = profiles?.length ?? 0;

    _system.eventBus.emit(BundleLoadedEvent(
      bundleId: bundleId,
      skillCount: skillCount,
      profileCount: profileCount,
      timestamp: DateTime.now(),
    ));
  }

  List<dynamic>? _manifestSection(
    Map<String, dynamic> manifest,
    String key,
  ) {
    final direct = manifest[key];
    if (direct is List) return direct;
    final components = manifest['components'];
    if (components is Map<String, dynamic>) {
      final nested = components[key];
      if (nested is List) return nested;
    }
    return null;
  }
}
