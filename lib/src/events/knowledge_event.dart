/// Knowledge Event - Event definitions for the knowledge system.
library;

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

  const SkillExecutedEvent({
    required this.skillId,
    required this.executionId,
    required this.success,
    required this.duration,
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

  const ClaimsRecordedEvent({
    required this.skillId,
    required this.claimIds,
    required this.timestamp,
  });
}

/// Profile rendered event.
class ProfileRenderedEvent implements KnowledgeEvent {
  @override
  final DateTime timestamp;

  @override
  String get type => 'profile_rendered';

  /// Profile ID.
  final String profileId;

  /// Entity ID.
  final String entityId;

  /// Render duration.
  final Duration duration;

  const ProfileRenderedEvent({
    required this.profileId,
    required this.entityId,
    required this.duration,
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
