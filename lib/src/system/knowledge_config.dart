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

  /// Philosophy configuration.
  final PhilosophyConfig philosophy;

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
    this.philosophy = const PhilosophyConfig(),
  });

  /// Default configuration.
  static const KnowledgeConfig defaults = KnowledgeConfig();

  /// Development configuration.
  static const KnowledgeConfig development = KnowledgeConfig(
    logging: LoggingConfig(level: LogLevel.debug),
    features: FeatureFlags(enableExperimentalPatternMining: true),
    philosophy: PhilosophyConfig(
      enableEvolution: true,
      minConfidenceThreshold: 0.3,
    ),
  );

  /// Production configuration.
  static const KnowledgeConfig production = KnowledgeConfig(
    events: EventConfig(persistEvents: true),
    pipeline: PipelineConfig(checkpointEnabled: true),
    logging: LoggingConfig(level: LogLevel.warning, enableAuditLog: true),
    philosophy: PhilosophyConfig(
      enableDuringGeneration: false,
      minConfidenceThreshold: 0.7,
    ),
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
    PhilosophyConfig? philosophy,
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
      philosophy: philosophy ?? this.philosophy,
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

  /// Default execution budget (null uses skill defaults).
  final ExecutionBudgetConfig? defaultBudget;

  const SkillConfig({
    this.defaultTimeout = const Duration(minutes: 5),
    this.maxConcurrentExecutions = 10,
    this.recordClaimsByDefault = true,
    this.defaultBudget,
  });

  /// Create a copy with modifications.
  SkillConfig copyWith({
    Duration? defaultTimeout,
    int? maxConcurrentExecutions,
    bool? recordClaimsByDefault,
    ExecutionBudgetConfig? defaultBudget,
  }) {
    return SkillConfig(
      defaultTimeout: defaultTimeout ?? this.defaultTimeout,
      maxConcurrentExecutions:
          maxConcurrentExecutions ?? this.maxConcurrentExecutions,
      recordClaimsByDefault:
          recordClaimsByDefault ?? this.recordClaimsByDefault,
      defaultBudget: defaultBudget ?? this.defaultBudget,
    );
  }
}

/// Execution budget configuration (mirrors mcp_skill ExecutionBudget).
class ExecutionBudgetConfig {
  /// Maximum tokens.
  final int maxTokens;

  /// Maximum duration.
  final Duration maxDuration;

  /// Maximum steps.
  final int maxSteps;

  /// Maximum LLM calls.
  final int maxLlmCalls;

  /// Maximum MCP calls.
  final int maxMcpCalls;

  /// Maximum concurrency.
  final int maxConcurrency;

  const ExecutionBudgetConfig({
    this.maxTokens = 100000,
    this.maxDuration = const Duration(minutes: 5),
    this.maxSteps = 50,
    this.maxLlmCalls = 20,
    this.maxMcpCalls = 100,
    this.maxConcurrency = 5,
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

  /// Conflict resolution strategy for multi-profile scenarios.
  final String conflictResolution;

  const ProfileConfig({
    this.enableAppraisalByDefault = true,
    this.appraisalThreshold = 70.0,
    this.maxContentLength = 100000,
    this.conflictResolution = 'merge',
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

  /// Maximum concurrent pipeline stages.
  final int maxConcurrency;

  const PipelineConfig({
    this.checkpointEnabled = false,
    this.checkpointInterval = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.maxConcurrency = 4,
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

/// Philosophy configuration.
class PhilosophyConfig {
  /// Whether philosophy evaluation is enabled.
  final bool enabled;

  /// Enable pre-generation intervention.
  final bool enablePreGeneration;

  /// Enable during-generation intervention.
  final bool enableDuringGeneration;

  /// Enable post-generation intervention.
  final bool enablePostGeneration;

  /// Enable tension detection.
  final bool enableTensionDetection;

  /// Enable evolution proposals.
  final bool enableEvolution;

  /// Minimum confidence threshold for philosophy guidance to be applied.
  final double minConfidenceThreshold;

  /// Conflict resolution strategy.
  final String conflictStrategy;

  const PhilosophyConfig({
    this.enabled = true,
    this.enablePreGeneration = true,
    this.enableDuringGeneration = true,
    this.enablePostGeneration = true,
    this.enableTensionDetection = true,
    this.enableEvolution = false,
    this.minConfidenceThreshold = 0.5,
    this.conflictStrategy = 'priority',
  });
}
