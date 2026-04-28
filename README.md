# MCP Knowledge

`mcp_knowledge` is the **orchestration facade** for the MakeMind knowledge stack. It does not own ports, bridges, or business logic — it composes the runtimes provided by the other `mcp_*` packages and exposes them through a clean, facade-based API.

## What `mcp_knowledge` provides

- **`KnowledgeSystem`** — single entry point. Owns five facades and the event bus, carries the optional runtimes.
- **`KnowledgePorts`** — flat container of 32 capability-named standard ports from `mcp_bundle`. Every field is optional.
- **`KnowledgeConfig`** — hierarchical immutable configuration with three presets (`defaults`, `development`, `production`).
- **5 thin facades** — `FactFacade`, `SkillFacade`, `ProfileFacade`, `PhilosophyFacade`, `OpsFacade`.
- **`KnowledgeEventBus`** + 13 typed event classes for reactive observability.

## What `mcp_knowledge` does NOT provide

- ❌ No port abstractions of its own — the standard ports live in `mcp_bundle`.
- ❌ No bridges — cross-domain wiring is the host's responsibility at runtime construction time.
- ❌ No raw-accessor adapters — runtimes expose their own adapters.
- ❌ No bundle file parsing — bundle handling is now an `OpsRuntime` workflow concern.
- ❌ No inline pipeline implementation — pipeline execution is delegated to `OpsRuntime` via `system.ops.runPipeline`.

## Quick start

### Scenario A — fact graph standalone

```dart
import 'package:mcp_knowledge/mcp_knowledge.dart';

void main() async {
  final factGraph = FactGraphRuntime.inMemory();
  await factGraph.initialize();

  final system = KnowledgeSystem(
    config: KnowledgeConfig.defaults,
    ports: KnowledgePorts(facts: factGraph.facts),
    factGraph: factGraph,
  );

  await system.facts.writeFacts([
    FactRecord(
      id: 'f1',
      workspaceId: 'default',
      type: 'observation',
      entityId: 'user-1',
      content: const {'value': 42},
      createdAt: DateTime.now(),
    ),
  ]);

  final results = await system.facts.queryFacts(
    const FactQuery(workspaceId: 'default', entityId: 'user-1'),
  );
  print('Found ${results.length} facts');

  await system.shutdown();
}
```

### Scenario G — full orchestration

```dart
final factGraph = FactGraphRuntime.inMemory();
await factGraph.initialize();

final skillRuntime = SkillRuntime(
  registry: MemorySkillRegistry(),
  ports: SkillPorts(
    llm: StubLlmPort(),
    mcp: const StubMcpPort(),
    facts: factGraph.facts,
    claims: factGraph.claims,
  ),
);

final profileRuntime = ProfileRuntime(
  registry: ProfileRegistry(),
  engines: EnginePorts.stub(),
);

final philosophyEngine = PhilosophyEngine(
  ethosStore: const StubEthosStorePort(),
  facts: factGraph.facts,
);

final opsRuntime = OpsRuntime.fromConsumedPorts(ConsumedOpsPorts(
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

final system = KnowledgeSystem(
  config: KnowledgeConfig.defaults,
  ports: KnowledgePorts(facts: factGraph.facts, claims: factGraph.claims),
  factGraph: factGraph,
  skillRuntime: skillRuntime,
  profileRuntime: profileRuntime,
  philosophyEngine: philosophyEngine,
  opsRuntime: opsRuntime,
);

// Every facade is now isAvailable.
final result = await system.skill.execute('my_skill', {'input': 'hello'});
final apply = await system.profile.apply('my_profile', entityId: 'e1');
final workflows = await system.ops.listWorkflows();

await system.shutdown();
```

### Scenario H — partial orchestration

```dart
final system = KnowledgeSystem(
  config: KnowledgeConfig.defaults,
  factGraph: factGraph,
  profileRuntime: profileRuntime,
  // skillRuntime / philosophyEngine / opsRuntime intentionally omitted
);

print(system.profile.isAvailable);    // true
print(system.skill.isAvailable);      // false
print(system.philosophy.isAvailable); // false
print(system.ops.isAvailable);        // false

// Calling an unavailable facade method throws StateError eagerly:
try {
  await system.skill.execute('any', const {});
} on StateError catch (e) {
  print(e.message);  // "SkillRuntime not configured — pass `skillRuntime: ...` …"
}
```

## Facades

### FactFacade

Thin wrapper over the fact-graph standard ports. Resolves each capability port from `system.factGraph` first, then `system.ports`.

