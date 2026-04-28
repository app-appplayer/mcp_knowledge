import 'package:test/test.dart';
import 'package:mcp_knowledge/mcp_knowledge.dart';

void main() {
  group('KnowledgeEvent', () {
    group('FactConfirmedEvent', () {
      test('creates fact confirmed event', () {
        final event = FactConfirmedEvent(
          factId: 'fact-1',
          entityId: 'entity-1',
          factType: 'personal',
          timestamp: DateTime(2024, 1, 1),
        );

        expect(event.factId, equals('fact-1'));
        expect(event.entityId, equals('entity-1'));
        expect(event.factType, equals('personal'));
        expect(event.type, equals('fact_confirmed'));
      });
    });

    group('CandidateCreatedEvent', () {
      test('creates candidate created event', () {
        final event = CandidateCreatedEvent(
          candidateId: 'candidate-1',
          confidence: 0.85,
          timestamp: DateTime(2024, 1, 1),
        );

        expect(event.candidateId, equals('candidate-1'));
        expect(event.confidence, equals(0.85));
        expect(event.type, equals('candidate_created'));
      });
    });

    group('SummaryRefreshedEvent', () {
      test('creates summary refreshed event', () {
        final event = SummaryRefreshedEvent(
          summaryId: 'summary-1',
          entityId: 'entity-1',
          timestamp: DateTime(2024, 1, 1),
        );

        expect(event.summaryId, equals('summary-1'));
        expect(event.entityId, equals('entity-1'));
        expect(event.type, equals('summary_refreshed'));
      });
    });

    group('SkillExecutedEvent', () {
      test('creates skill executed event', () {
        final event = SkillExecutedEvent(
          skillId: 'skill-1',
          executionId: 'exec-1',
          success: true,
          duration: const Duration(seconds: 5),
          timestamp: DateTime(2024, 1, 1),
        );

        expect(event.skillId, equals('skill-1'));
        expect(event.executionId, equals('exec-1'));
        expect(event.success, isTrue);
        expect(event.duration.inSeconds, equals(5));
        expect(event.type, equals('skill_executed'));
      });
    });

    group('ClaimsRecordedEvent', () {
      test('creates claims recorded event', () {
        final event = ClaimsRecordedEvent(
          skillId: 'skill-1',
          claimIds: ['claim-1', 'claim-2'],
          entityId: 'entity-1',
          timestamp: DateTime(2024, 1, 1),
        );

        expect(event.skillId, equals('skill-1'));
        expect(event.claimIds, containsAll(['claim-1', 'claim-2']));
        expect(event.entityId, equals('entity-1'));
        expect(event.type, equals('claims_recorded'));
      });
    });

    group('ProfileAppliedEvent', () {
      test('creates profile applied event', () {
        final event = ProfileAppliedEvent(
          profileId: 'profile-1',
          entityId: 'entity-1',
          duration: const Duration(milliseconds: 150),
          timestamp: DateTime(2024, 1, 1),
        );

        expect(event.profileId, equals('profile-1'));
        expect(event.entityId, equals('entity-1'));
        expect(event.duration.inMilliseconds, equals(150));
        expect(event.type, equals('profile_applied'));
      });
    });

    group('BundleLoadedEvent', () {
      test('creates bundle loaded event', () {
        final event = BundleLoadedEvent(
          bundleId: 'bundle-1',
          skillCount: 5,
          profileCount: 3,
          timestamp: DateTime(2024, 1, 1),
        );

        expect(event.bundleId, equals('bundle-1'));
        expect(event.skillCount, equals(5));
        expect(event.profileCount, equals(3));
        expect(event.type, equals('bundle_loaded'));
      });
    });

    group('PipelineCompletedEvent', () {
      test('creates pipeline completed event', () {
        final event = PipelineCompletedEvent(
          pipelineId: 'pipeline-1',
          success: true,
          metrics: {'processed': 100, 'errors': 0},
          timestamp: DateTime(2024, 1, 1),
        );

        expect(event.pipelineId, equals('pipeline-1'));
        expect(event.success, isTrue);
        expect(event.metrics['processed'], equals(100));
        expect(event.type, equals('pipeline_completed'));
      });
    });

    group('SystemShutdownEvent', () {
      test('creates system shutdown event', () {
        final event = SystemShutdownEvent(
          timestamp: DateTime(2024, 1, 1),
        );

        expect(event.type, equals('system_shutdown'));
      });
    });
  });
}
