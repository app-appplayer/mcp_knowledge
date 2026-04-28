import 'package:test/test.dart';
import 'package:mcp_knowledge/mcp_knowledge.dart';

void main() {
  group('KnowledgeConfig', () {
    test('creates config with default values', () {
      const config = KnowledgeConfig();

      expect(config.workspaceId, equals('default'));
      expect(config.factGraph, isA<FactGraphConfig>());
      expect(config.skill, isA<SkillConfig>());
      expect(config.profile, isA<ProfileConfig>());
      expect(config.pipeline, isA<PipelineConfig>());
      expect(config.scheduler, isA<SchedulerConfig>());
      expect(config.events, isA<EventConfig>());
      expect(config.logging, isA<LoggingConfig>());
      expect(config.features, isA<FeatureFlags>());
    });

    test('provides default configuration', () {
      const config = KnowledgeConfig.defaults;

      expect(config.workspaceId, equals('default'));
    });

    test('provides development configuration', () {
      const config = KnowledgeConfig.development;

      expect(config.logging.level, equals(LogLevel.debug));
      expect(config.features.enableExperimentalPatternMining, isTrue);
    });

    test('provides production configuration', () {
      const config = KnowledgeConfig.production;

      expect(config.events.persistEvents, isTrue);
      expect(config.pipeline.checkpointEnabled, isTrue);
      expect(config.logging.level, equals(LogLevel.warning));
    });

    test('copyWith creates modified copy', () {
      const original = KnowledgeConfig();

      final modified = original.copyWith(
        workspaceId: 'custom',
        logging: const LoggingConfig(level: LogLevel.error),
      );

      expect(original.workspaceId, equals('default'));
      expect(modified.workspaceId, equals('custom'));
      expect(modified.logging.level, equals(LogLevel.error));
    });

    test('copyWith with all fields', () {
      const original = KnowledgeConfig();

      final modified = original.copyWith(
        workspaceId: 'ws-2',
        factGraph: const FactGraphConfig(candidateAutoConfirmThreshold: 0.5),
        skill: const SkillConfig(maxConcurrentExecutions: 20),
        profile: const ProfileConfig(appraisalThreshold: 80.0),
        pipeline: const PipelineConfig(maxRetries: 5),
        scheduler: const SchedulerConfig(timezone: 'US/Pacific'),
        events: const EventConfig(bufferSize: 2000),
        logging: const LoggingConfig(level: LogLevel.debug),
        features: const FeatureFlags(enableHotReload: true),
      );

      expect(modified.workspaceId, equals('ws-2'));
      expect(modified.factGraph.candidateAutoConfirmThreshold, equals(0.5));
      expect(modified.skill.maxConcurrentExecutions, equals(20));
      expect(modified.profile.appraisalThreshold, equals(80.0));
      expect(modified.pipeline.maxRetries, equals(5));
      expect(modified.scheduler.timezone, equals('US/Pacific'));
      expect(modified.events.bufferSize, equals(2000));
      expect(modified.logging.level, equals(LogLevel.debug));
      expect(modified.features.enableHotReload, isTrue);
    });
  });

  group('FactGraphConfig', () {
    test('creates with default values', () {
      const config = FactGraphConfig();

      expect(config.candidateAutoConfirmThreshold, equals(0.95));
      expect(config.summaryRefreshInterval.inHours, equals(24));
      expect(config.maxEvidenceSize, equals(1024 * 1024));
      expect(config.enableConsistencyCheck, isTrue);
    });

    test('creates with custom values', () {
      const config = FactGraphConfig(
        candidateAutoConfirmThreshold: 0.8,
        summaryRefreshInterval: Duration(hours: 12),
        maxEvidenceSize: 2 * 1024 * 1024,
        enableConsistencyCheck: false,
      );

      expect(config.candidateAutoConfirmThreshold, equals(0.8));
      expect(config.summaryRefreshInterval.inHours, equals(12));
      expect(config.maxEvidenceSize, equals(2 * 1024 * 1024));
      expect(config.enableConsistencyCheck, isFalse);
    });
  });

  group('SkillConfig', () {
    test('creates with default values', () {
      const config = SkillConfig();

      expect(config.defaultTimeout.inMinutes, equals(5));
      expect(config.maxConcurrentExecutions, equals(10));
      expect(config.recordClaimsByDefault, isTrue);
      expect(config.defaultBudget, isNull);
    });

    test('creates with custom values', () {
      const config = SkillConfig(
        defaultTimeout: Duration(minutes: 10),
        maxConcurrentExecutions: 20,
        recordClaimsByDefault: false,
      );

      expect(config.defaultTimeout.inMinutes, equals(10));
      expect(config.maxConcurrentExecutions, equals(20));
      expect(config.recordClaimsByDefault, isFalse);
    });

    test('creates with default budget', () {
      const config = SkillConfig(
        defaultBudget: ExecutionBudgetConfig(
          maxTokens: 50000,
          maxSteps: 25,
        ),
      );

      expect(config.defaultBudget, isNotNull);
      expect(config.defaultBudget!.maxTokens, equals(50000));
      expect(config.defaultBudget!.maxSteps, equals(25));
    });
  });

  group('ExecutionBudgetConfig', () {
    test('creates with default values', () {
      const config = ExecutionBudgetConfig();

      expect(config.maxTokens, equals(100000));
      expect(config.maxDuration.inMinutes, equals(5));
      expect(config.maxSteps, equals(50));
      expect(config.maxLlmCalls, equals(20));
      expect(config.maxMcpCalls, equals(100));
      expect(config.maxConcurrency, equals(5));
    });

    test('creates with custom values', () {
      const config = ExecutionBudgetConfig(
        maxTokens: 50000,
        maxDuration: Duration(minutes: 2),
        maxSteps: 10,
        maxLlmCalls: 5,
        maxMcpCalls: 50,
        maxConcurrency: 3,
      );

      expect(config.maxTokens, equals(50000));
      expect(config.maxDuration.inMinutes, equals(2));
      expect(config.maxSteps, equals(10));
      expect(config.maxLlmCalls, equals(5));
      expect(config.maxMcpCalls, equals(50));
      expect(config.maxConcurrency, equals(3));
    });
  });

  group('ProfileConfig', () {
    test('creates with default values', () {
      const config = ProfileConfig();

      expect(config.enableAppraisalByDefault, isTrue);
      expect(config.appraisalThreshold, equals(70.0));
      expect(config.maxContentLength, equals(100000));
      expect(config.conflictResolution, equals('merge'));
    });

    test('creates with custom values', () {
      const config = ProfileConfig(
        enableAppraisalByDefault: false,
        appraisalThreshold: 80.0,
        maxContentLength: 200000,
        conflictResolution: 'override',
      );

      expect(config.enableAppraisalByDefault, isFalse);
      expect(config.appraisalThreshold, equals(80.0));
      expect(config.maxContentLength, equals(200000));
      expect(config.conflictResolution, equals('override'));
    });
  });

  group('PipelineConfig', () {
    test('creates with default values', () {
      const config = PipelineConfig();

      expect(config.checkpointEnabled, isFalse);
      expect(config.checkpointInterval.inSeconds, equals(30));
      expect(config.maxRetries, equals(3));
      expect(config.maxConcurrency, equals(4));
    });

    test('creates with custom values', () {
      const config = PipelineConfig(
        checkpointEnabled: true,
        checkpointInterval: Duration(minutes: 10),
        maxRetries: 5,
      );

      expect(config.checkpointEnabled, isTrue);
      expect(config.checkpointInterval.inMinutes, equals(10));
      expect(config.maxRetries, equals(5));
    });
  });

  group('SchedulerConfig', () {
    test('creates with default values', () {
      const config = SchedulerConfig();

      expect(config.enabled, isTrue);
      expect(config.timezone, equals('UTC'));
      expect(config.maxConcurrentJobs, equals(5));
    });

    test('creates with custom values', () {
      const config = SchedulerConfig(
        enabled: false,
        timezone: 'America/New_York',
        maxConcurrentJobs: 10,
      );

      expect(config.enabled, isFalse);
      expect(config.timezone, equals('America/New_York'));
      expect(config.maxConcurrentJobs, equals(10));
    });
  });

  group('EventConfig', () {
    test('creates with default values', () {
      const config = EventConfig();

      expect(config.bufferSize, equals(1000));
      expect(config.persistEvents, isFalse);
    });

    test('creates with custom values', () {
      const config = EventConfig(
        bufferSize: 5000,
        persistEvents: true,
      );

      expect(config.bufferSize, equals(5000));
      expect(config.persistEvents, isTrue);
    });
  });

  group('LoggingConfig', () {
    test('creates with default values', () {
      const config = LoggingConfig();

      expect(config.level, equals(LogLevel.info));
      expect(config.includeStackTrace, isFalse);
      expect(config.enableAuditLog, isFalse);
    });

    test('creates with custom values', () {
      const config = LoggingConfig(
        level: LogLevel.debug,
        includeStackTrace: true,
        enableAuditLog: true,
      );

      expect(config.level, equals(LogLevel.debug));
      expect(config.includeStackTrace, isTrue);
      expect(config.enableAuditLog, isTrue);
    });
  });

  group('LogLevel', () {
    test('has correct values', () {
      expect(LogLevel.values, containsAll([
        LogLevel.debug,
        LogLevel.info,
        LogLevel.warning,
        LogLevel.error,
      ]));
    });
  });

  group('FeatureFlags', () {
    test('creates with default values', () {
      const flags = FeatureFlags();

      expect(flags.enableExperimentalPatternMining, isFalse);
      expect(flags.enableAutoSummarization, isTrue);
      expect(flags.enableAutoConfirm, isFalse);
      expect(flags.enableHotReload, isFalse);
    });

    test('creates with custom values', () {
      const flags = FeatureFlags(
        enableExperimentalPatternMining: true,
        enableAutoSummarization: false,
        enableAutoConfirm: true,
        enableHotReload: true,
      );

      expect(flags.enableExperimentalPatternMining, isTrue);
      expect(flags.enableAutoSummarization, isFalse);
      expect(flags.enableAutoConfirm, isTrue);
      expect(flags.enableHotReload, isTrue);
    });
  });
}
