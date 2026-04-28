import 'dart:async';
import 'package:test/test.dart';
import 'package:mcp_knowledge/mcp_knowledge.dart';

void main() {
  group('KnowledgeEventBus', () {
    late KnowledgeEventBus eventBus;

    setUp(() {
      eventBus = KnowledgeEventBus();
    });

    tearDown(() async {
      await eventBus.close();
    });

    test('emits events to stream', () async {
      final events = <KnowledgeEvent>[];
      final subscription = eventBus.stream.listen(events.add);

      final event = FactConfirmedEvent(
        factId: 'fact-1',
        entityId: 'entity-1',
        factType: 'personal',
        timestamp: DateTime.now(),
      );

      eventBus.emit(event);

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(events.length, equals(1));
      expect(events.first, equals(event));

      await subscription.cancel();
    });

    test('filters events by type with on<T>()', () async {
      final factEvents = <FactConfirmedEvent>[];
      final skillEvents = <SkillExecutedEvent>[];

      final factSub = eventBus.on<FactConfirmedEvent>().listen(factEvents.add);
      final skillSub = eventBus.on<SkillExecutedEvent>().listen(skillEvents.add);

      eventBus.emit(FactConfirmedEvent(
        factId: 'f1',
        entityId: 'e1',
        factType: 'test',
        timestamp: DateTime.now(),
      ));

      eventBus.emit(SkillExecutedEvent(
        skillId: 's1',
        executionId: 'ex1',
        success: true,
        duration: const Duration(seconds: 1),
        timestamp: DateTime.now(),
      ));

      eventBus.emit(FactConfirmedEvent(
        factId: 'f2',
        entityId: 'e2',
        factType: 'test',
        timestamp: DateTime.now(),
      ));

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(factEvents.length, equals(2));
      expect(skillEvents.length, equals(1));

      await factSub.cancel();
      await skillSub.cancel();
    });

    test('subscribe provides typed handler', () async {
      final receivedEvents = <CandidateCreatedEvent>[];

      final subscription = eventBus.subscribe<CandidateCreatedEvent>(
        (event) => receivedEvents.add(event),
      );

      eventBus.emit(CandidateCreatedEvent(
        candidateId: 'c1',
        confidence: 0.9,
        timestamp: DateTime.now(),
      ));

      eventBus.emit(SystemShutdownEvent(timestamp: DateTime.now()));

      eventBus.emit(CandidateCreatedEvent(
        candidateId: 'c2',
        confidence: 0.8,
        timestamp: DateTime.now(),
      ));

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(receivedEvents.length, equals(2));
      expect(receivedEvents[0].candidateId, equals('c1'));
      expect(receivedEvents[1].candidateId, equals('c2'));

      await subscription.cancel();
    });

    test('does not emit after close', () async {
      final events = <KnowledgeEvent>[];
      eventBus.stream.listen(events.add);

      await eventBus.close();

      eventBus.emit(SystemShutdownEvent(timestamp: DateTime.now()));

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(events, isEmpty);
    });

    test('multiple subscribers receive same events', () async {
      final subscriber1 = <KnowledgeEvent>[];
      final subscriber2 = <KnowledgeEvent>[];

      final sub1 = eventBus.stream.listen(subscriber1.add);
      final sub2 = eventBus.stream.listen(subscriber2.add);

      eventBus.emit(BundleLoadedEvent(
        bundleId: 'b1',
        skillCount: 5,
        profileCount: 3,
        timestamp: DateTime.now(),
      ));

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(subscriber1.length, equals(1));
      expect(subscriber2.length, equals(1));

      await sub1.cancel();
      await sub2.cancel();
    });

    test('subscriber exception is isolated from other subscribers', () async {
      final receivedB = <CandidateCreatedEvent>[];

      // Subscriber A always throws.
      final subA = eventBus.subscribe<CandidateCreatedEvent>((_) {
        throw StateError('subscriber A boom');
      });

      // Subscriber B records events normally.
      final subB = eventBus.subscribe<CandidateCreatedEvent>(
        (event) => receivedB.add(event),
      );

      eventBus.emit(CandidateCreatedEvent(
        candidateId: 'c1',
        confidence: 0.7,
        timestamp: DateTime.now(),
      ));
      eventBus.emit(CandidateCreatedEvent(
        candidateId: 'c2',
        confidence: 0.8,
        timestamp: DateTime.now(),
      ));

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(receivedB.length, equals(2));
      expect(receivedB.map((e) => e.candidateId), equals(['c1', 'c2']));

      await subA.cancel();
      await subB.cancel();
    });

    test('subscriber exception does not propagate to emit caller', () async {
      eventBus.subscribe<CandidateCreatedEvent>((_) {
        throw Exception('handler failure');
      });

      // emit must not throw even though the subscriber throws.
      expect(
        () => eventBus.emit(CandidateCreatedEvent(
          candidateId: 'cx',
          confidence: 0.5,
          timestamp: DateTime.now(),
        )),
        returnsNormally,
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));
    });

    test('handles various event types', () async {
      final events = <String>[];
      eventBus.stream.listen((e) => events.add(e.type));

      eventBus.emit(FactConfirmedEvent(
        factId: 'f',
        entityId: 'e',
        factType: 't',
        timestamp: DateTime.now(),
      ));
      eventBus.emit(CandidateCreatedEvent(
        candidateId: 'c',
        confidence: 0.5,
        timestamp: DateTime.now(),
      ));
      eventBus.emit(SummaryRefreshedEvent(
        summaryId: 's',
        entityId: 'e',
        timestamp: DateTime.now(),
      ));
      eventBus.emit(ProfileAppliedEvent(
        profileId: 'p',
        entityId: 'e',
        duration: const Duration(milliseconds: 100),
        timestamp: DateTime.now(),
      ));
      eventBus.emit(PipelineCompletedEvent(
        pipelineId: 'pipe',
        success: true,
        metrics: {},
        timestamp: DateTime.now(),
      ));

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(events, containsAll([
        'fact_confirmed',
        'candidate_created',
        'summary_refreshed',
        'profile_applied',
        'pipeline_completed',
      ]));
    });
  });
}
