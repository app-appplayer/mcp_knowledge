/// Knowledge System - Core unified system class.
///
/// Provides single entry point for all knowledge operations.
library;

import 'knowledge_config.dart';
import 'knowledge_ports.dart';
import '../facade/fact_facade.dart';
import '../facade/skill_facade.dart';
import '../facade/profile_facade.dart';
import '../facade/bundle_facade.dart';
import '../bridge/skill_fact_bridge.dart';
import '../bridge/profile_fact_bridge.dart';
import '../bridge/bundle_system_bridge.dart';
import '../events/event_bus.dart';

/// Unified knowledge management system.
///
/// Integrates all knowledge subsystems and provides a single entry point
/// for knowledge operations.
class KnowledgeSystem {
  /// System configuration.
  final KnowledgeConfig config;

  /// External dependency ports.
  final KnowledgePorts ports;

  /// Event bus for cross-component communication.
  final KnowledgeEventBus eventBus;

  // === Facades ===

  /// Simplified fact operations.
  late final FactFacade facts;

  /// Simplified skill operations.
  late final SkillFacade skill;

  /// Simplified profile operations.
  late final ProfileFacade profile;

  /// Simplified bundle operations.
  late final BundleFacade bundle;

  // === Bridges (internal) ===

  late final SkillFactBridge _skillFactBridge;
  late final ProfileFactBridge _profileFactBridge;
  late final BundleSystemBridge _bundleSystemBridge;

  /// Create a new knowledge system.
  KnowledgeSystem({
    required this.config,
    required this.ports,
    KnowledgeEventBus? eventBus,
  }) : eventBus = eventBus ?? KnowledgeEventBus() {
    _initialize();
  }

  /// Create system with default configuration.
  factory KnowledgeSystem.defaults({
    required KnowledgePorts ports,
  }) {
    return KnowledgeSystem(
      config: KnowledgeConfig.defaults,
      ports: ports,
    );
  }

  void _initialize() {
    // Initialize bridges (placeholder)
    _skillFactBridge = SkillFactBridge(
      skillRuntime: null,
      factGraph: null,
    );
    _profileFactBridge = ProfileFactBridge(
      profileRuntime: null,
      factGraph: null,
    );
    _bundleSystemBridge = BundleSystemBridge(system: this);

    // Initialize facades
    facts = FactFacade(system: this);
    skill = SkillFacade(system: this);
    profile = ProfileFacade(system: this);
    bundle = BundleFacade(system: this);
  }

  /// Load and deploy a bundle.
  Future<BundleLoadResult> loadBundle(dynamic bundleData) async {
    // Implementation will use _bundleSystemBridge
    throw UnimplementedError('KnowledgeSystem.loadBundle not implemented');
  }

  /// Execute skill with optional claim recording.
  Future<dynamic> executeSkill(
    String skillId,
    Map<String, dynamic> inputs, {
    bool recordClaims = true,
    String? entityId,
  }) async {
    // Implementation will use skill facade and bridge
    throw UnimplementedError('KnowledgeSystem.executeSkill not implemented');
  }

  /// Render profile with entity context.
  Future<dynamic> renderProfile(
    String profileId, {
    required String entityId,
    Map<String, dynamic>? additionalContext,
  }) async {
    // Implementation will use profile facade and bridge
    throw UnimplementedError('KnowledgeSystem.renderProfile not implemented');
  }

  /// Run curation pipeline.
  Future<dynamic> runCuration({dynamic input}) async {
    throw UnimplementedError('KnowledgeSystem.runCuration not implemented');
  }

  /// Run summarization pipeline.
  Future<dynamic> runSummarization({dynamic input}) async {
    throw UnimplementedError(
        'KnowledgeSystem.runSummarization not implemented');
  }

  /// Run pattern mining pipeline.
  Future<dynamic> runPatternMining({dynamic input}) async {
    throw UnimplementedError(
        'KnowledgeSystem.runPatternMining not implemented');
  }

  /// Gracefully shutdown the system.
  Future<void> shutdown() async {
    await eventBus.close();
  }

  // Suppress unused field warnings for design phase
  SkillFactBridge get skillFactBridge => _skillFactBridge;
  ProfileFactBridge get profileFactBridge => _profileFactBridge;
  BundleSystemBridge get bundleSystemBridge => _bundleSystemBridge;
}

/// Result of loading a bundle.
class BundleLoadResult {
  /// Bundle ID.
  final String bundleId;

  /// Number of skills loaded.
  final int skillsLoaded;

  /// Number of profiles loaded.
  final int profilesLoaded;

  /// Number of knowledge items loaded.
  final int knowledgeItemsLoaded;

  /// Warnings during loading.
  final List<String> warnings;

  const BundleLoadResult({
    required this.bundleId,
    required this.skillsLoaded,
    required this.profilesLoaded,
    required this.knowledgeItemsLoaded,
    this.warnings = const [],
  });
}
