/// Skill Ports Adapter - Adapts unified ports to skill-specific ports.
library;

/// Adapter that converts KnowledgePorts to SkillPorts.
class SkillPortsAdapter {
  final dynamic _knowledgePorts;

  /// Create adapter with unified ports.
  SkillPortsAdapter({required dynamic knowledgePorts})
      : _knowledgePorts = knowledgePorts;

  /// Get storage port for skills.
  dynamic get storagePort => _knowledgePorts.storagePort;

  /// Get LLM port for skills.
  dynamic get llmPort => _knowledgePorts.llmPort;

  /// Get MCP port for skills.
  dynamic get mcpPort => _knowledgePorts.mcpPort;

  /// Convert to skill-compatible ports object.
  Map<String, dynamic> toSkillPorts() {
    return {
      'storage': storagePort,
      'llm': llmPort,
      'mcp': mcpPort,
    };
  }

  /// Create skill runtime with adapted ports.
  dynamic createSkillRuntime({
    Map<String, dynamic>? config,
  }) {
    // Implementation will create SkillRuntime with adapted ports
    throw UnimplementedError(
        'SkillPortsAdapter.createSkillRuntime not implemented');
  }
}

/// Extension for easy port access.
extension SkillPortsExtension on SkillPortsAdapter {
  /// Check if all required ports are available.
  bool get hasRequiredPorts {
    return storagePort != null && llmPort != null;
  }

  /// Check if MCP port is available.
  bool get hasMcpPort => mcpPort != null;
}
