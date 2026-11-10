/// PhilosophyFacade: events, per-point gating, error wrapping and the state
/// adjustment, driven by a scripted PhilosophyPort.
library;

import 'package:mcp_knowledge/mcp_knowledge.dart';
import 'package:test/test.dart';

final _guidance = PhilosophyGuidance(
  prohibitionChecks: ProhibitionCheckResult.allPassed(const []),
  recommendedAction: 'proceed',
  confidence: 0.8,
  explanation: 'fine',
  prohibitionViolated: false,
);

final _ethos = Ethos(
  id: 'e1',
  name: 'E',
  valuePriorities: const [],
  prohibitions: const [],
  metadata: EthosMetadata(
      version: '1',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026)),
);

final _tension = Tension(
  id: 't1',
  source: const TensionSource(opposingLayer: TensionLayer.profile),
  philosophyDirective: 'a',
  opposingDirective: 'b',
  severity: TensionSeverity.high,
  description: 'd',
);

final _proposal = EvolutionProposal(
  id: 'ev1',
  ethosId: 'e1',
  type: EvolutionType.reinforce,
  targetComponentId: 'c',
  targetComponentType: 'valuePriority',
  description: 'd',
  rationale: 'because',
  confidence: 0.7,
);

final _feedback = FeedbackEvent(
  id: 'f1',
  actionId: 'a',
  ethosId: 'e1',
  outcome: FeedbackOutcome.positive,
  outcomeScore: 1,
);

class _Port implements PhilosophyPort {
  bool fail = false;
  bool violated = false;
  int interventions = 0;

  void _maybeFail() {
    if (fail) throw const PhilosophyException('scripted failure');
  }

  @override
  Future<PhilosophyGuidance> evaluate(PhilosophyEvaluationContext c) async {
    _maybeFail();
    return _guidance;
  }

  @override
  Future<ProhibitionCheckResult> checkProhibitions(
      ProhibitionCheckRequest r) async {
    _maybeFail();
    return ProhibitionCheckResult(
      checks: [
        ProhibitionCheck(
            prohibitionId: 'p1',
            violated: violated,
            severity: ProhibitionSeverity.hard,
            violationDetail: violated ? null : 'unused'),
        const ProhibitionCheck(
            prohibitionId: 'p2',
            violated: true,
            severity: ProhibitionSeverity.soft,
            violationDetail: 'detail'),
      ],
      hasHardViolation: violated,
    );
  }

  @override
  Future<InterventionResult> intervene(
      InterventionPoint point, PipelineContext context) async {
    _maybeFail();
    interventions++;
    return InterventionResult(point: point);
  }

  @override
  Future<Ethos> getEthos() async {
    _maybeFail();
    return _ethos;
  }

  @override
  Future<List<Tension>> detectTensions(MultiLayerContext context) async {
    _maybeFail();
    return [_tension];
  }

  @override
  Future<EvolutionProposal?> proposeFeedback(FeedbackEvent event) async {
    _maybeFail();
    return event.id == 'none' ? null : _proposal;
  }
}

final _multi = MultiLayerContext(
    philosophyContext: PhilosophyEvaluationContext(contextId: 'c'));

