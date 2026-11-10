/// SkillFacade: failure by exception, `run`, `executeWithContext` events and
/// the entity id fallbacks of ClaimsRecordedEvent.
library;

import 'package:mcp_knowledge/mcp_knowledge.dart';
import 'package:mcp_skill/mcp_skill.dart' as skill;
import 'package:test/test.dart';

enum _Mode { throws, claimsWithSubject, claimsNoSubject, ok, failed }

class _Runtime extends skill.SkillRuntime {
  _Runtime(this.mode)
      : super(
            registry: MemorySkillRegistry(),
            ports: SkillPorts(llm: StubLlmPort(), mcp: const StubMcpPort()));

  final _Mode mode;

  @override
  Future<SkillResult> run(skill.SkillContext context) async {
    if (mode == _Mode.throws) throw StateError('runtime exploded');
    if (mode == _Mode.failed) {
      return SkillResult.simpleError('nope', Duration.zero);
    }
    final withClaims =
        mode == _Mode.claimsWithSubject || mode == _Mode.claimsNoSubject;
    return SkillResult(
      claims: [
        if (withClaims)
          Claim(
            id: 'c1',
            workspaceId: context.workspaceId,
            text: 't',
            type: ClaimType.conclusion,
            subject: mode == _Mode.claimsWithSubject ? 'subj' : null,
            evidenceRefs: const [],
            confidence: 1,
          ),
      ],
      evidenceRefs: const [],
      confidence: 1,
      asOf: context.asOf,
      output: 'value',
      metadata: ExecutionMetadata(
        skillId: context.skillId,
        skillVersion: '1',
        procedureId: 'p',
        startedAt: context.asOf,
        finishedAt: context.asOf,
        duration: Duration.zero,
        stepsExecuted: 0,
        toolsCalled: const [],
        custom: const {'output': 'value'},
      ),
    );
  }
}

void main() {
  late List<KnowledgeEvent> events;

  KnowledgeSystem build(_Mode mode) {
    final s = KnowledgeSystem(
        config: KnowledgeConfig.defaults, skillRuntime: _Runtime(mode));
    events = [];
    s.eventBus.stream.listen(events.add);
    addTearDown(s.shutdown);
    return s;
  }

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 5));

  skill.SkillContext ctx({String? userId, Map<String, dynamic>? inputs}) =>
      skill.SkillContext(
        contextId: 'c',
        skillId: 's',
        runId: 'r',
        traceId: 't',
        request: '',
        workspaceId: 'w',
        asOf: DateTime.utc(2026),
        userId: userId,
        inputs: inputs ?? const {},
      );

  test('the facade exposes its system', () {
    final s = build(_Mode.ok);
    expect(s.skill.system, same(s));
  });

  test('a runtime that throws becomes a failed result and an event', () async {
    final s = build(_Mode.throws);
    final a = await s.skill.execute('s', const {});
    final b = await s.skill.executeWithContext(ctx());
    expect([a.success, b.success], [false, false]);
    await settle();
    final e = events.whereType<SkillExecutedEvent>().toList();
    expect(e, hasLength(2));
    expect(e.every((x) => !x.success), isTrue);
  });

  test('without a runtime the facade refuses', () {
    final s = KnowledgeSystem(config: KnowledgeConfig.defaults);
    addTearDown(s.shutdown);
    expect(s.skill.isAvailable, isFalse);
    expect(() => s.skill.execute('s', const {}), throwsStateError);
  });

  test('run returns the output or throws SkillException', () async {
    expect(await build(_Mode.ok).skill.run<String>('s', const {}), 'value');
    try {
      await build(_Mode.failed).skill.run<String>('s', const {});
      fail('should throw');
    } on SkillException catch (e) {
      expect(e.message, isNotEmpty);
      expect(e.toString(), startsWith('SkillException:'));
    }
  });

  test('executeWithContext emits the claims event with the best entity id',
      () async {
    var s = build(_Mode.claimsWithSubject);
    await s.skill.executeWithContext(ctx(userId: 'user'));
    await settle();
    expect(events.whereType<ClaimsRecordedEvent>().single.entityId, 'user');

    s = build(_Mode.claimsWithSubject);
    await s.skill.executeWithContext(ctx());
    await settle();
    expect(events.whereType<ClaimsRecordedEvent>().single.entityId, 'subj');

    s = build(_Mode.claimsNoSubject);
    await s.skill.executeWithContext(ctx(inputs: {'entityId': 'from-input'}));
    await settle();
    expect(
        events.whereType<ClaimsRecordedEvent>().single.entityId, 'from-input');

    s = build(_Mode.claimsNoSubject);
    await s.skill.executeWithContext(ctx(inputs: {'entityId': ''}));
    await settle();
    expect(events.whereType<ClaimsRecordedEvent>().single.entityId, '');
  });
}
