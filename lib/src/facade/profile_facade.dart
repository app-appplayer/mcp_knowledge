/// Profile Facade — thin wrapper around `ProfileRuntime` (mcp_profile).
///
/// REDESIGN-PLAN Phase 8 §3.5 / §4 step 6: this facade no longer fakes
/// profile application by formatting templates inline. It delegates to
/// a real `ProfileRuntime` so the 3-pillar pipeline (Appraisal → Decision
/// → Expression) actually runs.
library;

import 'package:mcp_profile/mcp_profile.dart' as profile;

import '../system/knowledge_system.dart';
import '../events/knowledge_event.dart';

// Re-export ProfileRuntime + context types so consumers can build
// RuntimeProfileContext without importing mcp_profile directly.
export 'package:mcp_profile/mcp_profile.dart'
    show
        Profile,
        ProfileRegistry,
        ProfileRuntime,
        ProfileApplicationResult,
        ProfileApplicationMetadata,
        RuntimeProfileContext,
        DefaultRuntimeContext,
        RuntimeContextBuilder,
        ProfileNotFoundException,
        EnginePorts;

/// Thin facade over [profile.ProfileRuntime].
class ProfileFacade {
  final KnowledgeSystem _system;

  ProfileFacade({required KnowledgeSystem system}) : _system = system;

  /// Access the orchestrator.
  KnowledgeSystem get system => _system;

  /// Whether a profile runtime is wired.
  bool get isAvailable => _system.profileRuntime != null;

  profile.ProfileRuntime get _runtime {
    final rt = _system.profileRuntime;
    if (rt == null) {
      throw StateError(
        'ProfileRuntime not configured — pass `profileRuntime: ...` to '
        'KnowledgeSystem to enable profile evaluation.',
      );
    }
    return rt;
  }

  // ── Apply ────────────────────────────────────────────────────────────────

  /// Run the full appraisal → decision → expression pipeline.
  ///
  /// Builds a [profile.RuntimeProfileContext] from the supplied
  /// parameters and dispatches to `ProfileRuntime.apply()`. Optional
  /// `rawContent` triggers the Expression formatting step.
  Future<profile.ProfileApplicationResult> apply(
    String profileId, {
    required String entityId,
    Map<String, dynamic>? inputs,
    Map<String, dynamic>? metadata,
    String? rawContent,
  }) async {
    final ports = _system.ports;
    final context = profile.DefaultRuntimeContext(
      profileId: profileId,
      entityId: entityId,
      inputs: inputs ?? const {},
      metadata: metadata ?? const {},
      facts: ports.facts,
      patterns: ports.patterns,
      summaries: ports.summaries,
      llm: ports.llm,
    );

    final result = await _runtime.apply(context, rawContent: rawContent);

    _system.eventBus.emit(ProfileAppliedEvent(
      profileId: profileId,
      entityId: entityId,
      duration: result.metadata.duration,
      decision: result.decision.action,
      timestamp: DateTime.now(),
    ));

    return result;
  }

  /// Apply a profile and return only the appraisal portion.
  Future<profile.ProfileApplicationResult> appraise(
    String profileId, {
    required String entityId,
  }) async {
    return apply(profileId, entityId: entityId);
  }

  // ── Registry passthrough (mcp_profile.ProfileRegistry) ───────────────────

  /// Register a profile against the underlying [profile.ProfileRegistry].
  void register(profile.Profile p) {
    _runtime.registry.register(p);
  }

  /// Unregister a profile.
  bool unregister(String profileId) {
    return _runtime.registry.unregister(profileId);
  }

  /// Get a profile from the registry.
  profile.Profile? get(String profileId) {
    return _runtime.registry.get(profileId);
  }

  /// List all registered profiles.
  ///
  /// Returns an empty list when no `ProfileRuntime` is wired — listing
  /// is a read-only enumeration that integrates poorly with a hard
  /// `StateError`. Callers driving multi-pool UI pickers (e.g. agent
  /// fork starters) can call `list()` unconditionally and treat the
  /// empty result as "no pool starters" without first probing
  /// [isAvailable]. Mutating operations (`register`, `unregister`,
  /// `get`, `apply`) still raise `StateError` when the runtime is not
  /// wired since the partial state would silently lose data.
  List<profile.Profile> list() {
    final rt = _system.profileRuntime;
    if (rt == null) return const [];
    return rt.registry.all;
  }

}

/// Profile exception raised by the facade.
class ProfileException implements Exception {
  final String message;
  ProfileException(this.message);

  @override
  String toString() => 'ProfileException: $message';
}
