// The knowledge system over an in-memory fact graph: text ingested through
// the ingest facade, facts read through the fact facade. The example prints
// what it did.
// ignore_for_file: avoid_print

import 'package:mcp_knowledge/mcp_knowledge.dart';

Future<void> main() async {
  final factGraph = FactGraphRuntime.inMemory(defaultWorkspaceId: 'demo');
  await factGraph.initialize();

  final system = KnowledgeSystem(
    config: const KnowledgeConfig(workspaceId: 'demo'),
    ports: KnowledgePorts(facts: factGraph.facts),
    factGraph: factGraph,
  );

  // Evidence and fragments through the ingest pipeline; the fact graph takes
  // them in with the audit chain and the extracted-from edges.
  final ingested = await system.ingest.ingestText(
    'Shipping is included. Returns within 30 days.',
    options: IngestOptions.defaults.copyWith(extractFragments: true),
  );
  print('evidence ${ingested.evidence?.evidenceId}');

  // Facts through the fact facade.
  await system.facts.writeFacts([
    FactRecord(
      id: 'f1',
      workspaceId: 'demo',
      type: 'observation',
      entityId: 'user-1',
      content: const {'value': 42},
      createdAt: DateTime.now(),
    ),
  ]);
  final results = await system.facts.queryFacts(
    const FactQuery(workspaceId: 'demo', entityId: 'user-1'),
  );
  print('${results.length} fact(s) for user-1');

  await system.shutdown();
}
