/// ProfileFacade integration tests against a real ProfileRuntime.
///
/// Uses mcp_profile's stub engine ports so the facade actually exercises
/// `ProfileRuntime.apply()` (REDESIGN-PLAN Phase 8 §4 step 6).
library;

import 'package:mcp_knowledge/mcp_knowledge.dart';
import 'package:test/test.dart';

ProfileRuntime _buildStubRuntime() {
  final registry = ProfileRegistry();
  registry.register(const Profile(
    id: 'p-test',
    name: 'Test Profile',
    version: '1.0.0',
  ));
  return ProfileRuntime(
    registry: registry,
    engines: EnginePorts.stub(),
  );
}

void main() {
  group('ProfileFacade with ProfileRuntime', () {
    late KnowledgeSystem system;

    setUp(() {
      system = KnowledgeSystem(
        config: KnowledgeConfig.defaults,
        profileRuntime: _buildStubRuntime(),
      );
    });

    tearDown(() async {
      await system.shutdown();
    });

    test('isAvailable is true', () {
      expect(system.profile.isAvailable, isTrue);
    });

    test('apply runs the full 3-pillar pipeline and returns a result',
        () async {
      final result = await system.profile.apply(
        'p-test',
        entityId: 'e1',
      );
      expect(result.profileId, equals('p-test'));
      expect(result.metadata.profileVersion, equals('1.0.0'));
    });

    test('apply emits ProfileAppliedEvent', () async {
      var event = false;
      system.eventBus.on<ProfileAppliedEvent>().listen((_) {
        event = true;
      });
      await system.profile.apply('p-test', entityId: 'e1');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(event, isTrue);
    });

    test('apply with unknown profile throws ProfileNotFoundException',
        () async {
      expect(
        () => system.profile.apply('missing', entityId: 'e1'),
        throwsA(isA<ProfileNotFoundException>()),
      );
    });

    test('register/list/get round-trip via underlying registry', () {
      const newProfile = Profile(
        id: 'p-new',
        name: 'New',
        version: '0.1.0',
      );
      system.profile.register(newProfile);
      expect(system.profile.get('p-new')?.id, equals('p-new'));
      expect(
        system.profile.list().map((p) => p.id),
        containsAll(['p-test', 'p-new']),
      );
      expect(system.profile.unregister('p-new'), isTrue);
      expect(system.profile.get('p-new'), isNull);
    });
  });

  group('ProfileFacade without ProfileRuntime — graceful list', () {
    test('list() returns empty list when profileRuntime is null', () {
      final system = KnowledgeSystem(
        config: KnowledgeConfig.defaults,
        // profileRuntime intentionally not wired
      );
      expect(system.profile.isAvailable, isFalse);
      // list() must not throw — returns const [] so multi-pool UI pickers
      // can call it unconditionally.
      expect(system.profile.list(), isEmpty);
    });

    test('apply still throws StateError when profileRuntime is null',
        () async {
      final system = KnowledgeSystem(
        config: KnowledgeConfig.defaults,
      );
      expect(
        () => system.profile.apply('p-test', entityId: 'e1'),
        throwsStateError,
      );
    });
  });
}
