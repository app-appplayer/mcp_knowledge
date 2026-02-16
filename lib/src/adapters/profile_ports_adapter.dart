/// Profile Ports Adapter - Adapts unified ports to profile-specific ports.
library;

/// Adapter that converts KnowledgePorts to ProfilePorts.
class ProfilePortsAdapter {
  final dynamic _knowledgePorts;

  /// Create adapter with unified ports.
  ProfilePortsAdapter({required dynamic knowledgePorts})
      : _knowledgePorts = knowledgePorts;

  /// Get storage port for profiles.
  dynamic get storagePort => _knowledgePorts.storagePort;

  /// Get expression port for template rendering.
  dynamic get expressionPort => _knowledgePorts.expressionPort;

  /// Convert to profile-compatible ports object.
  Map<String, dynamic> toProfilePorts() {
    return {
      'storage': storagePort,
      'expression': expressionPort,
    };
  }

  /// Create profile runtime with adapted ports.
  dynamic createProfileRuntime({
    Map<String, dynamic>? config,
  }) {
    // Implementation will create ProfileRuntime with adapted ports
    throw UnimplementedError(
        'ProfilePortsAdapter.createProfileRuntime not implemented');
  }
}

/// Extension for easy port access.
extension ProfilePortsExtension on ProfilePortsAdapter {
  /// Check if all required ports are available.
  bool get hasRequiredPorts {
    return storagePort != null;
  }

  /// Check if expression port is available.
  bool get hasExpressionPort => expressionPort != null;
}
