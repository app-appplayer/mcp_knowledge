/// Knowledge Event - Event definitions for the knowledge system.
library;

import 'package:mcp_bundle/mcp_bundle.dart' show DecisionAction;

// Re-export DecisionAction for event consumers
export 'package:mcp_bundle/mcp_bundle.dart' show DecisionAction;

/// Base class for all knowledge events.
abstract class KnowledgeEvent {
  /// Event timestamp.
  DateTime get timestamp;

  /// Event type identifier.
  String get type;
}

/// Fact confirmed event.
class FactConfirmedEvent implements KnowledgeEvent {
  @override
  final DateTime timestamp;

  @override
  String get type => 'fact_confirmed';

  /// Fact ID.
  final String factId;

  /// Entity ID.
  final String entityId;

  /// Fact type.
  final String factType;

  const FactConfirmedEvent({
    required this.factId,
    required this.entityId,
    required this.factType,
    required this.timestamp,
  });
}

/// Candidate created event.
class CandidateCreatedEvent implements KnowledgeEvent {
  @override
  final DateTime timestamp;

  @override
  String get type => 'candidate_created';

  /// Candidate ID.
  final String candidateId;

  /// Confidence score.
  final double confidence;

  const CandidateCreatedEvent({
    required this.candidateId,
    required this.confidence,
    required this.timestamp,
  });
}

/// Summary refreshed event.
class SummaryRefreshedEvent implements KnowledgeEvent {
  @override
  final DateTime timestamp;

  @override
  String get type => 'summary_refreshed';

  /// Summary ID.
  final String summaryId;

  /// Entity ID.
  final String entityId;

  const SummaryRefreshedEvent({
    required this.summaryId,
    required this.entityId,
    required this.timestamp,
  });
}

/// Skill executed event.
class SkillExecutedEvent implements KnowledgeEvent {
  @override
  final DateTime timestamp;

  @override
  String get type => 'skill_executed';

  /// Skill ID.
  final String skillId;

  /// Execution ID.
  final String executionId;

  /// Whether execution succeeded.
  final bool success;

  /// Execution duration.
  final Duration duration;

  /// Number of claims extracted.
  final int claimCount;

  const SkillExecutedEvent({
    required this.skillId,
    required this.executionId,
    required this.success,
    required this.duration,
    this.claimCount = 0,
    required this.timestamp,
  });
}

/// Claims recorded event.
class ClaimsRecordedEvent implements KnowledgeEvent {
  @override
  final DateTime timestamp;

  @override
  String get type => 'claims_recorded';

  /// Skill ID.
  final String skillId;

  /// Claim IDs.
  final List<String> claimIds;

  /// Entity ID.
  final String entityId;

  const ClaimsRecordedEvent({
    required this.skillId,
    required this.claimIds,
    required this.entityId,
    required this.timestamp,
  });
}

/// Profile applied event (runs the 3-pillar pipeline).
class ProfileAppliedEvent implements KnowledgeEvent {
  @override
  final DateTime timestamp;

  @override
  String get type => 'profile_applied';

  /// Profile ID.
  final String profileId;

  /// Entity ID.
  final String entityId;

  /// Application duration.
  final Duration duration;

  /// Decision action from the decision pillar.
  final DecisionAction? decision;

  const ProfileAppliedEvent({
    required this.profileId,
    required this.entityId,
    required this.duration,
    this.decision,
    required this.timestamp,
  });
}

/// Bundle loaded event.
class BundleLoadedEvent implements KnowledgeEvent {
  @override
  final DateTime timestamp;

  @override
  String get type => 'bundle_loaded';

  /// Bundle ID.
  final String bundleId;

  /// Skills loaded count.
  final int skillCount;

  /// Profiles loaded count.
  final int profileCount;

  const BundleLoadedEvent({
    required this.bundleId,
    required this.skillCount,
    required this.profileCount,
    required this.timestamp,
  });
}

/// Pipeline completed event.
class PipelineCompletedEvent implements KnowledgeEvent {
  @override
  final DateTime timestamp;

  @override
  String get type => 'pipeline_completed';

  /// Pipeline ID.
  final String pipelineId;

  /// Whether pipeline succeeded.
  final bool success;

  /// Execution metrics.
  final Map<String, dynamic> metrics;

  const PipelineCompletedEvent({
    required this.pipelineId,
    required this.success,
    required this.metrics,
    required this.timestamp,
  });
}

/// System shutdown event.
class SystemShutdownEvent implements KnowledgeEvent {
  @override
  final DateTime timestamp;

  @override
  String get type => 'system_shutdown';

  const SystemShutdownEvent({required this.timestamp});
}

/// Philosophy evaluated event.
class PhilosophyEvaluatedEvent implements KnowledgeEvent {
  @override
  final DateTime timestamp;

  @override
  String get type => 'philosophy_evaluated';

  /// Context identifier.
  final String contextId;

  /// Evaluation confidence score.
  final double confidence;

  /// Whether a prohibition was violated.
  final bool prohibitionViolated;

  /// Recommended action from evaluation.
  final String recommendedAction;

  const PhilosophyEvaluatedEvent({
    required this.contextId,
    required this.confidence,
    required this.prohibitionViolated,
    required this.recommendedAction,
    required this.timestamp,
  });
}

/// Tension detected event.
class TensionDetectedEvent implements KnowledgeEvent {
  @override
  final DateTime timestamp;

  @override
  String get type => 'tension_detected';

  /// Tension identifier.
  final String tensionId;

  /// Severity level.
  final String severity;

  /// Philosophy directive causing tension.
  final String philosophyDirective;

  /// Opposing directive from another layer.
  final String opposingDirective;

  /// Layer where the tension was detected.
  final String layer;

  const TensionDetectedEvent({
    required this.tensionId,
    required this.severity,
    required this.philosophyDirective,
    required this.opposingDirective,
    required this.layer,
    required this.timestamp,
  });
}

/// Prohibition violated event.
class ProhibitionViolatedEvent implements KnowledgeEvent {
  @override
  final DateTime timestamp;

  @override
  String get type => 'prohibition_violated';

  /// Prohibition identifier.
  final String prohibitionId;

  /// Violation severity.
  final String severity;

  /// Violation detail.
  final String detail;

  /// Whether this is a hard (blocking) prohibition.
  final bool isHard;

  const ProhibitionViolatedEvent({
    required this.prohibitionId,
    required this.severity,
    required this.detail,
    required this.isHard,
    required this.timestamp,
  });
}

/// Evolution proposed event.
class EvolutionProposedEvent implements KnowledgeEvent {
  @override
  final DateTime timestamp;

  @override
  String get type => 'evolution_proposed';

  /// Proposal identifier.
  final String proposalId;

  /// Ethos identifier.
  final String ethosId;

  /// Type of evolution proposed.
  final String evolutionType;

  /// Confidence in the proposal.
  final double confidence;

  /// Human-readable description.
  final String description;

  const EvolutionProposedEvent({
    required this.proposalId,
    required this.ethosId,
    required this.evolutionType,
    required this.confidence,
    required this.description,
    required this.timestamp,
  });
}