```dart
await system.facts.writeFacts([fact]);
final facts = await system.facts.queryFacts(FactQuery(workspaceId: 'ws'));
await system.facts.confirmCandidate('c1');
await system.facts.refreshSummary('e1', 'overview');
```

### SkillFacade

Thin wrapper over `mcp_skill.SkillRuntime`. Builds a `SkillContext` and delegates to `runtime.run()` so the full 7-step pipeline runs.

```dart
final result = await system.skill.execute(
  'my_skill',
  {'input': 'hello'},
  entityId: 'user_123',
);
```

### ProfileFacade

Thin wrapper over `mcp_profile.ProfileRuntime`. Builds a `RuntimeProfileContext` and delegates to `runtime.apply()` so the full 3-pillar pipeline (Appraisal → Decision → Expression) runs.

```dart
final result = await system.profile.apply(
  'my_profile',
  entityId: 'user_123',
  rawContent: 'optional content to format',
);
```

### PhilosophyFacade

Thin wrapper over `mcp_philosophy.PhilosophyEngine` (or a bare `PhilosophyPort` from `KnowledgePorts`). Honors the per-intervention-point gates in `config.philosophy`.

```dart
final guidance = await system.philosophy.evaluate(context);
final tensions = await system.philosophy.detectTensions(multiLayerContext);
```

### OpsFacade

Thin wrapper over `mcp_knowledge_ops.OpsRuntime`'s workflow / pipeline / runbook ports. Replaces the legacy `BundleFacade` from 0.1.0.

```dart
final workflows = await system.ops.listWorkflows();
final handle = await system.ops.runWorkflow('skill_build', input);
final pipelineHandle = await system.ops.runPipeline('curation_pipeline', input);
final runbookExecution = await system.ops.runRunbook('my_runbook', input);
```

## Event bus

Real-time event notifications:

```dart
system.eventBus.on<SkillExecutedEvent>().listen((event) {
  print('Skill ${event.skillId} executed in ${event.duration}');
});

system.eventBus.on<ProfileAppliedEvent>().listen((event) {
  print('Profile ${event.profileId} applied → ${event.decision}');
});
```

13 event classes are available: `FactConfirmedEvent`, `CandidateCreatedEvent`, `SummaryRefreshedEvent`, `SkillExecutedEvent`, `ClaimsRecordedEvent`, `ProfileAppliedEvent`, `BundleLoadedEvent`, `PipelineCompletedEvent`, `SystemShutdownEvent`, `PhilosophyEvaluatedEvent`, `TensionDetectedEvent`, `ProhibitionViolatedEvent`, `EvolutionProposedEvent`.

## Configuration

```dart
// Three presets
final defaults = KnowledgeConfig.defaults;
final dev = KnowledgeConfig.development;
final prod = KnowledgeConfig.production;

// Custom configuration via copyWith
final config = KnowledgeConfig.defaults.copyWith(
  workspaceId: 'tenant_42',
  philosophy: PhilosophyConfig(
    enabled: true,
    enableTensionDetection: true,
    minConfidenceThreshold: 0.7,
  ),
);
```

## Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                        KnowledgeSystem                               │
├──────────────────────────────────────────────────────────────────────┤
│  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌────────┐  │
│  │FactFacade │ │SkillFacade│ │ProfileFac.│ │Philosophy │ │OpsFac. │  │
│  └─────┬─────┘ └─────┬─────┘ └─────┬─────┘ └─────┬─────┘ └───┬────┘  │
│        │             │             │              │           │      │
│  ┌─────┴─────────────┴─────────────┴──────────────┴───────────┴────┐ │
│  │                       KnowledgeEventBus                        │ │
│  └────────────────────────────────────────────────────────────────┘ │
├──────────────────────────────────────────────────────────────────────┤
│         Optional runtimes (host constructs and injects)              │
│  FactGraphRuntime │ SkillRuntime │ ProfileRuntime                    │
│  PhilosophyEngine │ OpsRuntime                                       │
├──────────────────────────────────────────────────────────────────────┤
│       KnowledgePorts — flat 32-field standard-port container         │
│  facts/claims/entities/candidates/evidence/patterns/summaries/...    │
│  skillRuntime/skillRegistry/mcp/llm                                  │
│  metrics/appraisal/decision/expression/profileSummaries              │
│  philosophy/ethosStore                                               │
│  workflow/pipeline/scheduler/audit/runbook                           │
│  kvStorage/approval/notification/event/metric                        │
└──────────────────────────────────────────────────────────────────────┘
```

## Support

- [Issue Tracker](https://github.com/app-appplayer/mcp_knowledge/issues)
- [Discussions](https://github.com/app-appplayer/mcp_knowledge/discussions)

## License

MIT — see [LICENSE](LICENSE).
