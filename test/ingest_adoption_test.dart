// Evidence that enters through the ingest facade is taken in by the engine:
// it gets the audit chain and the extractedFrom edges that evidence ingested
// by the engine itself gets.

import 'package:mcp_knowledge/mcp_knowledge.dart';
import 'package:test/test.dart';

void main() {
  test('ingested evidence has an audit chain and edges to its fragments',
      () async {
    final container = InMemoryStorageContainer();
    final system = KnowledgeSystem(
      config: const KnowledgeConfig(workspaceId: 'w'),
      factGraph:
          FactGraphRuntime.fromStorages(container, defaultWorkspaceId: 'w'),
    );
    addTearDown(system.shutdown);
    final result = await system.ingest.ingestText(
      '배송비는 포함입니다. 반품은 30일 이내입니다.',
      options: IngestOptions.defaults.copyWith(extractFragments: true),
    );
    expect(result.error, isNull);
    final evidenceId = result.evidence!.evidenceId;
    final stored = (await container.evidence.getEvidence(evidenceId))!;
    expect(stored.workspaceId, 'w');
    expect(stored.fragmentIds.toSet(),
        {for (final f in result.fragments) f.fragmentId});
    expect(await container.evidenceAudit.chain(evidenceId), hasLength(1));
    final edges = await container.edges
        .queryEdges(const EdgeQuery(type: EdgeType.extractedFrom));
    expect(edges.map((e) => e.sourceId).toSet(),
        {for (final f in result.fragments) f.fragmentId});
    expect(edges.every((e) => e.targetId == evidenceId), isTrue);
    expect(
        (await container.evidence.getFragments(evidenceId))
            .every((f) => f.workspaceId == 'w'),
        isTrue);
  });
}
