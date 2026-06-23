## [0.2.5] - 2026-06-23 - prohibition-enforcement floor guarantee (dependency-only)

### Changed (dependency floor)
- `mcp_philosophy` `^0.1.1` → `^0.1.2` — **guarantees** the deterministic prohibition enforcement (`Prohibition.forbiddenPatterns`, mcp_philosophy 0.1.2) is present in the wired `PhilosophyEngine`, rather than relying on caret-resolves-to-latest. mcp_knowledge owns the `mcp_philosophy` dependency that brings the engine into consumers' graphs (flowbrain_core etc.), so the floor belongs here. Without it a consumer could resolve mcp_philosophy 0.1.1 and the `bk.philosophy.check` / work-time §3 gate would silently fall open for any prohibition outside the two built-in heuristics.
- `mcp_bundle` `^0.4.0` → `^0.4.4` — internal-dep latest (0.4.4 carries `Prohibition.forbiddenPatterns` + Ethos `fromJson` field-named validation).
- No code change — floor-only release.

## [0.2.4] - 2026-05-30 - OpsFacade behavior execution (additive)

### Added
- `OpsFacade.runBehavior(id, {runId, input})` / `resumeBehavior(id, runId, {statePatch})` / `listBehaviors()` — execute / resume / list behavior definitions registered in `OpsRuntime.behaviorRegistry` (the unified "behavior definition" engine). Returns a plain `Map<String, dynamic>` (`runId` · `status` · optional `waitingStepId` / `error`) so callers need no mcp_knowledge_ops types. `resumeBehavior` merges the optional `statePatch` into the run state before re-evaluating the waiting guard (the approval/unblock path). Keeps behavior execution on the facade layer alongside `runWorkflow` / `runRunbook`, so kernels and tools route through `system.ops.runBehavior` instead of reaching into `mcp_knowledge_ops` directly.

### Changed (dependency floor)
- `mcp_knowledge_ops` `^0.2.1` → `^0.2.2` — the behavior engine (`BehaviorRunnable` · `OpsRuntime.behaviorRegistry` · `EngineResult`) lives in 0.2.2; the floor is raised so those symbols are guaranteed, not merely resolved.

### Backward compatibility
- Additive only. No existing API or behavior changed.

## [0.2.3] - 2026-05-23 - mcp_bundle 0.4.0 + sibling cascade

### Changed (cascade)
- `mcp_bundle` `^0.3.2` → `^0.4.0` (UiSection.pages spec realignment, see mcp_bundle 0.4.0).
- `mcp_fact_graph` `^0.2.1` → `^0.2.2`.
- `mcp_skill` `^0.2.0` → `^0.2.1`.
- `mcp_profile` `^0.2.0` → `^0.2.1`.
- `mcp_philosophy` `^0.1.0` → `^0.1.1`.
- `mcp_knowledge_ops` `^0.2.0` → `^0.2.1`.

mcp_knowledge does not touch `UiSection.pages` directly — caret-only cascade. Consumers should bump to `^0.2.3`.

## [0.2.2] - 2026-05-07 - Cascade `mcp_bundle ^0.3.2`

### Dependencies
- `mcp_bundle: ^0.3.1` → `^0.3.2` — cascade alignment to pick up the new `McpBundle.factGraphSection` wire (additive — fact instance round-trip slot alongside the existing `factGraphSchema` type catalogue). No code changes in `mcp_knowledge` itself; downstream consumers that round-trip bundles with embedded fact instance data through `mcp_knowledge`'s facades / bridges now resolve against the new wire.

---

## [0.2.1] - 2026-05-04 - Multi-ethos resolution & graceful profile listing

### Added
- `PhilosophyFacade.getEthosById(String? id)` — id-based ethos resolution against the wired `EthosStorePort` with a graceful fallback to the active ethos. Multi-ethos workspaces (e.g. `ads-core` vs `editorial-core`) can now fork from a specific ethos id without bypassing the facade.

### Changed
- `ProfileFacade.list()` returns an empty list when no `ProfileRuntime` is wired instead of raising `StateError`. Mutating operations (`register`, `unregister`, `get`, `apply`) still raise `StateError`. Read-only enumeration is now safe to call unconditionally.

### Dependencies
- `mcp_bundle: ^0.3.1` — for `EthosRecord.fromJson` used by `getEthosById` to reconstruct ethos payloads round-tripped through persistent stores.
- `mcp_fact_graph: ^0.2.1` — propagates the upstream `ConsistencyChecker._periodsOverlap` bug fix (calendar-day → microsecond precision) so consumers that pin `mcp_knowledge` exactly receive the fix transitively.

---

## [0.2.0] - 2026-04-28 - Orchestrator-Only Redesign

