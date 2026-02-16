/// MCP Knowledge - Unified Knowledge Management System for MakeMind.
///
/// Integrates mcp_bundle, mcp_fact_graph, mcp_skill, mcp_profile,
/// and mcp_knowledge_ops into a single cohesive system.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:mcp_knowledge/mcp_knowledge.dart';
///
/// void main() async {
///   final system = KnowledgeSystem(
///     config: KnowledgeConfig.defaults,
///     ports: KnowledgePorts.stub(),
///   );
///
///   // Use facades
///   await system.skill.run('my_skill', {'input': 'value'});
///   final prompt = await system.profile.getSystemPrompt(
///     'assistant',
///     entityId: 'user_123',
///   );
/// }
/// ```
library mcp_knowledge;

// === Core System ===
export 'src/system/knowledge_system.dart';
export 'src/system/knowledge_config.dart';
export 'src/system/knowledge_ports.dart';

// === Facades ===
export 'src/facade/fact_facade.dart';
export 'src/facade/skill_facade.dart';
export 'src/facade/profile_facade.dart';
export 'src/facade/bundle_facade.dart';

// === Bridges ===
export 'src/bridge/skill_fact_bridge.dart';
export 'src/bridge/profile_fact_bridge.dart';
export 'src/bridge/bundle_system_bridge.dart';

// === Events ===
export 'src/events/knowledge_event.dart';
export 'src/events/event_bus.dart';

// === Adapters ===
export 'src/adapters/skill_ports_adapter.dart';
export 'src/adapters/profile_ports_adapter.dart';
export 'src/adapters/fact_graph_ports_adapter.dart';

// NOTE: Re-exports from underlying packages will be added
// when full implementation connects to actual subsystems.
// For now, this is a design-phase standalone package.
