/// Skill Facade - Simplified API for skill operations.
library;

/// Skill information.
class SkillInfo {
  /// Skill ID.
  final String skillId;

  /// Skill name.
  final String name;

  /// Description.
  final String? description;

  const SkillInfo({
    required this.skillId,
    required this.name,
    this.description,
  });
}

/// Simplified API for skill operations.
class SkillFacade {
  final dynamic _system;

  /// Create facade with system reference.
  SkillFacade({required dynamic system}) : _system = system;

  /// Execute skill and return output directly.
  /// Throws exception on failure.
  Future<T> run<T>(String skillId, Map<String, dynamic> inputs) async {
    final result = await execute(skillId, inputs);
    if (!result.success) {
      throw SkillException(result.error ?? 'Unknown error');
    }
    return result.output as T;
  }

  /// Execute skill with full result.
  Future<SkillResult> execute(
    String skillId,
    Map<String, dynamic> inputs, {
    bool recordClaims = true,
    String? entityId,
    String? executionId,
  }) async {
    // Implementation will use _system.skills
    throw UnimplementedError('SkillFacade.execute not implemented');
  }

  /// List available skills.
  Future<List<SkillInfo>> list({
    String? category,
    String? tag,
  }) async {
    // Implementation will use _system.skills
    throw UnimplementedError('SkillFacade.list not implemented');
  }

  /// Get skill details.
  Future<dynamic> get(String skillId) async {
    // Implementation will use _system.skills
    throw UnimplementedError('SkillFacade.get not implemented');
  }
}

/// Skill execution result.
class SkillResult {
  /// Whether execution succeeded.
  final bool success;

  /// Output value.
  final dynamic output;

  /// Error message.
  final String? error;

  /// Execution ID.
  final String executionId;

  /// Duration.
  final Duration duration;

  const SkillResult({
    required this.success,
    this.output,
    this.error,
    required this.executionId,
    required this.duration,
  });
}

/// Skill exception.
class SkillException implements Exception {
  final String message;
  SkillException(this.message);

  @override
  String toString() => 'SkillException: $message';
}
