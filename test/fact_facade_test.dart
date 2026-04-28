/// FactFacade integration tests against a real FactGraphRuntime.
library;

import 'package:mcp_knowledge/mcp_knowledge.dart';
import 'package:test/test.dart';

void main() {
  group('FactFacade with FactGraphRuntime.inMemory', () {
    late FactGraphRuntime factGraph;
    late KnowledgeSystem system;

    setUp(() async {
      factGraph = FactGraphRuntime.inMemory(defaultWorkspaceId: 'test-ws');
      await factGraph.initialize();
      system = KnowledgeSystem(
        config: const KnowledgeConfig(workspaceId: 'test-ws'),
        factGraph: factGraph,
      );
    });

    tearDown(() async {
      await factGraph.close();
      await system.shutdown();
    });

    test('isAvailable is true when factGraph is wired', () {
      expect(system.facts.isAvailable, isTrue);
    });

    test('writeFacts and queryFacts roundtrip', () async {
      final now = DateTime.now();
      await system.facts.writeFacts([
        FactRecord(
          id: 'f1',
          workspaceId: 'test-ws',
          type: 'observation',
          entityId: 'e1',
          content: const {'value': 42},
          createdAt: now,
        ),
      ]);
      final results = await system.facts.queryFacts(
        const FactQuery(workspaceId: 'test-ws', entityId: 'e1'),
      );
      expect(results.length, equals(1));
      expect(results.first.id, equals('f1'));
    });

    test('createCandidates creates a CandidateCreatedEvent', () async {
      var eventCount = 0;
      system.eventBus.on<CandidateCreatedEvent>().listen((_) => eventCount++);

      await system.facts.createCandidates([
        CandidateRecord(
          id: 'c1',
          workspaceId: 'test-ws',
          type: 'fact',
          content: const {'text': 'maybe'},
          createdAt: DateTime.now(),
          confidence: 0.6,
        ),
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(eventCount, equals(1));
    });

    test('storePattern → getPattern roundtrip via PatternsPort', () async {
      final id = await system.facts.storePattern(
        PatternRecord(
          id: 'p1',
          workspaceId: 'test-ws',
          type: 'temporal',
          description: 'spike',
          detectedAt: DateTime.now(),
        ),
      );
      expect(id, equals('p1'));
    });

    test('refreshSummary emits SummaryRefreshedEvent', () async {
      var received = false;
      system.eventBus.on<SummaryRefreshedEvent>().listen((_) {
        received = true;
      });
      await system.facts.refreshSummary('e1', 'overview');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(received, isTrue);
    });
  });

  group('FactFacade with default L0 runtime', () {
    test('auto-wires FactGraphRuntime.inMemory() when factGraph is omitted',
        () async {
      final system = KnowledgeSystem(config: KnowledgeConfig.defaults);
      final facts = await system.facts.queryFacts(
        const FactQuery(workspaceId: 'x'),
      );
      expect(facts, isEmpty);
      await system.shutdown();
    });
  });
}
