# MCP Knowledge

## Support This Project

If you find this package useful, consider supporting ongoing development on PayPal.

[![Donate](https://www.paypalobjects.com/en_US/i/btn/btn_donate_LG.gif)](https://www.paypal.com/ncp/payment/F7G56QD9LSJ92)
Support makemind via [PayPal](https://www.paypal.com/ncp/payment/F7G56QD9LSJ92)

---

### MCP Knowledge Package Family

- [`mcp_bundle`](https://pub.dev/packages/mcp_bundle): Bundle schema, loader, validator, and expression language for MCP ecosystem.
- [`mcp_fact_graph`](https://pub.dev/packages/mcp_fact_graph): Temporal knowledge graph with evidence-based fact management and summarization.
- [`mcp_skill`](https://pub.dev/packages/mcp_skill): Skill definitions and runtime execution for AI capabilities.
- [`mcp_profile`](https://pub.dev/packages/mcp_profile): Profile definitions for AI personas with template rendering and appraisal.
- [`mcp_knowledge_ops`](https://pub.dev/packages/mcp_knowledge_ops): Knowledge operations including pipelines, workflows, and scheduling.
- [`mcp_knowledge`](https://pub.dev/packages/mcp_knowledge): Unified integration package for the complete knowledge system.

---

The unified integration package for the MCP knowledge ecosystem. Provides a single entry point for managing facts, skills, profiles, and knowledge operations with a clean, facade-based API.

## Features

### Unified System
- **Single Entry Point**: `KnowledgeSystem` integrates all subsystems
- **Simplified Facades**: Clean API for common operations
- **Cross-Package Bridges**: Seamless integration between packages
- **Event-Driven Architecture**: Real-time event notifications

### Facades
- **FactFacade**: Simplified fact and evidence operations
- **SkillFacade**: Easy skill execution with claim recording
- **ProfileFacade**: Profile rendering with context injection
- **BundleFacade**: Bundle loading and deployment

### Bridges
- **SkillFactBridge**: Connect skill outputs to fact graph
- **ProfileFactBridge**: Inject fact context into profiles
- **BundleSystemBridge**: Deploy bundles across all subsystems

### Events
- **Fact Events**: FactConfirmed, CandidateCreated, SummaryRefreshed
- **Skill Events**: SkillExecuted, ClaimsRecorded
- **Profile Events**: ProfileRendered
- **System Events**: BundleLoaded, PipelineCompleted, SystemShutdown

## Quick Start

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  mcp_knowledge: ^0.1.0
```

### Basic Usage

```dart
import 'package:mcp_knowledge/mcp_knowledge.dart';

void main() async {
  // Create knowledge system
  final system = KnowledgeSystem(
    config: KnowledgeConfig.defaults,
    ports: KnowledgePorts.stub(),
  );

  // Use skill facade
  final skillOutput = await system.skill.run(
    'preference_extractor',
    {'conversation': 'I prefer dark mode'},
  );

  // Use profile facade
  final systemPrompt = await system.profile.getSystemPrompt(
    'friendly_assistant',
    entityId: 'user_123',
  );

  // Use fact facade
  await system.facts.ingest(
    'User mentioned preference for dark mode',
    sourceType: 'conversation',
  );

  // Listen to events
  system.eventBus.on<FactConfirmedEvent>().listen((event) {
    print('Fact confirmed: ${event.factId}');
  });

  // Graceful shutdown
  await system.shutdown();
}
```

## Core Concepts

### KnowledgeSystem

The central class that integrates all subsystems:

```dart
final system = KnowledgeSystem(
  config: KnowledgeConfig(
    workspaceId: 'my_workspace',
    factGraph: FactGraphConfig(
      candidateAutoConfirmThreshold: 0.95,
    ),
    skill: SkillConfig(
      defaultTimeout: Duration(minutes: 5),
    ),
    profile: ProfileConfig(
      enableAppraisalByDefault: true,
    ),
    features: FeatureFlags(
      enableAutoSummarization: true,
    ),
  ),
  ports: KnowledgePorts(
    storage: myStoragePort,
    llm: myLlmPort,
    mcp: myMcpPort,
    evidence: myEvidencePort,
    expression: myExpressionPort,
  ),
);
```

### Facades

Simplified APIs for common operations:

```dart
// Skill Facade
final output = await system.skill.run<Map<String, dynamic>>(
  'analyzer',
  {'text': 'Hello world'},
);

// Profile Facade
final prompt = await system.profile.getSystemPrompt(
  'assistant',
  entityId: 'user_123',
  additionalContext: {'task': 'help with code'},
);

// Fact Facade
final result = await system.facts.ingest(
  'User is a software developer',
  sourceType: 'conversation',
  metadata: {'conversationId': 'conv_001'},
);

// Bundle Facade
await system.bundle.loadAndDeploy('my_bundle.mcpb');
```

### Event Bus

Real-time event notifications:

```dart
// Listen to specific events
system.eventBus.on<SkillExecutedEvent>().listen((event) {
  print('Skill ${event.skillId} executed in ${event.duration}');
});

system.eventBus.on<FactConfirmedEvent>().listen((event) {
  print('Fact ${event.factId} confirmed');
});

// Subscribe with handler
final subscription = system.eventBus.subscribe<ProfileRenderedEvent>(
  (event) => print('Profile ${event.profileId} rendered'),
);
```

### Configuration

Hierarchical configuration for all subsystems:

```dart
// Development configuration
final devConfig = KnowledgeConfig.development;

// Production configuration
final prodConfig = KnowledgeConfig.production;

// Custom configuration
final customConfig = KnowledgeConfig(
  workspaceId: 'prod_workspace',
  factGraph: FactGraphConfig(
    enableConsistencyCheck: true,
    summaryRefreshInterval: Duration(hours: 12),
  ),
  scheduler: SchedulerConfig(
    enabled: true,
    maxConcurrentJobs: 10,
  ),
  logging: LoggingConfig(
    level: LogLevel.warning,
    enableAuditLog: true,
  ),
);
```

### Ports

Unified port container for all dependencies:

```dart
// Create ports
final ports = KnowledgePorts(
  storage: PostgresStoragePort(connectionString),
  llm: ClaudePort(apiKey: 'your-api-key'),
  mcp: McpClientPort(client),
  evidence: LlmEvidencePort(llm),
  expression: MustacheExpressionPort(),
);

// Use stub ports for testing
final testPorts = KnowledgePorts.stub();
```

## Bridges

### SkillFactBridge

Connect skill execution to fact recording:

```dart
final bridge = system.skillFactBridge;

// Execute and record claims
final result = await bridge.executeAndRecord(
  'preference_extractor',
  {'conversation': 'I like dark mode'},
  entityId: 'user_123',
  autoConfirm: false,
);

print('Claims: ${result.claimIds}');
```

### ProfileFactBridge

Inject fact context into profile rendering:

```dart
final bridge = system.profileFactBridge;

// Render with full context
final result = await bridge.renderWithContext(
  'assistant',
  entityId: 'user_123',
  domains: ['preferences', 'history'],
);

print('System Prompt: ${result.content}');
print('Facts used: ${result.factIds}');
```

## API Reference

### KnowledgeSystem

| Property | Description |
|----------|-------------|
| `config` | System configuration |
| `ports` | External dependency ports |
| `eventBus` | Event bus for notifications |
| `facts` | Fact facade |
| `skill` | Skill facade |
| `profile` | Profile facade |
| `bundle` | Bundle facade |

| Method | Description |
|--------|-------------|
| `loadBundle(bundle)` | Load and deploy a bundle |
| `executeSkill(skillId, inputs)` | Execute a skill |
| `renderProfile(profileId, entityId)` | Render a profile |
| `runCuration(input)` | Run curation pipeline |
| `runSummarization(input)` | Run summarization |
| `shutdown()` | Graceful shutdown |

## Examples

### Complete Examples Available
- `example/basic_system.dart` - Basic system setup
- `example/facades.dart` - Using facades
- `example/events.dart` - Event handling
- `example/bridges.dart` - Bridge usage
- `example/full_workflow.dart` - Complete workflow

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    KnowledgeSystem                          │
├─────────────────────────────────────────────────────────────┤
│  ┌───────────┐  ┌───────────┐  ┌───────────┐  ┌──────────┐ │
│  │FactFacade │  │SkillFacade│  │ProfileFac │  │BundleFac │ │
│  └─────┬─────┘  └─────┬─────┘  └─────┬─────┘  └────┬─────┘ │
│        │              │              │             │        │
│  ┌─────┴──────────────┴──────────────┴─────────────┴─────┐ │
│  │                      Bridges                          │ │
│  │  SkillFactBridge │ ProfileFactBridge │ BundleSystem   │ │
│  └───────────────────────────────────────────────────────┘ │
│                           │                                 │
│  ┌───────────────────────────────────────────────────────┐ │
│  │                    EventBus                           │ │
│  └───────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌───────────────┐  │
│  │FactGraph │ │  Skill   │ │ Profile  │ │ KnowledgeOps  │  │
│  │ Service  │ │ Runtime  │ │ Runtime  │ │  Pipelines    │  │
│  └──────────┘ └──────────┘ └──────────┘ └───────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                    KnowledgePorts                           │
│  Storage │ LLM │ MCP │ Evidence │ Expression                │
└─────────────────────────────────────────────────────────────┘
```

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## Support

- [Documentation](https://github.com/app-appplayer/mcp_knowledge/wiki)
- [Issue Tracker](https://github.com/app-appplayer/mcp_knowledge/issues)
- [Discussions](https://github.com/app-appplayer/mcp_knowledge/discussions)
- [Support on Patreon](https://www.patreon.com/mcpdevstudio)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