### Changed (breaking)
- `mcp_knowledge` is now **orchestrator-only** — no port definitions or wrappers; composes runtimes from `mcp_fact_graph` / `mcp_skill` / `mcp_profile` / `mcp_philosophy` / `mcp_knowledge_ops`.
- `KnowledgeSystem` constructor accepts five optional runtimes (`factGraph`, `skillRuntime`, `profileRuntime`, `philosophyEngine`, `opsRuntime`). Partial orchestration supported via `null`.
- `KnowledgePorts` is a flat 32-field container of `mcp_bundle` standard ports (legacy `CollectionStoragePort` removed).
- Facade methods (`SkillFacade.execute`, `ProfileFacade.apply`, `FactFacade`, `PhilosophyFacade`) delegate to real runtimes; 0.1.0 stand-ins are gone.
- New dependency: `mcp_bundle ^0.3.0`.

### Added
- `OpsFacade` wrapping `OpsRuntime`'s workflow / pipeline / runbook ports (replaces `BundleFacade`).
- `KnowledgeSystem.stub()` convenience factory.

### Removed
- Six bridges (`skill_fact`, `profile_fact`, `bundle_system`, `philosophy_skill/profile/fact`) and five raw-accessor adapters — replaced by Contract Layer port wiring inside the runtimes.
- `BundleFacade` — bundle deployment is now an `OpsRuntime` workflow concern.
- `KnowledgeSystem.runCuration / runSummarization / runPatternMining / loadBundle / executeSkill / applyProfile / executePipeline / executeWorkflow / resumeFromCheckpoint` — delegated to `system.ops.*` / `system.skill.*` / `system.profile.*`.

---

## [0.1.0] - Initial Release

### Added

#### Core Features
- **KnowledgeSystem**
  - Unified entry point for all knowledge operations
  - Configuration management with `KnowledgeConfig`
  - Port-based dependency injection with `KnowledgePorts`
  - Graceful shutdown and lifecycle management

- **Facades**
  - `FactFacade` for simplified fact operations
  - `SkillFacade` for skill execution
  - `ProfileFacade` for profile rendering
  - `BundleFacade` for bundle management

- **Bridges**
  - `SkillFactBridge` for connecting skill outputs to fact graph
  - `ProfileFactBridge` for injecting fact context into profiles
  - `BundleSystemBridge` for deploying bundles across subsystems

- **Event System**
  - `KnowledgeEventBus` for event distribution
  - Typed event streams with `on<T>()` method
  - Event subscription with handlers

- **Events**
  - `FactConfirmedEvent` - when a candidate becomes a fact
  - `CandidateCreatedEvent` - when a new candidate is created
  - `SummaryRefreshedEvent` - when a summary is updated
  - `SkillExecutedEvent` - when a skill completes
  - `ClaimsRecordedEvent` - when claims are recorded
  - `ProfileRenderedEvent` - when a profile is rendered
  - `BundleLoadedEvent` - when a bundle is deployed
  - `PipelineCompletedEvent` - when a pipeline finishes
  - `SystemShutdownEvent` - when system shuts down

- **Configuration**
  - `KnowledgeConfig` with hierarchical settings
  - `FactGraphConfig` for fact graph settings
  - `SkillConfig` for skill execution settings
  - `ProfileConfig` for profile rendering settings
  - `SchedulerConfig` for scheduling settings
  - `EventConfig` for event system settings
  - `LoggingConfig` for logging settings
  - `FeatureFlags` for feature toggles
  - Preset configurations: `defaults`, `development`, `production`

- **Ports**
  - `KnowledgePorts` unified port container
  - `StoragePort` for data persistence
  - `LlmPort` for LLM integration
  - `McpPort` for MCP communication
  - `EvidencePort` for evidence processing
  - `ExpressionPort` for template evaluation
  - Stub implementations for testing

- **Adapters**
  - `SkillPortsAdapter` for skill port conversion
  - `ProfilePortsAdapter` for profile port conversion
  - `FactGraphPortsAdapter` for fact graph port conversion

### Integration
- Integrates `mcp_bundle` for bundle management
- Integrates `mcp_fact_graph` for knowledge storage
- Integrates `mcp_skill` for AI capabilities
- Integrates `mcp_profile` for AI personas
- Integrates `mcp_knowledge_ops` for operations

### Architecture
- Facade pattern for simplified APIs
- Bridge pattern for cross-package integration
- Event-driven architecture for loose coupling
- Port-based dependency injection

---

## Support and Contributing

- [Report Issues](https://github.com/app-appplayer/mcp_knowledge/issues)
- [Join Discussions](https://github.com/app-appplayer/mcp_knowledge/discussions)
- [Read Documentation](https://github.com/app-appplayer/mcp_knowledge/wiki)
- [Support Development](https://www.patreon.com/mcpdevstudio)
