/// OpsFacade: run lookups, runbooks, behaviors and the port-only fallbacks.
library;

import 'package:mcp_knowledge/mcp_knowledge.dart';
import 'package:mcp_knowledge_ops/mcp_knowledge_ops.dart' as ops;
import 'package:test/test.dart';

ConsumedOpsPorts _consumed() => ConsumedOpsPorts(
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

void main() {
  late OpsRuntime runtime;
  late KnowledgeSystem system;

  setUp(() {
    runtime = OpsRuntime.fromConsumedPorts(_consumed());
    runtime.behaviorRegistry['approve'] = () {
      final store = ops.EphemeralStateStore();
      return ops.BehaviorRunnable(
        ops.BehaviorEngine(
            store: store, dispatch: (a, s) async => {'paid': true}),
        const [
          ops.BehaviorStep(
              id: 'gate', when: 'approved == true', then: {'false': 'wait'}),
          ops.BehaviorStep(
              id: 'pay', action: ops.BehaviorAction(kind: 'tool', ref: 'pay')),
        ],
      );
    };
    runtime.behaviorRegistry['boom'] = () => ops.BehaviorRunnable(
          ops.BehaviorEngine(
              store: ops.EphemeralStateStore(),
              dispatch: (a, s) async => throw StateError('exploded')),
          const [
            ops.BehaviorStep(
                id: 's', action: ops.BehaviorAction(kind: 'tool', ref: 'x')),
          ],
        );
    system =
        KnowledgeSystem(config: KnowledgeConfig.defaults, opsRuntime: runtime);
  });

  tearDown(() => system.shutdown());

  test('the facade exposes its system', () {
    expect(system.ops.system, same(system));
  });

  test('workflow and pipeline runs can be looked up', () async {
    final w = await system.ops.runWorkflow('skill_build', const {});
    expect((await system.ops.getWorkflowRun(w.runId))?.runId, w.runId);
    expect(await system.ops.getWorkflowRun('nope'), isNull);
    final p = await system.ops.runPipeline('curation_pipeline', const {});
    expect((await system.ops.getPipelineRun(p.runId))?.runId, p.runId);
    expect(await system.ops.getPipelineRun('nope'), isNull);
  });

  test('runbooks run and list through the runtime', () async {
    final listed = await system.ops.listRunbooks();
    expect(listed, isA<List<RunbookDescriptor>>());
    final run = await system.ops.runRunbook('missing', const {});
    expect(run.runbookId, 'missing');
  });

  test('runbooks fall back to a bare port', () async {
    final s = KnowledgeSystem(
        config: KnowledgeConfig.defaults,
        ports: const KnowledgePorts(runbook: StubRunbookPort()));
    addTearDown(s.shutdown);
    expect((await s.ops.runRunbook('r', const {})).status, 'succeeded');
    expect(await s.ops.listRunbooks(), isEmpty);
  });

  test('a behavior runs, suspends at its gate and resumes with a patch',
      () async {
    expect(system.ops.listBehaviors(), containsAll(['approve', 'boom']));
    final first = await system.ops.runBehavior('approve', runId: 'r1');
    expect(first['status'], 'suspended');
    expect(first['waitingStepId'], 'gate');
    expect(first['behaviorId'], 'approve');
    expect(first['runId'], 'r1');
    expect(first.containsKey('error'), isFalse);
  });

  test('a resumed behavior continues once its guard holds', () async {
    final store = ops.EphemeralStateStore();
    const steps = [
      ops.BehaviorStep(
          id: 'gate', when: 'approved == true', then: {'false': 'wait'}),
      ops.BehaviorStep(
          id: 'pay', action: ops.BehaviorAction(kind: 'tool', ref: 'pay')),
    ];
    runtime.behaviorRegistry['shared'] = () => ops.BehaviorRunnable(
        ops.BehaviorEngine(store: store, dispatch: (a, s) async => null),
        steps);
    expect((await system.ops.runBehavior('shared', runId: 'x'))['status'],
        'suspended');
    final done = await system.ops
        .resumeBehavior('shared', 'x', statePatch: {'approved': true});
    expect(done['status'], 'completed');
  });

  test('a behavior without a run id gets one; a failing one reports error',
      () async {
    final r = await system.ops.runBehavior('boom');
    expect(r['status'], 'failed');
    expect(r['error'], contains('exploded'));
    expect(r['runId'], startsWith('boom:'));
  });

  test('an unknown behavior, and no runtime, are refused', () {
    expect(() => system.ops.runBehavior('nope'), throwsStateError);
    final bare = KnowledgeSystem(config: KnowledgeConfig.defaults);
    addTearDown(bare.shutdown);
    expect(() => bare.ops.listBehaviors(), throwsStateError);
    expect(() => bare.ops.listWorkflows(), throwsStateError);
    expect(() => bare.ops.runPipeline('p', const {}), throwsStateError);
  });

  test('a failed workflow carries its error into the event', () async {
    final events = <PipelineCompletedEvent>[];
    system.eventBus.on<PipelineCompletedEvent>().listen(events.add);
    await system.ops.runWorkflow('does-not-exist', const {});
    await system.ops.runPipeline('does-not-exist', const {});
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(events, hasLength(2));
    expect(events.every((e) => !e.success), isTrue);
    expect(events.every((e) => e.metrics.containsKey('error')), isTrue);
  });
}
