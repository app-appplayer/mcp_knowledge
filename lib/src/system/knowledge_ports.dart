/// Knowledge Ports - Unified port container.
///
/// Provides a single container for all external dependencies.
library;

/// Unified port container for all external dependencies.
class KnowledgePorts {
  /// Storage port.
  final StoragePort storage;

  /// LLM port.
  final LlmPort llm;

  /// MCP port.
  final McpPort mcp;

  /// Evidence processing port.
  final EvidencePort evidence;

  /// Expression formatting port.
  final ExpressionPort expression;

  const KnowledgePorts({
    required this.storage,
    required this.llm,
    required this.mcp,
    required this.evidence,
    required this.expression,
  });

  /// Create with stub implementations.
  factory KnowledgePorts.stub() {
    return KnowledgePorts(
      storage: InMemoryStoragePort(),
      llm: StubLlmPort(),
      mcp: StubMcpPort(),
      evidence: StubEvidencePort(),
      expression: StubExpressionPort(),
    );
  }

  /// Create copy with some ports replaced.
  KnowledgePorts copyWith({
    StoragePort? storage,
    LlmPort? llm,
    McpPort? mcp,
    EvidencePort? evidence,
    ExpressionPort? expression,
  }) {
    return KnowledgePorts(
      storage: storage ?? this.storage,
      llm: llm ?? this.llm,
      mcp: mcp ?? this.mcp,
      evidence: evidence ?? this.evidence,
      expression: expression ?? this.expression,
    );
  }
}

// === Storage Port ===

/// Abstract storage port.
abstract class StoragePort {
  Future<void> save(String collection, String id, Map<String, dynamic> data);
  Future<Map<String, dynamic>?> get(String collection, String id);
  Future<List<Map<String, dynamic>>> query(
      String collection, QueryFilter filter);
  Future<void> delete(String collection, String id);
}

/// Query filter for storage.
class QueryFilter {
  final Map<String, dynamic> conditions;
  final int? limit;
  final int? offset;
  final String? orderBy;
  final bool descending;

  const QueryFilter({
    this.conditions = const {},
    this.limit,
    this.offset,
    this.orderBy,
    this.descending = false,
  });
}

/// In-memory storage implementation.
class InMemoryStoragePort implements StoragePort {
  final Map<String, Map<String, Map<String, dynamic>>> _data = {};

  @override
  Future<void> save(
      String collection, String id, Map<String, dynamic> data) async {
    _data.putIfAbsent(collection, () => {});
    _data[collection]![id] = data;
  }

  @override
  Future<Map<String, dynamic>?> get(String collection, String id) async {
    return _data[collection]?[id];
  }

  @override
  Future<List<Map<String, dynamic>>> query(
      String collection, QueryFilter filter) async {
    final collectionData = _data[collection]?.values.toList() ?? [];
    var result = collectionData;
    if (filter.limit != null) {
      result = result.take(filter.limit!).toList();
    }
    return result;
  }

  @override
  Future<void> delete(String collection, String id) async {
    _data[collection]?.remove(id);
  }
}

// === LLM Port ===

/// Abstract LLM port.
abstract class LlmPort {
  Future<LlmResponse> complete(LlmRequest request);
  Future<List<double>> embed(String text);
}

/// LLM request.
class LlmRequest {
  final String? systemPrompt;
  final String prompt;
  final String? model;
  final double? temperature;
  final int? maxTokens;

  const LlmRequest({
    this.systemPrompt,
    required this.prompt,
    this.model,
    this.temperature,
    this.maxTokens,
  });
}

/// LLM response.
class LlmResponse {
  final String content;
  final int? tokensUsed;

  const LlmResponse({required this.content, this.tokensUsed});
}

/// Stub LLM port.
class StubLlmPort implements LlmPort {
  const StubLlmPort();

  @override
  Future<LlmResponse> complete(LlmRequest request) async {
    return const LlmResponse(content: 'Stub response');
  }

  @override
  Future<List<double>> embed(String text) async {
    return List.filled(384, 0.0);
  }
}

// === MCP Port ===

/// Abstract MCP port.
abstract class McpPort {
  Future<ToolResult> callTool(String name, Map<String, dynamic> arguments);
  Future<Resource> readResource(String uri);
  Future<List<ToolInfo>> listTools();
}

/// Tool execution result.
class ToolResult {
  final dynamic content;
  final bool isError;

  const ToolResult({required this.content, this.isError = false});
}

/// Resource.
class Resource {
  final String uri;
  final String? mimeType;
  final String content;

  const Resource({required this.uri, this.mimeType, required this.content});
}

/// Tool information.
class ToolInfo {
  final String name;
  final String? description;
  final Map<String, dynamic>? inputSchema;

  const ToolInfo({required this.name, this.description, this.inputSchema});
}

/// Stub MCP port.
class StubMcpPort implements McpPort {
  const StubMcpPort();

  @override
  Future<ToolResult> callTool(
      String name, Map<String, dynamic> arguments) async {
    return const ToolResult(content: 'Stub tool result');
  }

  @override
  Future<Resource> readResource(String uri) async {
    return Resource(uri: uri, content: '');
  }

  @override
  Future<List<ToolInfo>> listTools() async {
    return [];
  }
}

// === Evidence Port ===

/// Abstract evidence port.
abstract class EvidencePort {
  Future<List<String>> extractFragments(String content, String mimeType);
  Future<double> computeConfidence(String fragment);
}

/// Stub evidence port.
class StubEvidencePort implements EvidencePort {
  const StubEvidencePort();

  @override
  Future<List<String>> extractFragments(
      String content, String mimeType) async {
    return [];
  }

  @override
  Future<double> computeConfidence(String fragment) async {
    return 0.5;
  }
}

// === Expression Port ===

/// Abstract expression port.
abstract class ExpressionPort {
  String format(String template, Map<String, dynamic> variables);
  bool validate(String template);
}

/// Stub expression port.
class StubExpressionPort implements ExpressionPort {
  const StubExpressionPort();

  @override
  String format(String template, Map<String, dynamic> variables) {
    return template;
  }

  @override
  bool validate(String template) {
    return true;
  }
}
