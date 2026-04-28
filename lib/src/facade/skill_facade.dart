/// Skill Facade — thin wrapper around `SkillRuntime` (mcp_skill).
///
/// REDESIGN-PLAN Phase 8 §4 step 3 / DoD #3: this facade no longer
/// fabricates skill execution by calling `LlmPort.complete()` directly.
/// It delegates to a real `SkillRuntime` provided by the host. The 7-step
/// pipeline (route → context → plan → execute → validate → persist →
/// aggregate) actually runs.
library;

import 'package:mcp_bundle/mcp_bundle.dart' show SkillResult, Period;
import 'package:mcp_skill/mcp_skill.dart' as skill;

import '../system/knowledge_system.dart';
import '../events/knowledge_event.dart';

// Re-export key skill types so consumers can build SkillContext / budgets
// without importing mcp_skill directly.
export 'package:mcp_bundle/mcp_bundle.dart' show SkillResult;
export 'package:mcp_skill/mcp_skill.dart'
    show
        SkillRuntime,
        SkillContext,
        ExecutionBudget,
        BudgetTracker,
        MultiSkillRuntime,
        MultiSkillConfig,
        MultiSkillResult,
        MultiSkillMode,
        SkillRef;

/// Thin facade over [skill.SkillRuntime].
///
/// Holds a reference to the orchestrator and exposes ergonomic execute
/// methods. Every method requires `system.skillRuntime` to be non-null —
/// otherwise it throws a `StateError`.
class SkillFacade {
  final KnowledgeSystem _system;

  SkillFacade({required KnowledgeSystem system}) : _system = system;

  /// Access the orchestrator.
  KnowledgeSystem get system => _system;

  /// Whether a skill runtime is wired.
  bool get isAvailable => _system.skillRuntime != null;

  skill.SkillRuntime get _runtime {
    final rt = _system.skillRuntime;
    if (rt == null) {
      throw StateError(
        'SkillRuntime not configured — pass `skillRuntime: ...` to '
        'KnowledgeSystem to enable skill execution.',
      );
    }
    return rt;
  }

  // ── Execute ──────────────────────────────────────────────────────────────

  /// Execute a skill and return the canonical [SkillResult].
  ///
  /// Builds a [skill.SkillContext] from the supplied parameters and runs
  /// the full mcp_skill pipeline via `SkillRuntime.run()`.
  Future<SkillResult> execute(
    String skillId,
    Map<String, dynamic> inputs, {
    String? entityId,
    String? executionId,
    Period? period,
    skill.ExecutionBudget? budget,
    String? request,
  }) async {
    final runtime = _runtime;
    final startTime = DateTime.now();
    final context = _buildContext(
      skillId: skillId,
      inputs: inputs,
      entityId: entityId,
      executionId: executionId,
      period: period,
      budget: budget ?? _defaultBudget(),
      request: request,
    );

    try {
      final result = await runtime.run(context);
      final now = DateTime.now();
      _system.eventBus.emit(SkillExecutedEvent(
        skillId: skillId,
        executionId: context.runId,
        success: result.success,
        duration: now.difference(startTime),
        claimCount: result.claims.length,
        timestamp: now,
      ));
      if (result.claims.isNotEmpty) {
        _system.eventBus.emit(ClaimsRecordedEvent(
          skillId: skillId,
          claimIds: result.claims.map((c) => c.id).toList(),
          entityId: _resolveEntityId(entityId, inputs, result),
          timestamp: now,
        ));
      }
      return result;
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      _system.eventBus.emit(SkillExecutedEvent(
        skillId: skillId,
        executionId: context.runId,
        success: false,
        duration: duration,
        timestamp: DateTime.now(),
      ));
      return SkillResult.simpleError(e.toString(), duration);
    }
  }

  /// Execute a skill and return its primary output value.
  /// Throws [SkillException] on failure.
  Future<T> run<T>(String skillId, Map<String, dynamic> inputs) async {
    final result = await execute(skillId, inputs);
    if (!result.success) {
      final errorMsg =
          result.metadata.custom?['error'] as String? ?? 'Unknown error';
      throw SkillException(errorMsg);
    }
    return result.metadata.custom?['output'] as T;
  }

  /// Execute a skill with an explicit caller-built [skill.SkillContext].
  ///
  /// Use this when you need full control over runId/traceId/contextBundle.
  Future<SkillResult> executeWithContext(skill.SkillContext context) async {
    final runtime = _runtime;
    final startTime = DateTime.now();
    try {
      final result = await runtime.run(context);
      final now = DateTime.now();
      _system.eventBus.emit(SkillExecutedEvent(
        skillId: context.skillId,
        executionId: context.runId,
        success: result.success,
        duration: now.difference(startTime),
        claimCount: result.claims.length,
        timestamp: now,
      ));
      if (result.claims.isNotEmpty) {
        _system.eventBus.emit(ClaimsRecordedEvent(
          skillId: context.skillId,
          claimIds: result.claims.map((c) => c.id).toList(),
          entityId: _resolveEntityId(context.userId, context.inputs, result),
          timestamp: now,
        ));
      }
      return result;
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      _system.eventBus.emit(SkillExecutedEvent(
        skillId: context.skillId,
        executionId: context.runId,
        success: false,
        duration: duration,
        timestamp: DateTime.now(),
      ));
      return SkillResult.simpleError(e.toString(), duration);
    }
  }

  /// Map the system's [ExecutionBudgetConfig] (if any) to a runtime
  /// [skill.ExecutionBudget]. Returns null when no default is configured.
  skill.ExecutionBudget? _defaultBudget() {
    final cfg = _system.config.skill.defaultBudget;
    if (cfg == null) return null;
    return skill.ExecutionBudget(
      maxTokens: cfg.maxTokens,
      maxDuration: cfg.maxDuration,
      maxSteps: cfg.maxSteps,
      maxLlmCalls: cfg.maxLlmCalls,
      maxMcpCalls: cfg.maxMcpCalls,
      maxConcurrency: cfg.maxConcurrency,
    );
  }

  /// Resolve the best-effort entity ID for a [ClaimsRecordedEvent].
  ///
  /// Priority: explicit `entityId` argument → first claim's RDF subject →
  /// `inputs['entityId']` → empty string.
  String _resolveEntityId(
    String? entityId,
    Map<String, dynamic> inputs,
    SkillResult result,
  ) {
    if (entityId != null && entityId.isNotEmpty) return entityId;
    if (result.claims.isNotEmpty) {
      final subj = result.claims.first.subject;
      if (subj != null && subj.isNotEmpty) return subj;
    }
    final fromInputs = inputs['entityId'];
    if (fromInputs is String && fromInputs.isNotEmpty) return fromInputs;
    return '';
  }

  // ── Context construction helper ──────────────────────────────────────────

  skill.SkillContext _buildContext({
    required String skillId,
    required Map<String, dynamic> inputs,
    String? entityId,
    String? executionId,
    Period? period,
    skill.ExecutionBudget? budget,
    String? request,
  }) {
    final now = DateTime.now();
    final id =
        executionId ?? 'exec-${now.microsecondsSinceEpoch}';
    return skill.SkillContext(
      contextId: 'ctx-$id',
      skillId: skillId,
      runId: id,
      traceId: 'trace-$id',
      request: request ?? '',
      workspaceId: _system.config.workspaceId,
      asOf: now,
      period: period,
      inputs: inputs,
      budget: budget,
      userId: entityId,
    );
  }
}

/// Skill exception raised by [SkillFacade.run].
class SkillException implements Exception {
  final String message;
  SkillException(this.message);

  @override
  String toString() => 'SkillException: $message';
}
