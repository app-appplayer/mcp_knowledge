/// FactFacade: every wrapped port call against a real in-memory runtime.
library;

import 'package:mcp_fact_graph/mcp_fact_graph.dart' as fg;
import 'package:mcp_knowledge/mcp_knowledge.dart';
import 'package:test/test.dart';

void main() {
  late FactGraphRuntime runtime;
  late KnowledgeSystem system;
  late List<KnowledgeEvent> events;
  final t0 = DateTime.utc(2026, 6, 1);

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 5));

  setUp(() async {
    runtime = FactGraphRuntime.inMemory(defaultWorkspaceId: 'w');
    await runtime.initialize();
    system = KnowledgeSystem(
      config: const KnowledgeConfig(workspaceId: 'w'),
      factGraph: runtime,
    );
    events = [];
    system.eventBus.stream.listen(events.add);
  });

  tearDown(() async {
    await runtime.close();
    await system.shutdown();
  });

  test('the facade exposes its system', () {
    expect(system.facts.system, same(system));
  });

  test('evidence: fragments, confidence and classification', () async {
    final fragments = await system.facts
        .extractFragments('Paid 30 USD on 2026-05-01 to Acme.', 'text/plain');
    expect(fragments, isNotEmpty);
    expect(await system.facts.computeFragmentConfidence('Paid 30 USD'),
        inInclusiveRange(0, 1));
    expect(await system.facts.classifyFragment('Paid 30 USD'), isNotEmpty);
  });

  test('candidates: pending, confirm (event), reject', () async {
    await system.facts.createCandidates([
      CandidateRecord(
          id: 'c1',
          workspaceId: 'w',
          type: 'fact',
          content: const {'text': 'a'},
          createdAt: t0,
          confidence: 0.5),
      CandidateRecord(
          id: 'c2',
          workspaceId: 'w',
          type: 'fact',
          content: const {'text': 'b'},
          createdAt: t0),
    ]);
    expect(await system.facts.getPendingCandidates(), hasLength(2));
    expect(await system.facts.getPendingCandidates(workspaceId: 'w', limit: 1),
        hasLength(1));
    await system.facts.rejectCandidate('c2', 'duplicate', reviewerId: 'r');
    await system.facts.confirmCandidate('c1', reviewerId: 'r');
    await settle();
    expect(events.whereType<FactConfirmedEvent>().single.factId, 'c1');
    expect(await system.facts.getPendingCandidates(), isEmpty);
  });

  test('facts: write, get, query by entity, delete', () async {
    FactRecord rec(String id) => FactRecord(
        id: id,
        workspaceId: 'w',
        type: 'note',
        entityId: 'e1',
        content: const {'v': 1},
        createdAt: t0);
    await system.facts.writeFacts([rec('f1'), rec('f2')]);
    expect((await system.facts.getFact('f1'))!.id, 'f1');
    expect(await system.facts.getFact('missing'), isNull);
    expect(await system.facts.getFactsForEntity('e1'), hasLength(2));
    expect(
        await system.facts
            .getFactsForEntity('e1', workspaceId: 'w', limit: 1, period: null),
        hasLength(1));
    await system.facts.deleteFacts(['f1']);
    expect(await system.facts.getFact('f1'), isNull);
  });

  test('entities: get and merge', () async {
    for (final id in ['a', 'b']) {
      await runtime.entityStorage.saveEntity(fg.Entity(
          entityId: id,
          workspaceId: 'w',
          type: 'person',
          canonicalName: 'Name $id',
          createdAt: t0,
          updatedAt: t0));
    }
    expect((await system.facts.getEntity('a'))!.name, 'Name a');
    expect(await system.facts.getEntity('zz'), isNull);
    final merged = await system.facts.mergeEntities('a', 'b');
    expect(merged.id, 'a');
  });

  test('claims: write (event) and query', () async {
    await system.facts.writeClaims([
      const Claim(
          id: 'cl1',
          workspaceId: 'w',
          text: 'Acme was paid',
          type: ClaimType.fact,
          subject: 'acme',
          evidenceRefs: [],
          confidence: 0.9),
    ], evidenceRefs: const []);
    await system.facts.writeClaims(const []);
    await settle();
    final e = events.whereType<ClaimsRecordedEvent>().toList();
    expect(e.first.entityId, 'acme');
    expect(e.last.entityId, '');
    expect(await system.facts.queryClaims(const ClaimQuery(workspaceId: 'w')),
        hasLength(1));
  });

  test('summaries: get, refresh, mark stale', () async {
    expect(await system.facts.getSummary('e1', 'overview'), isNull);
    await system.facts.refreshSummary('e1', 'overview');
    expect(await system.facts.getSummary('e1', 'overview'), isNotNull);
    await system.facts.markSummariesStale(['e1'], summaryType: 'overview');
  });

  test('patterns: store, get, query', () async {
    await system.facts.storePattern(PatternRecord(
        id: 'p1',
        workspaceId: 'w',
        type: 'temporal',
        description: 'spike',
        detectedAt: t0));
    expect((await system.facts.getPattern('p1'))!.id, 'p1');
    expect(await system.facts.getPattern('zz'), isNull);
    expect(
        await system.facts.queryPatterns(const PatternQuery(workspaceId: 'w')),
        hasLength(1));
  });
}
