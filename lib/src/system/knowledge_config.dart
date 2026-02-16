/// Knowledge Config - System-wide configuration.
///
/// Provides hierarchical configuration for all subsystems.
library;

/// System-wide configuration.
class KnowledgeConfig {
  /// Workspace identifier.
  final String workspaceId;

  /// FactGraph configuration.
  final FactGraphConfig factGraph;

  /// Skill configuration.
  final SkillConfig skill;

  /// Profile configuration.
  final ProfileConfig profile;

  /// Pipeline configuration.
  final PipelineConfig pipeline;

  /// Scheduler configuration.
  final SchedulerConfig scheduler;

  /// Event configuration.
  final EventConfig events;

  /// Logging configuration.
  final LoggingConfig logging;

  /// Feature flags.
  final FeatureFlags features;

  const KnowledgeConfig({
    this.workspaceId = 'default',
    this.factGraph = const FactGraphConfig(),
    this.skill = const SkillConfig(),
    this.profile = const ProfileConfig(),
    this.pipeline = const PipelineConfig(),
    this.scheduler = const SchedulerConfig(),
    this.events = const EventConfig(),
    this.logging = const LoggingConfig(),
    this.features = const FeatureFlags(),
  });

  /// Default configuration.
  static const KnowledgeConfig defaults = KnowledgeConfig();

  /// Development configuration.
  static const KnowledgeConfig development = KnowledgeConfig(
    logging: LoggingConfig(level: LogLevel.debug),
    features: FeatureFlags(enableExperimentalPatternMining: true),
  );

  /// Production configuration.
  static const KnowledgeConfig production = KnowledgeConfig(
    events: EventConfig(persistEvents: true),
    pipeline: PipelineConfig(checkpointEnabled: true),
    logging: LoggingConfig(level: LogLevel.warning),
  );

  /// Create copy with modifications.
  KnowledgeConfig copyWith({
    String? workspaceId,
    FactGraphConfig? factGraph,
    SkillConfig? skill,
    ProfileConfig? profile,
    PipelineConfig? pipeline,
    SchedulerConfig? scheduler,
    EventConfig? events,
    LoggingConfig? logging,
    FeatureFlags? features,
  }) {
    return KnowledgeConfig(
      workspaceId: workspaceId ?? this.workspaceId,
      factGraph: factGraph ?? this.factGraph,
      skill: skill ?? this.skill,
      profile: profile ?? this.profile,
      pipeline: pipeline ?? this.pipeline,
      scheduler: scheduler ?? this.scheduler,
      events: events ?? this.events,
      logging: logging ?? this.logging,
      features: features ?? this.features,
    );
  }
}

/// FactGraph configuration.
class FactGraphConfig {
  /// Auto-confirm threshold for candidates.
  final double candidateAutoConfirmThreshold;

  /// Summary refresh interval.
  final Duration summaryRefreshInterval;

  /// Maximum evidence size in bytes.
  final int maxEvidenceSize;

  /// Enable consistency checking.
  final bool enableConsistencyCheck;

  const FactGraphConfig({
    this.candidateAutoConfirmThreshold = 0.95,
    this.summaryRefreshInterval = const Duration(hours: 24),
    this.maxEvidenceSize = 1024 * 1024,
    this.enableConsistencyCheck = true,
  });
}

/// Skill configuration.
class SkillConfig {
  /// Default timeout for skill execution.
  final Duration defaultTimeout;

  /// Maximum concurrent executions.
  final int maxConcurrentExecutions;

  /// Record claims by default.
  final bool recordClaimsByDefault;

  const SkillConfig({
    this.defaultTimeout = const Duration(minutes: 5),
    this.maxConcurrentExecutions = 10,
    this.recordClaimsByDefault = true,
  });
}

/// Profile configuration.
class ProfileConfig {
  /// Enable appraisal by default.
  final bool enableAppraisalByDefault;

  /// Appraisal threshold.
  final double appraisalThreshold;

  /// Maximum content length.
  final int maxContentLength;

  const ProfileConfig({
    this.enableAppraisalByDefault = true,
    this.appraisalThreshold = 70.0,
    this.maxContentLength = 100000,
  });
}

/// Pipeline configuration.
class PipelineConfig {
  /// Enable checkpointing.
  final bool checkpointEnabled;

  /// Checkpoint interval.
  final Duration checkpointInterval;

  /// Maximum retries.
  final int maxRetries;

  const PipelineConfig({
    this.checkpointEnabled = false,
    this.checkpointInterval = const Duration(minutes: 5),
    this.maxRetries = 3,
  });
}

/// Scheduler configuration.
class SchedulerConfig {
  /// Whether scheduler is enabled.
  final bool enabled;

  /// Timezone for scheduling.
  final String timezone;

  /// Maximum concurrent jobs.
  final int maxConcurrentJobs;

  const SchedulerConfig({
    this.enabled = true,
    this.timezone = 'UTC',
    this.maxConcurrentJobs = 5,
  });
}

/// Event configuration.
class EventConfig {
  /// Event buffer size.
  final int bufferSize;

  /// Whether to persist events.
  final bool persistEvents;

  const EventConfig({
    this.bufferSize = 1000,
    this.persistEvents = false,
  });
}

/// Logging configuration.
class LoggingConfig {
  /// Log level.
  final LogLevel level;

  /// Include stack traces.
  final bool includeStackTrace;

  /// Enable audit logging.
  final bool enableAuditLog;

  const LoggingConfig({
    this.level = LogLevel.info,
    this.includeStackTrace = false,
    this.enableAuditLog = false,
  });
}

/// Log levels.
enum LogLevel {
  debug,
  info,
  warning,
  error;
}

/// Feature flags.
class FeatureFlags {
  /// Enable experimental pattern mining.
  final bool enableExperimentalPatternMining;

  /// Enable auto summarization.
  final bool enableAutoSummarization;

  /// Enable auto confirm.
  final bool enableAutoConfirm;

  /// Enable hot reload.
  final bool enableHotReload;

  const FeatureFlags({
    this.enableExperimentalPatternMining = false,
    this.enableAutoSummarization = true,
    this.enableAutoConfirm = false,
    this.enableHotReload = false,
  });
}
