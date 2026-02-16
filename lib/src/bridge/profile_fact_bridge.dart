/// Profile-Fact Bridge - Bridge for profile rendering with fact context.
library;

/// Result of profile rendering with fact context.
class ProfileWithContextResult {
  /// Whether rendering succeeded.
  final bool success;

  /// Rendered content.
  final String? content;

  /// Entity context used.
  final Map<String, dynamic> contextUsed;

  /// Facts referenced.
  final List<String> factIds;

  /// Error message.
  final String? error;

  const ProfileWithContextResult({
    required this.success,
    this.content,
    this.contextUsed = const {},
    this.factIds = const [],
    this.error,
  });
}

/// Bridge connecting profile rendering to fact graph.
class ProfileFactBridge {
  final dynamic _profileRuntime;
  final dynamic _factGraph;

  /// Create bridge with profile runtime and fact graph.
  ProfileFactBridge({
    required dynamic profileRuntime,
    required dynamic factGraph,
  })  : _profileRuntime = profileRuntime,
        _factGraph = factGraph;

  /// Render profile with entity context from fact graph.
  Future<ProfileWithContextResult> renderWithContext(
    String profileId, {
    required String entityId,
    List<String>? domains,
    Map<String, dynamic>? additionalContext,
  }) async {
    // Implementation will:
    // 1. Query fact graph for entity context
    // 2. Merge with additional context
    // 3. Render profile with merged context
    throw UnimplementedError(
        'ProfileFactBridge.renderWithContext not implemented');
  }

  /// Get full entity context for profile rendering.
  Future<Map<String, dynamic>> getEntityContext(
    String entityId, {
    List<String>? domains,
    DateTime? asOf,
  }) async {
    // Implementation will query fact graph
    throw UnimplementedError(
        'ProfileFactBridge.getEntityContext not implemented');
  }

  /// Render system prompt with entity facts.
  Future<String> renderSystemPrompt(
    String profileId, {
    required String entityId,
    List<String>? domains,
  }) async {
    final result = await renderWithContext(
      profileId,
      entityId: entityId,
      domains: domains,
    );
    if (!result.success) {
      throw ProfileFactBridgeException(result.error ?? 'Unknown error');
    }
    return result.content!;
  }
}

/// Profile-Fact bridge exception.
class ProfileFactBridgeException implements Exception {
  final String message;
  ProfileFactBridgeException(this.message);

  @override
  String toString() => 'ProfileFactBridgeException: $message';
}
