/// Philosophy Facade — thin wrapper around `PhilosophyEngine` (mcp_philosophy).
///
/// REDESIGN-PLAN Phase 8 §4 step 6: this facade no longer needs the
/// philosophy bridges (`philosophy_fact_bridge`, `philosophy_skill_bridge`,
/// `philosophy_profile_bridge`). The `PhilosophyEngine` consumes
/// `FactsPort`/`EvidencePort`/`ContextBundlePort` directly during its
/// own construction, so this facade only adds event emission and
/// config-gating for intervention points.
library;

import 'package:mcp_bundle/mcp_bundle.dart'
    show
        PhilosophyPort,
        PhilosophyEvaluationContext,
        PhilosophyGuidance,
        ProhibitionCheckRequest,
        ProhibitionCheckResult,
        InterventionPoint,
        PipelineContext,
        InterventionResult,
        Ethos,
        MultiLayerContext,
        Tension,
        FeedbackEvent,
        EvolutionProposal,
        StateWeighting,
        StateWeightingImpact;
import 'package:mcp_philosophy/mcp_philosophy.dart'
    show StateAdjuster, PhilosophyException;

import '../system/knowledge_system.dart';
import '../system/knowledge_config.dart';
import '../events/knowledge_event.dart';

/// Thin facade over [PhilosophyPort] / `PhilosophyEngine`.
///
/// All methods first check that the engine (or a bare `PhilosophyPort`)
/// is configured. Throws `StateError` when nothing is wired.
class PhilosophyFacade {
  final KnowledgeSystem _system;

  PhilosophyFacade({required KnowledgeSystem system}) : _system = system;

  /// Access the orchestrator.
  KnowledgeSystem get system => _system;

  /// Whether a philosophy port is wired (engine or bare port).
  bool get isAvailable =>
      _system.philosophyEngine != null || _system.ports.philosophy != null;

  PhilosophyPort get _port {
    final engine = _system.philosophyEngine;
    if (engine != null) return engine;
    final port = _system.ports.philosophy;
    if (port != null) return port;
    throw StateError(
      'PhilosophyPort not configured — pass `philosophyEngine: ...` or '
      '`ports: KnowledgePorts(philosophy: ...)` to KnowledgeSystem.',
    );
  }

  PhilosophyConfig get _config => _system.config.philosophy;

  // ── Core operations ──────────────────────────────────────────────────────

  /// Evaluate context against the active Ethos.
  Future<PhilosophyGuidance> evaluate(
    PhilosophyEvaluationContext context,
  ) async {
    try {
      final guidance = await _port.evaluate(context);
      _system.eventBus.emit(PhilosophyEvaluatedEvent(
        contextId: context.contextId,
        confidence: guidance.confidence,
        prohibitionViolated: guidance.prohibitionViolated,
        recommendedAction: guidance.recommendedAction,
        timestamp: DateTime.now(),
      ));
      return guidance;
    } on PhilosophyException catch (e) {
      throw PhilosophyFacadeException(
        'evaluate failed: ${e.message}',
        cause: e,
      );
    }
  }

  /// Check prohibitions against a proposed action or output.
  Future<ProhibitionCheckResult> checkProhibitions(
    ProhibitionCheckRequest request,
  ) async {
    try {
      final result = await _port.checkProhibitions(request);
      for (final check in result.checks) {
        if (check.violated) {
          _system.eventBus.emit(ProhibitionViolatedEvent(
            prohibitionId: check.prohibitionId,
            severity: check.severity.name,
            detail: check.violationDetail ?? 'Prohibition violated',
            isHard: result.hasHardViolation,
            timestamp: DateTime.now(),
          ));
        }
      }
      return result;
    } on PhilosophyException catch (e) {
      throw PhilosophyFacadeException(
        'checkProhibitions failed: ${e.message}',
        cause: e,
      );
    }
  }

  /// Apply philosophy intervention at a pipeline stage.
  ///
  /// Honors the per-intervention-point enable flags in
  /// `config.philosophy`. Returns `InterventionResult.noOp()` when the
  /// intervention point is disabled.
  Future<InterventionResult> intervene(
    InterventionPoint point,
    PipelineContext context,
  ) async {
    if (!_config.enabled) {
      return InterventionResult.noOp();
    }

    final allowed = switch (point) {
      InterventionPoint.preGeneration => _config.enablePreGeneration,
      InterventionPoint.duringGeneration => _config.enableDuringGeneration,
      InterventionPoint.postGeneration => _config.enablePostGeneration,
      InterventionPoint.unknown => false,
    };
    if (!allowed) {
      return InterventionResult.noOp();
    }

    try {
      return await _port.intervene(point, context);
    } on PhilosophyException catch (e) {
      throw PhilosophyFacadeException(
        'intervene failed at ${point.name}: ${e.message}',
        cause: e,
      );
    }
  }

  /// Retrieve the currently active Ethos.
  Future<Ethos> getEthos() async {
    try {
      return await _port.getEthos();
    } on PhilosophyException catch (e) {
      throw PhilosophyFacadeException(
        'getEthos failed: ${e.message}',
        cause: e,
      );
    }
  }

  /// Detect tensions between Philosophy and other layers.
  Future<List<Tension>> detectTensions(MultiLayerContext context) async {
    if (!_config.enableTensionDetection) {
      return const [];
    }
    try {
      final tensions = await _port.detectTensions(context);
      for (final tension in tensions) {
        _system.eventBus.emit(TensionDetectedEvent(
          tensionId: tension.id,
          severity: tension.severity.name,
          philosophyDirective: tension.philosophyDirective,
          opposingDirective: tension.opposingDirective,
          layer: tension.source.opposingLayer.name,
          timestamp: DateTime.now(),
        ));
      }
      return tensions;
    } on PhilosophyException catch (e) {
      throw PhilosophyFacadeException(
        'detectTensions failed: ${e.message}',
        cause: e,
      );
    }
  }

  /// Generate an evolution proposal from action feedback.
  Future<EvolutionProposal?> proposeFeedback(FeedbackEvent event) async {
    if (!_config.enableEvolution) {
      return null;
    }
    try {
      final proposal = await _port.proposeFeedback(event);
      if (proposal != null) {
        _system.eventBus.emit(EvolutionProposedEvent(
          proposalId: proposal.id,
          ethosId: proposal.ethosId,
          evolutionType: proposal.type.name,
          confidence: proposal.confidence,
          description: proposal.rationale,
          timestamp: DateTime.now(),
        ));
      }
      return proposal;
    } on PhilosophyException catch (e) {
      throw PhilosophyFacadeException(
        'proposeFeedback failed: ${e.message}',
        cause: e,
      );
    }
  }

  /// Evaluate context and adjust guidance by state weighting.
  Future<(PhilosophyGuidance, StateWeightingImpact)> evaluateAndAdjust(
    PhilosophyEvaluationContext context,
    StateWeighting stateWeighting,
  ) async {
    final guidance = await evaluate(context);
    const adjuster = StateAdjuster();
    final result = adjuster.adjustGuidance(guidance, stateWeighting);
    return result;
  }
}

/// Exception for philosophy facade operations.
class PhilosophyFacadeException implements Exception {
  const PhilosophyFacadeException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'PhilosophyFacadeException: $message';
}
