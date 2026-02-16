/// Fact Graph Ports Adapter - Adapts unified ports to fact graph-specific ports.
library;

/// Adapter that converts KnowledgePorts to FactGraphPorts.
class FactGraphPortsAdapter {
  final dynamic _knowledgePorts;

  /// Create adapter with unified ports.
  FactGraphPortsAdapter({required dynamic knowledgePorts})
      : _knowledgePorts = knowledgePorts;

  /// Get storage port for fact graph.
  dynamic get storagePort => _knowledgePorts.storagePort;

  /// Get evidence port for evidence processing.
  dynamic get evidencePort => _knowledgePorts.evidencePort;

  /// Get LLM port for summarization.
  dynamic get llmPort => _knowledgePorts.llmPort;

  /// Convert to fact graph-compatible ports object.
  Map<String, dynamic> toFactGraphPorts() {
    return {
      'storage': storagePort,
      'evidence': evidencePort,
      'llm': llmPort,
    };
  }

  /// Create fact graph with adapted ports.
  dynamic createFactGraph({
    Map<String, dynamic>? config,
  }) {
    // Implementation will create FactGraph with adapted ports
    throw UnimplementedError(
        'FactGraphPortsAdapter.createFactGraph not implemented');
  }
}

/// Extension for easy port access.
extension FactGraphPortsExtension on FactGraphPortsAdapter {
  /// Check if all required ports are available.
  bool get hasRequiredPorts {
    return storagePort != null;
  }

  /// Check if evidence port is available.
  bool get hasEvidencePort => evidencePort != null;

  /// Check if LLM port is available for summarization.
  bool get hasLlmPort => llmPort != null;
}
