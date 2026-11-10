import 'dart:convert';

import 'package:mcp_ingest/mcp_ingest.dart' as mi
    show IngestInput, IngestPipeline;
import 'package:mcp_knowledge/mcp_knowledge.dart';
import 'package:test/test.dart';

void main() {
  late KnowledgeSystem system;

  setUp(() => system = KnowledgeSystem.stub());
  tearDown(() => system.shutdown());

  test('ingestText stores the evidence and fragments in the system workspace',
      () async {
    final result = await system.ingest.ingestText(
      '배송비는 포함입니다. 반품은 30일 이내입니다.',
      options: IngestOptions.defaults.copyWith(extractFragments: true),
    );

    expect(result.error, isNull);
    final evidence = result.evidence!;
    expect(evidence.workspaceId, system.config.workspaceId);
    final storage = system.factGraph.evidenceStorage;
    final stored = await storage.getEvidence(evidence.evidenceId);
    expect(stored, isNotNull);
    expect(stored!.workspaceId, system.config.workspaceId);
    expect((await storage.getFragments(evidence.evidenceId)).length,
        result.fragments.length);
  });

  test('a given workspace wins over the system workspace', () async {
    final result =
        await system.ingest.ingestText('안녕하세요', workspaceId: 'ws-other');
    expect(result.evidence!.workspaceId, 'ws-other');
    final found = await system.factGraph.evidenceStorage
        .queryEvidence(const EvidenceQuery(workspaceId: 'ws-other'));
    expect(found.single.evidenceId, result.evidence!.evidenceId);
  });

  test('ingest reads a byte stream with its mime type', () async {
    final result = await system.ingest.ingest(
      mi.IngestInput(
        stream: Stream.value(
            utf8.encode('<html><body><p>한국어 문서</p></body></html>')),
        filename: 'page.html',
        mimeType: 'text/html',
      ),
    );
    expect(result.error, isNull);
    expect(result.evidence!.mimeType, 'text/html');
  });

  test('a failed ingestion saves nothing and returns the error', () async {
    final result = await system.ingest.ingest(
      mi.IngestInput(
        stream: Stream.value([1, 2, 3]),
        filename: 'blob.bin',
        mimeType: 'application/x-unknown-thing',
      ),
    );
    expect(result.error, isNotNull);
    expect(result.evidence, isNull);
    final all = await system.factGraph.evidenceStorage
        .queryEvidence(const EvidenceQuery());
    expect(all, isEmpty);
  });

  test('the facade is available and uses an injected pipeline', () async {
    final custom = KnowledgeSystem.stub();
    addTearDown(custom.shutdown);
    expect(custom.ingest.isAvailable, isTrue);
    final withPipeline = KnowledgeSystem(
      config: KnowledgeConfig.defaults,
      ports: KnowledgePorts.stub(),
      ingestPipeline: mi.IngestPipeline.defaults(),
    );
    addTearDown(withPipeline.shutdown);
    final r = await withPipeline.ingest.ingestText('hello');
    expect(r.error, isNull);
  });
}
