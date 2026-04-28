/// OpsFacade integration tests against a real OpsRuntime.
///
/// REDESIGN-PLAN Phase 8 §4 step 6 / DoD #5: replaces the legacy
/// `BundleFacade` test surface. Verifies that the orchestrator delegates
/// to the standard `WorkflowPort` / `PipelinePort` / `RunbookPort`
/// implementations provided by `OpsRuntime`.
library;

import 'package:mcp_knowledge/mcp_knowledge.dart';
import 'package:test/test.dart';

ConsumedOpsPorts _stubConsumed() {
  return ConsumedOpsPorts(
    facts: const StubFactsPort(),
    claims: const StubClaimsPort(),
    skillRuntime: const StubSkillRuntimePort(),
    appraisal: const StubAppraisalPort(),
    decision: const StubDecisionPort(),
    metrics: const StubMetricsPort(),
    mcp: const StubMcpPort(),
    llm: StubLlmPort(),
    philosophy: const StubPhilosophyPort(),
    kvStorage: InMemoryKvStoragePort(),
  );
}

void main() {
  group('OpsFacade with OpsRuntime.fromConsumedPorts', () {
    late OpsRuntime opsRuntime;
    late KnowledgeSystem system;

    setUp(() {
      opsRuntime = OpsRuntime.fromConsumedPorts(_stubConsumed());
      system = KnowledgeSystem(
        config: KnowledgeConfig.defaults,
        opsRuntime: opsRuntime,
      );
    });

    tearDown(() async {
      await system.shutdown();
    });

    test('isAvailable is true', () {
      expect(system.ops.isAvailable, isTrue);
    });

    test('listWorkflows surfaces the built-in workflow registry', () async {
      final workflows = await system.ops.listWorkflows();
      expect(workflows, isNotEmpty);
      expect(
        workflows.map((w) => w.id),
        containsAll(['skill_build', 'profile_build', 'bundle_build']),
      );
    });

    test('runWorkflow with unknown id reports failure on the run handle',
        () async {
      final handle = await system.ops.runWorkflow('does-not-exist', const {});
      expect(handle.status, isNot(equals('succeeded')));
    });

    test('runPipeline with unknown id reports failure on the run handle',
        () async {
      final handle = await system.ops.runPipeline('does-not-exist', const {});
      expect(handle.status, isNot(equals('succeeded')));
    });

    test('loadBundle emits BundleLoadedEvent with manifest counts', () async {
      BundleLoadedEvent? captured;
      system.eventBus.on<BundleLoadedEvent>().listen((e) => captured = e);
      await system.ops.loadBundle('bundle-a', {
        'skills': [
          {'id': 's1'},
          {'id': 's2'},
        ],
        'profiles': [
          {'id': 'p1'},
        ],
      });
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(captured, isNotNull);
      expect(captured!.bundleId, 'bundle-a');
      expect(captured!.skillCount, 2);
      expect(captured!.profileCount, 1);
    });

    test('loadBundle handles manifests with a nested components map',
        () async {
      BundleLoadedEvent? captured;
      system.eventBus.on<BundleLoadedEvent>().listen((e) => captured = e);
      await system.ops.loadBundle('bundle-b', {
        'components': {
          'skills': [
            {'id': 's1'},
          ],
          'profiles': [
            {'id': 'p1'},
            {'id': 'p2'},
          ],
        },
      });
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(captured, isNotNull);
      expect(captured!.skillCount, 1);
      expect(captured!.profileCount, 2);
    });
  });

  group('OpsFacade.loadBundle without an OpsRuntime', () {
    test('throws StateError when no OpsRuntime is wired', () async {
      final system = KnowledgeSystem(
        config: KnowledgeConfig.defaults,
      );
      addTearDown(system.shutdown);
      expect(
        () => system.ops.loadBundle('b', const {}),
        throwsStateError,
      );
    });
  });

  group('OpsFacade fallback to KnowledgePorts', () {
    test('falls back to bare WorkflowPort when no runtime is wired', () async {
      final system = KnowledgeSystem(
        config: KnowledgeConfig.defaults,
        ports: const KnowledgePorts(
          workflow: StubWorkflowPort(),
          pipeline: StubPipelinePort(),
        ),
      );
      expect(system.ops.isAvailable, isTrue);
      final handle = await system.ops.runWorkflow('any', const {});
      expect(handle.status, equals('succeeded'));
    });
  });
}