void main() {
  late _Port port;
  late KnowledgeSystem system;
  late List<KnowledgeEvent> events;

  KnowledgeSystem build(PhilosophyConfig cfg) {
    final s = KnowledgeSystem(
      config: KnowledgeConfig(workspaceId: 'w', philosophy: cfg),
      ports: KnowledgePorts(philosophy: port),
    );
    events = [];
    s.eventBus.stream.listen(events.add);
    addTearDown(s.shutdown);
    return s;
  }

  setUp(() {
    port = _Port();
    system = build(const PhilosophyConfig(enableEvolution: true));
  });

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 5));

  final ctx = PhilosophyEvaluationContext(contextId: 'c1');
  final request = ProhibitionCheckRequest();
  final pipeline = PipelineContext(
      pipelineId: 'p', currentPoint: InterventionPoint.preGeneration);

  test('without a port the facade is unavailable and refuses', () {
    final s = KnowledgeSystem(config: KnowledgeConfig.defaults);
    addTearDown(s.shutdown);
    expect(s.philosophy.isAvailable, isFalse);
    expect(s.philosophy.system, same(s));
    expect(() => s.philosophy.getEthos(), throwsStateError);
  });

  test('evaluate emits PhilosophyEvaluatedEvent', () async {
    expect(system.philosophy.isAvailable, isTrue);
    expect(system.philosophy.system, same(system));
    expect(await system.philosophy.evaluate(ctx), same(_guidance));
    await settle();
    final e = events.whereType<PhilosophyEvaluatedEvent>().single;
    expect(e.type, 'philosophy_evaluated');
    expect(e.contextId, 'c1');
    expect(e.confidence, 0.8);
    expect(e.prohibitionViolated, isFalse);
    expect(e.recommendedAction, 'proceed');
  });

  test('checkProhibitions emits one event per violated check', () async {
    port.violated = true;
    await system.philosophy.checkProhibitions(request);
    await settle();
    final e = events.whereType<ProhibitionViolatedEvent>().toList();
    expect(e.map((x) => x.prohibitionId), ['p1', 'p2']);
    expect(e.first.detail, 'Prohibition violated'); // no detail given
    expect(e.last.detail, 'detail');
    expect(e.first.isHard, isTrue);
    expect(e.first.type, 'prohibition_violated');
    expect(e.first.severity, 'hard');
  });

  test('intervene honours the enable flags of each point', () async {
    final all = await system.philosophy
        .intervene(InterventionPoint.preGeneration, pipeline);
    expect(all.point, InterventionPoint.preGeneration);
    expect(port.interventions, 1);

    system = build(const PhilosophyConfig(enabled: false));
    await system.philosophy
        .intervene(InterventionPoint.preGeneration, pipeline);
    system = build(const PhilosophyConfig(
        enablePreGeneration: false,
        enableDuringGeneration: false,
        enablePostGeneration: false));
    for (final p in InterventionPoint.values) {
      await system.philosophy.intervene(p, pipeline);
    }
    expect(port.interventions, 1); // nothing more ran
    system = build(const PhilosophyConfig(enableEvolution: true));
    await system.philosophy
        .intervene(InterventionPoint.duringGeneration, pipeline);
    await system.philosophy
        .intervene(InterventionPoint.postGeneration, pipeline);
    await system.philosophy.intervene(InterventionPoint.unknown, pipeline);
    expect(port.interventions, 3); // unknown is never run
  });

  test('tensions: event per tension; off by a flag', () async {
    expect(await system.philosophy.detectTensions(_multi), hasLength(1));
    await settle();
    final e = events.whereType<TensionDetectedEvent>().single;
    expect(e.type, 'tension_detected');
    expect(e.tensionId, 't1');
    expect(e.severity, 'high');
    expect(e.layer, 'profile');
    expect(e.philosophyDirective, 'a');
    expect(e.opposingDirective, 'b');
    system = build(const PhilosophyConfig(enableTensionDetection: false));
    expect(await system.philosophy.detectTensions(_multi), isEmpty);
  });

  test('evolution: proposal event; none when null; off by a flag', () async {
    expect(await system.philosophy.proposeFeedback(_feedback), same(_proposal));
    await settle();
    final e = events.whereType<EvolutionProposedEvent>().single;
    expect(e.type, 'evolution_proposed');
    expect(e.proposalId, 'ev1');
    expect(e.ethosId, 'e1');
    expect(e.evolutionType, 'reinforce');
    expect(e.confidence, 0.7);
    expect(e.description, 'because');
    final none = FeedbackEvent(
        id: 'none',
        actionId: 'a',
        ethosId: 'e1',
        outcome: FeedbackOutcome.neutral,
        outcomeScore: 0);
    expect(await system.philosophy.proposeFeedback(none), isNull);
    system = build(const PhilosophyConfig());
    expect(await system.philosophy.proposeFeedback(_feedback), isNull);
  });

  test('evaluateAndAdjust returns the guidance and its adjustment', () async {
    final (guidance, impact) = await system.philosophy
        .evaluateAndAdjust(ctx, const StateWeighting(urgency: 0.9));
    expect(guidance, isNotNull);
    expect(impact, isNotNull);
  });

  test('a PhilosophyException is wrapped, with its cause', () async {
    port.fail = true;
    final calls = <String, Future<Object?> Function()>{
      'evaluate': () => system.philosophy.evaluate(ctx),
      'checkProhibitions': () => system.philosophy.checkProhibitions(request),
      'intervene': () => system.philosophy
          .intervene(InterventionPoint.preGeneration, pipeline),
      'getEthos': () => system.philosophy.getEthos(),
      'detectTensions': () => system.philosophy.detectTensions(_multi),
      'proposeFeedback': () => system.philosophy.proposeFeedback(_feedback),
    };
    for (final e in calls.entries) {
      try {
        await e.value();
        fail('${e.key} should throw');
      } on PhilosophyFacadeException catch (x) {
        expect(x.message, startsWith('${e.key} failed'));
        expect(x.cause, isA<PhilosophyException>());
        expect(x.toString(), startsWith('PhilosophyFacadeException:'));
      }
    }
  });
}
