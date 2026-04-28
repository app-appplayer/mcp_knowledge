/// SkillFacade integration tests against a real `SkillRuntime`.
///
/// REDESIGN-PLAN Phase 8 §4 step 3 / DoD #3: this test verifies the
/// facade actually invokes `SkillRuntime.run()` (no LLM-only fakery).
library;

import 'package:mcp_bundle/mcp_bundle.dart'
    show Claim, ClaimType, ExecutionMetadata;
import 'package:mcp_knowledge/mcp_knowledge.dart';
import 'package:mcp_skill/mcp_skill.dart' as skill;
import 'package:test/test.dart';

void main() {
  group('SkillFacade with SkillRuntime', () {
    late KnowledgeSystem system;

    setUp(() {
      final registry = MemorySkillRegistry();
      final runtime = SkillRuntime(
        registry: registry,
        ports: SkillPorts(
          llm: StubLlmPort(),
          mcp: const StubMcpPort(),
        ),
      );
      system = KnowledgeSystem(
        config: KnowledgeConfig.defaults,
        skillRuntime: runtime,
      );
    });

    tearDown(() async {
      await system.shutdown();
    });

    test('isAvailable is true', () {
      expect(system.skill.isAvailable, isTrue);
    });

    test('execute against missing skill returns a failure result', () async {
      final result = await system.skill.execute(
        'unknown-skill',
        const {},
        entityId: 'e1',
      );
      expect(result.success, isFalse);
    });

    test('execute emits SkillExecutedEvent regardless of outcome', () async {
      var event = false;
      system.eventBus.on<SkillExecutedEvent>().listen((_) {
        event = true;
      });
      await system.skill.execute('unknown', const {});
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(event, isTrue);
    });

    test(
        'execute emits ClaimsRecordedEvent when the result contains claims',
        () async {
      final registry = MemorySkillRegistry();
      final runtime = _ClaimEmittingSkillRuntime(
        registry: registry,
        ports: SkillPorts(
          llm: StubLlmPort(),
          mcp: const StubMcpPort(),
        ),
      );
      final s = KnowledgeSystem(
        config: KnowledgeConfig.defaults,
        skillRuntime: runtime,
      );
      addTearDown(s.shutdown);

      ClaimsRecordedEvent? captured;
      s.eventBus.on<ClaimsRecordedEvent>().listen((e) => captured = e);
      await s.skill.execute('my-skill', const {}, entityId: 'ent-42');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(captured, isNotNull);
      expect(captured!.skillId, 'my-skill');
      expect(captured!.entityId, 'ent-42');
      expect(captured!.claimIds, ['claim-1']);
    });

    test(
        'SkillConfig.defaultBudget propagates to SkillContext.budget when '
        'execute is called without an explicit budget', () async {
      final registry = MemorySkillRegistry();
      final runtime = _CapturingSkillRuntime(
        registry: registry,
        ports: SkillPorts(
          llm: StubLlmPort(),
          mcp: const StubMcpPort(),
        ),
      );
      final s = KnowledgeSystem(
        config: const KnowledgeConfig(
          skill: SkillConfig(
            defaultBudget: ExecutionBudgetConfig(
              maxTokens: 1234,
              maxSteps: 7,
            ),
          ),
        ),
        skillRuntime: runtime,
      );
      addTearDown(s.shutdown);

      await s.skill.execute('unknown', const {});
      expect(runtime.lastContext?.budget, isNotNull);
      expect(runtime.lastContext!.budget!.maxTokens, equals(1234));
      expect(runtime.lastContext!.budget!.maxSteps, equals(7));
    });

    test('executeWithContext accepts a caller-built SkillContext', () async {
      final ctx = skill.SkillContext(
        contextId: 'ctx-1',
        skillId: 'unknown',
        runId: 'run-1',
        traceId: 'trace-1',
        request: 'noop',
        workspaceId: 'default',
        asOf: DateTime.now(),
      );
      final result = await system.skill.executeWithContext(ctx);
      expect(result, isA<SkillResult>());
    });
  });
}

/// SkillRuntime test double that returns a result with one claim.
class _ClaimEmittingSkillRuntime extends skill.SkillRuntime {
  _ClaimEmittingSkillRuntime({
    required super.registry,
    required super.ports,
  });

  @override
  Future<SkillResult> run(skill.SkillContext context) async {
    return SkillResult(
      claims: [
        Claim(
          id: 'claim-1',
          workspaceId: context.workspaceId,
          text: 'stub claim',
          type: ClaimType.conclusion,
          evidenceRefs: const [],
          confidence: 0.9,
        ),
      ],
      evidenceRefs: const [],
      confidence: 0.9,
      asOf: context.asOf,
      metadata: ExecutionMetadata(
        skillId: context.skillId,
        skillVersion: '1.0.0',
        procedureId: 'p1',
        startedAt: context.asOf,
        finishedAt: context.asOf,
        duration: Duration.zero,
        stepsExecuted: 0,
        toolsCalled: const [],
      ),
    );
  }
}

/// SkillRuntime test double that captures the context passed to [run].
class _CapturingSkillRuntime extends skill.SkillRuntime {
  skill.SkillContext? lastContext;

  _CapturingSkillRuntime({
    required super.registry,
    required super.ports,
  });

  @override
  Future<SkillResult> run(skill.SkillContext context) async {
    lastContext = context;
    return SkillResult.simpleError('captured', Duration.zero);
  }
}
