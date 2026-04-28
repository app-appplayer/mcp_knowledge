/// KnowledgeSystem orchestration tests.
library;

import 'package:mcp_knowledge/mcp_knowledge.dart';
import 'package:test/test.dart';

void main() {
  group('KnowledgeSystem construction', () {
    test('auto-wires L0 FactGraph; opt-in runtimes stay null', () {
      final system = KnowledgeSystem(
        config: KnowledgeConfig.defaults,
        ports: KnowledgePorts.stub(),
      );

      expect(system.facts, isA<FactFacade>());
      expect(system.skill, isA<SkillFacade>());
      expect(system.profile, isA<ProfileFacade>());
      expect(system.philosophy, isA<PhilosophyFacade>());
      expect(system.ops, isA<OpsFacade>());

      // L0 is core-mandatory — auto-wired even with no explicit runtime.
      expect(system.factGraph, isNotNull);

      // L1~L3 and Ops are opt-in.
      expect(system.skillRuntime, isNull);
      expect(system.profileRuntime, isNull);
      expect(system.philosophyEngine, isNull);
      expect(system.opsRuntime, isNull);
    });

    test('KnowledgeSystem.stub() returns a stub-everything orchestrator',
        () async {
      final system = KnowledgeSystem.stub();
      expect(system.config, equals(KnowledgeConfig.defaults));
      expect(system.ports.facts, isA<FactsPort>());
      await system.shutdown();
    });

    test('KnowledgeSystem.defaults wires the supplied runtimes', () {
      final factGraph = FactGraphRuntime.inMemory();
      final system = KnowledgeSystem.defaults(
        ports: KnowledgePorts(
          facts: factGraph.facts,
          claims: factGraph.claims,
        ),
        factGraph: factGraph,
      );
      expect(system.factGraph, same(factGraph));
      expect(system.facts.isAvailable, isTrue);
    });

    test('shutdown emits SystemShutdownEvent then closes the bus', () async {
      final system = KnowledgeSystem.stub();
      var received = false;
      system.eventBus.on<SystemShutdownEvent>().listen((_) {
        received = true;
      });
      await system.shutdown();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(received, isTrue);
    });
  });

  group('Scenario H — facade availability', () {
    test('facts facade is always available (L0 is core-mandatory)', () {
      final system = KnowledgeSystem(config: KnowledgeConfig.defaults);
      expect(system.facts.isAvailable, isTrue);
    });

    test('facts facade resolves ports from KnowledgePorts when factGraph null',
        () {
      final system = KnowledgeSystem(
        config: KnowledgeConfig.defaults,
        ports: const KnowledgePorts(facts: StubFactsPort()),
      );
      expect(system.facts.isAvailable, isTrue);
    });

    test('skill facade throws StateError when no runtime is wired', () async {
      final system = KnowledgeSystem(config: KnowledgeConfig.defaults);
      expect(system.skill.isAvailable, isFalse);
      expect(
        () => system.skill.execute('any', const {}),
        throwsA(isA<StateError>()),
      );
    });

    test('profile facade throws StateError when no runtime is wired', () async {
      final system = KnowledgeSystem(config: KnowledgeConfig.defaults);
      expect(system.profile.isAvailable, isFalse);
      expect(
        () => system.profile.apply('any', entityId: 'e1'),
        throwsA(isA<StateError>()),
      );
    });

    test('philosophy facade throws StateError when no port is wired', () async {
      final system = KnowledgeSystem(config: KnowledgeConfig.defaults);
      expect(system.philosophy.isAvailable, isFalse);
      expect(
        () => system.philosophy.getEthos(),
        throwsA(isA<StateError>()),
      );
    });

    test('ops facade throws StateError when no runtime is wired', () async {
      final system = KnowledgeSystem(config: KnowledgeConfig.defaults);
      expect(system.ops.isAvailable, isFalse);
      expect(
        () => system.ops.runWorkflow('any', const {}),
        throwsA(isA<StateError>()),
      );
    });
  });
}
