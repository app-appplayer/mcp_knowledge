/// Scenario G — Full orchestration integration test.
///
/// REDESIGN-PLAN Phase 8 §5 / DoD #5: wire all five runtimes
/// (FactGraphRuntime + SkillRuntime + ProfileRuntime + PhilosophyEngine
/// + OpsRuntime) into a single `KnowledgeSystem` and verify that every
/// facade is reachable and the orchestrator does not need any bridges
/// or raw-accessor adapters to compose them.
library;

import 'package:mcp_knowledge/mcp_knowledge.dart';
import 'package:mcp_profile/mcp_profile.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Scenario G — full orchestration', () {
    late FactGraphRuntime factGraph;
    late SkillRuntime skillRuntime;
    late ProfileRuntime profileRuntime;
    late PhilosophyEngine philosophyEngine;
    late OpsRuntime opsRuntime;
    late KnowledgeSystem system;

    setUp(() async {
      // 1. FactGraph
      factGraph = FactGraphRuntime.inMemory(defaultWorkspaceId: 'g');
      await factGraph.initialize();

      // 2. Skill
      skillRuntime = SkillRuntime(
        registry: MemorySkillRegistry(),
        ports: SkillPorts(
          llm: StubLlmPort(),
          mcp: const StubMcpPort(),
          facts: factGraph.facts,
          claims: factGraph.claims,
          contextBundle: factGraph.contextBundle,
          retrieval: factGraph.retrieval,
          asset: factGraph.asset,
        ),
      );

      // 3. Profile
      final profileRegistry = p.ProfileRegistry();
      profileRegistry.register(const p.Profile(
        id: 'g-profile',
        name: 'G Profile',
        version: '1.0.0',
      ));
      profileRuntime = ProfileRuntime(
        registry: profileRegistry,
        engines: EnginePorts.stub(),
      );

      // 4. Philosophy
      philosophyEngine = PhilosophyEngine(
        ethosStore: const StubEthosStorePort(),
        facts: factGraph.facts,
        evidence: factGraph.evidence,
        contextBundle: factGraph.contextBundle,
      );

      // 5. Ops
      opsRuntime = OpsRuntime.fromConsumedPorts(ConsumedOpsPorts(
        facts: factGraph.facts,
        claims: factGraph.claims,
        skillRuntime: const StubSkillRuntimePort(),
        appraisal: const StubAppraisalPort(),
        decision: const StubDecisionPort(),
        metrics: const StubMetricsPort(),
        mcp: const StubMcpPort(),
        llm: StubLlmPort(),
        philosophy: philosophyEngine,
        kvStorage: InMemoryKvStoragePort(),
      ));

      // 6. Compose
      system = KnowledgeSystem(
        config: const KnowledgeConfig(workspaceId: 'g'),
        ports: KnowledgePorts(
          facts: factGraph.facts,
          claims: factGraph.claims,
          entities: factGraph.entities,
          candidates: factGraph.candidates,
          evidence: factGraph.evidence,
          patterns: factGraph.patterns,
          summaries: factGraph.summaries,
          contextBundle: factGraph.contextBundle,
          retrieval: factGraph.retrieval,
          philosophy: philosophyEngine,
          llm: StubLlmPort(),
          mcp: const StubMcpPort(),
        ),
        factGraph: factGraph,
        skillRuntime: skillRuntime,
        profileRuntime: profileRuntime,
        philosophyEngine: philosophyEngine,
        opsRuntime: opsRuntime,
      );
    });

    tearDown(() async {
      await factGraph.close();
      await system.shutdown();
    });

    test('every facade reports available', () {
      expect(system.facts.isAvailable, isTrue);
      expect(system.skill.isAvailable, isTrue);
      expect(system.profile.isAvailable, isTrue);
      expect(system.philosophy.isAvailable, isTrue);
      expect(system.ops.isAvailable, isTrue);
    });

    test('facts → profile → ops chained workflow', () async {
      // 1. Write a fact via the FactsPort.
      await system.facts.writeFacts([
        FactRecord(
          id: 'f-g1',
          workspaceId: 'g',
          type: 'observation',
          entityId: 'user-1',
          content: const {'mood': 'curious'},
          createdAt: DateTime.now(),
        ),
      ]);
      final facts = await system.facts.getFactsForEntity('user-1');
      expect(facts.length, equals(1));

      // 2. Apply a profile via the real ProfileRuntime.
      final profileResult = await system.profile.apply(
        'g-profile',
        entityId: 'user-1',
      );
      expect(profileResult.profileId, equals('g-profile'));

      // 3. List workflows via the real OpsRuntime / WorkflowPort.
      final workflows = await system.ops.listWorkflows();
      expect(workflows, isNotEmpty);
    });
  });

  group('Scenario H — partial orchestration', () {
    test('runs with only fact graph + profile (no skill / philosophy / ops)',
        () async {
      final factGraph = FactGraphRuntime.inMemory();
      await factGraph.initialize();
      final registry = p.ProfileRegistry();
      registry.register(const p.Profile(
        id: 'h-profile',
        name: 'H Profile',
        version: '1.0.0',
      ));
      final system = KnowledgeSystem(
        config: KnowledgeConfig.defaults,
        ports: KnowledgePorts(
          facts: factGraph.facts,
          claims: factGraph.claims,
        ),
        factGraph: factGraph,
        profileRuntime: ProfileRuntime(
          registry: registry,
          engines: EnginePorts.stub(),
        ),
      );

      expect(system.facts.isAvailable, isTrue);
      expect(system.profile.isAvailable, isTrue);
      expect(system.skill.isAvailable, isFalse);
      expect(system.philosophy.isAvailable, isFalse);
      expect(system.ops.isAvailable, isFalse);

      final result = await system.profile.apply('h-profile', entityId: 'e1');
      expect(result.profileId, equals('h-profile'));

      await factGraph.close();
      await system.shutdown();
    });
  });
}
