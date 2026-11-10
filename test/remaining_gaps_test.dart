/// copyWith of the configuration and ports, the profile facade's appraise and
/// exception, and ingestion that stores fragments.
library;

import 'dart:typed_data';

import 'package:mcp_ingest/mcp_ingest.dart' as ing;
import 'package:mcp_knowledge/mcp_knowledge.dart';
import 'package:test/test.dart';

void main() {
  test('KnowledgeConfig.copyWith replaces each part and keeps the rest', () {
    const base = KnowledgeConfig.defaults;
    const skill = SkillConfig(maxConcurrentExecutions: 3);
    const philosophy = PhilosophyConfig(enabled: false);
    final c = base.copyWith(
      workspaceId: 'w2',
      factGraph: const FactGraphConfig(),
      skill: skill,
      profile: const ProfileConfig(),
      pipeline: const PipelineConfig(),
      scheduler: const SchedulerConfig(),
      events: const EventConfig(),
      logging: const LoggingConfig(),
      features: const FeatureFlags(),
      philosophy: philosophy,
    );
    expect(c.workspaceId, 'w2');
    expect(c.skill, same(skill));
    expect(c.philosophy, same(philosophy));
    final same2 = base.copyWith();
    expect(same2.workspaceId, base.workspaceId);
    expect(same2.skill, same(base.skill));
    expect(same2.logging, same(base.logging));
  });

  test('SkillConfig.copyWith', () {
    const budget = ExecutionBudgetConfig(maxTokens: 5);
    final c = const SkillConfig().copyWith(
        defaultTimeout: const Duration(seconds: 1),
        maxConcurrentExecutions: 2,
        recordClaimsByDefault: false,
        defaultBudget: budget);
    expect(c.defaultTimeout, const Duration(seconds: 1));
    expect(c.maxConcurrentExecutions, 2);
    expect(c.recordClaimsByDefault, isFalse);
    expect(c.defaultBudget, same(budget));
    final kept = c.copyWith();
    expect(kept.maxConcurrentExecutions, 2);
    expect(kept.defaultBudget, same(budget));
  });

  test('KnowledgePorts.copyWith replaces a port and keeps the others', () {
    const a = KnowledgePorts(workflow: StubWorkflowPort());
    final b = a.copyWith(claims: const StubClaimsPort());
    expect(b.workflow, isNotNull);
    expect(b.claims, isNotNull);
    expect(a.claims, isNull);
    expect(b.copyWith().claims, same(b.claims));
  });

  test('ProfileException has a message and a readable form', () {
    final e = ProfileException('bad');
    expect(e.message, 'bad');
    expect(e.toString(), 'ProfileException: bad');
  });

  test('ProfileFacade: exposes its system and appraises', () async {
    final registry = ProfileRegistry()
      ..register(const Profile(id: 'p', name: 'P', version: '1'));
    final s = KnowledgeSystem(
      config: KnowledgeConfig.defaults,
      profileRuntime:
          ProfileRuntime(registry: registry, engines: EnginePorts.stub()),
    );
    addTearDown(s.shutdown);
    expect(s.profile.system, same(s));
    final r = await s.profile.appraise('p', entityId: 'e');
    expect(r.profileId, 'p');
  });

  test('ingest stores the fragments of a successful ingestion', () async {
    final registry = ing.ExtractorRegistry()..register(_KeyValueExtractor());
    final s = KnowledgeSystem(config: const KnowledgeConfig(workspaceId: 'w'));
    addTearDown(s.shutdown);
    final facade = IngestFacade(
        system: s,
        pipeline: ing.IngestPipeline(
            extractors: registry, chunkerFactory: ing.ChunkerFactory()));
    expect(facade.system, same(s));
    final r = await facade.ingest(
        ing.IngestInput.fromBytes(Uint8List.fromList([1, 2, 3]),
            mimeType: 'text/x-kv'),
        options: IngestOptions.defaults
            .copyWith(extractFragments: true, fragmentRules: const [
          ing.FragmentRule(
            id: 'r1',
            field: 'amount',
            pattern: 'total',
            patternType: ing.FragmentPatternType.keyword,
            valueType: ing.FragmentValueType.currency,
          ),
        ]));
    expect(r.success, isTrue);
    expect(r.fragments, isNotEmpty);
    final stored =
        await s.factGraph.evidenceStorage.getFragments(r.evidence!.evidenceId);
    expect(stored, hasLength(r.fragments.length));
  });
}

class _KeyValueExtractor extends ing.Extractor {
  @override
  String get id => 'kv';
  @override
  Set<String> get supportedTypes => {'text/x-kv'};
  @override
  int get priority => 100;
  @override
  Duration estimateDuration(int fileSize) => Duration.zero;
  @override
  Future<ing.NormalizedDocument> extract(
      Stream<List<int>> input, ing.ExtractOptions options) async {
    await input.drain<void>();
    return ing.NormalizedDocument(
      id: 'doc',
      metadata: const ing.DocumentMetadata(
          mimeType: 'text/x-kv', sha256: 'abc', fileSize: 3),
      parts: const [
        ing.KeyValueBlock(id: 'kv1', key: 'Total', value: '100.00')
      ],
      structure: ing.DocumentStructure.empty,
      provenance: ing.ExtractionProvenance(
        extractorId: 'kv',
        extractorVersion: '1',
        extractedAt: DateTime.utc(2026),
        extractionDuration: Duration.zero,
      ),
    );
  }
}
