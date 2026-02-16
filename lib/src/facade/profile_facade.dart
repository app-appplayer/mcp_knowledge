/// Profile Facade - Simplified API for profile operations.
library;

/// Profile information.
class ProfileInfo {
  /// Profile ID.
  final String profileId;

  /// Profile name.
  final String name;

  /// Description.
  final String? description;

  /// Tags.
  final List<String> tags;

  const ProfileInfo({
    required this.profileId,
    required this.name,
    this.description,
    this.tags = const [],
  });
}

/// Profile selection result.
class ProfileSelectionResult {
  /// Selected profile ID.
  final String? selectedId;

  /// Selection confidence.
  final double confidence;

  /// Reason for selection.
  final String? reason;

  /// Alternative profiles.
  final List<String> alternatives;

  const ProfileSelectionResult({
    this.selectedId,
    required this.confidence,
    this.reason,
    this.alternatives = const [],
  });

  /// Whether a profile was selected.
  bool get hasSelection => selectedId != null;
}

/// Simplified API for profile operations.
class ProfileFacade {
  final dynamic _system;

  /// Create facade with system reference.
  ProfileFacade({required dynamic system}) : _system = system;

  /// Render system prompt with entity context.
  /// Throws exception on failure.
  Future<String> getSystemPrompt(
    String profileId, {
    required String entityId,
    Map<String, dynamic>? additionalContext,
  }) async {
    final result = await render(
      profileId,
      entityId: entityId,
      additionalContext: additionalContext,
    );
    if (!result.success) {
      throw ProfileException(result.error ?? 'Unknown error');
    }
    return result.content!;
  }

  /// Render profile with full options and result.
  Future<ProfileResult> render(
    String profileId, {
    required String entityId,
    Map<String, dynamic>? additionalContext,
  }) async {
    // Implementation will use _system.profiles
    throw UnimplementedError('ProfileFacade.render not implemented');
  }

  /// List available profiles.
  Future<List<ProfileInfo>> list({
    String? tag,
    String? category,
  }) async {
    // Implementation will use _system.profiles
    throw UnimplementedError('ProfileFacade.list not implemented');
  }

  /// Select best profile for context.
  Future<ProfileSelectionResult> select(
    List<String> candidateIds, {
    required Map<String, dynamic> context,
    String? preferredId,
  }) async {
    // Implementation will use _system.profiles
    throw UnimplementedError('ProfileFacade.select not implemented');
  }
}

/// Profile render result.
class ProfileResult {
  /// Whether render succeeded.
  final bool success;

  /// Rendered content.
  final String? content;

  /// Error message.
  final String? error;

  /// Duration.
  final Duration duration;

  const ProfileResult({
    required this.success,
    this.content,
    this.error,
    required this.duration,
  });
}

/// Profile exception.
class ProfileException implements Exception {
  final String message;
  ProfileException(this.message);

  @override
  String toString() => 'ProfileException: $message';
}
