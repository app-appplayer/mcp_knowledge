/// PhilosophyFacade tests focused on the multi-ethos resolution path.
library;

import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:mcp_knowledge/mcp_knowledge.dart';
import 'package:mcp_philosophy/mcp_philosophy.dart' show PhilosophyEngine;
import 'package:test/test.dart';

class _MemEthosStore implements EthosStorePort {
  final Map<String, EthosRecord> _records = {};
  String? _activeId;

  @override
  Future<EthosRecord?> getEthos(String id) async => _records[id];

  @override
  Future<void> putEthos(EthosRecord ethos) async {
    _records[ethos.id] = ethos;
    _activeId ??= ethos.id;
  }

  @override
  Future<List<EthosRecord>> listEthos({int? limit}) async =>
      _records.values.toList();

  @override
  Future<void> activateEthos(String id) async {
    if (_records.containsKey(id)) _activeId = id;
  }

  @override
  Future<String?> getActiveEthosId() async => _activeId;
}

EthosRecord _ethosRecord(String id, {String? name}) {
  final ethos = Ethos(
    id: id,
    name: name ?? id,
    valuePriorities: const [],
    prohibitions: const [],
    metadata: EthosMetadata(
      version: '1.0.0',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    ),
  );
  return EthosRecord(
    id: id,
    name: ethos.name,
    version: '1',
    payload: ethos.toJson(),
    createdAt: DateTime.utc(2026, 1, 1),
  );
}

void main() {
  group('PhilosophyFacade.getEthosById — multi-ethos resolution', () {
    test('id matches a record → returns that ethos (not the active one)',
        () async {
      final store = _MemEthosStore();
      await store.putEthos(_ethosRecord('ads-core', name: 'Ads'));
      await store.putEthos(_ethosRecord('editorial-core', name: 'Editorial'));
      // ads-core was put first → it is the active id.
      final engine = PhilosophyEngine(ethosStore: store);
      final system = KnowledgeSystem(
        config: KnowledgeConfig.defaults,
        ports: KnowledgePorts(ethosStore: store),
        philosophyEngine: engine,
      );
      addTearDown(system.shutdown);

      final ethos = await system.philosophy.getEthosById('editorial-core');
      expect(ethos.id, 'editorial-core');
      expect(ethos.name, 'Editorial');
    });

    test('null id → falls back to active ethos', () async {
      final store = _MemEthosStore();
      await store.putEthos(_ethosRecord('ads-core', name: 'Ads'));
      final engine = PhilosophyEngine(ethosStore: store);
      final system = KnowledgeSystem(
        config: KnowledgeConfig.defaults,
        ports: KnowledgePorts(ethosStore: store),
        philosophyEngine: engine,
      );
      addTearDown(system.shutdown);

      final ethos = await system.philosophy.getEthosById(null);
      expect(ethos.id, 'ads-core');
    });

    test('unknown id → falls back to active ethos', () async {
      final store = _MemEthosStore();
      await store.putEthos(_ethosRecord('ads-core', name: 'Ads'));
      final engine = PhilosophyEngine(ethosStore: store);
      final system = KnowledgeSystem(
        config: KnowledgeConfig.defaults,
        ports: KnowledgePorts(ethosStore: store),
        philosophyEngine: engine,
      );
      addTearDown(system.shutdown);

      final ethos = await system.philosophy.getEthosById('does-not-exist');
      expect(ethos.id, 'ads-core');
    });

    test('store unwired → falls back to active ethos via engine', () async {
      // Engine has its own store, KnowledgePorts.ethosStore is null.
      final engineStore = _MemEthosStore();
      await engineStore.putEthos(_ethosRecord('ads-core', name: 'Ads'));
      final engine = PhilosophyEngine(ethosStore: engineStore);
      final system = KnowledgeSystem(
        config: KnowledgeConfig.defaults,
        // ports.ethosStore intentionally not wired here
        philosophyEngine: engine,
      );
      addTearDown(system.shutdown);

      final ethos =
          await system.philosophy.getEthosById('editorial-core');
      // Falls through to engine.getEthos() which returns the active one.
      expect(ethos.id, 'ads-core');
    });
  });
}
