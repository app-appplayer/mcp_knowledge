/// KnowledgePorts tests — verify the standard-port container only carries
/// capability-named ports from `mcp_bundle` and exposes a working stub
/// factory.
library;

import 'package:mcp_knowledge/mcp_knowledge.dart';
import 'package:test/test.dart';

void main() {
  group('KnowledgePorts', () {
    test('default constructor leaves every port null', () {
      const ports = KnowledgePorts();
      expect(ports.facts, isNull);
      expect(ports.claims, isNull);
      expect(ports.entities, isNull);
      expect(ports.candidates, isNull);
      expect(ports.evidence, isNull);
      expect(ports.patterns, isNull);
      expect(ports.summaries, isNull);
      expect(ports.runs, isNull);
      expect(ports.contextBundle, isNull);
      expect(ports.retrieval, isNull);
      expect(ports.asset, isNull);
      expect(ports.index, isNull);
      expect(ports.skillRuntime, isNull);
      expect(ports.mcp, isNull);
      expect(ports.llm, isNull);
      expect(ports.metrics, isNull);
      expect(ports.appraisal, isNull);
      expect(ports.decision, isNull);
      expect(ports.expression, isNull);
      expect(ports.profileSummaries, isNull);
      expect(ports.philosophy, isNull);
      expect(ports.ethosStore, isNull);
      expect(ports.workflow, isNull);
      expect(ports.pipeline, isNull);
      expect(ports.scheduler, isNull);
      expect(ports.audit, isNull);
      expect(ports.runbook, isNull);
      expect(ports.kvStorage, isNull);
      expect(ports.approval, isNull);
      expect(ports.notification, isNull);
      expect(ports.event, isNull);
      expect(ports.metric, isNull);
    });

    test('stub() factory wires every standard port to its stub', () {
      final ports = KnowledgePorts.stub();
      expect(ports.facts, isA<FactsPort>());
      expect(ports.claims, isA<ClaimsPort>());
      expect(ports.entities, isA<EntitiesPort>());
      expect(ports.candidates, isA<CandidatesPort>());
      expect(ports.evidence, isA<EvidencePort>());
      expect(ports.patterns, isA<PatternsPort>());
      expect(ports.summaries, isA<SummariesPort>());
      expect(ports.runs, isA<RunsPort>());
      expect(ports.contextBundle, isA<ContextBundlePort>());
      expect(ports.retrieval, isA<RetrievalPort>());
      expect(ports.asset, isA<AssetPort>());
      expect(ports.skillRuntime, isA<SkillRuntimePort>());
      expect(ports.mcp, isA<McpPort>());
      expect(ports.llm, isA<LlmPort>());
      expect(ports.metrics, isA<MetricsPort>());
      expect(ports.appraisal, isA<AppraisalPort>());
      expect(ports.decision, isA<DecisionPort>());
      expect(ports.expression, isA<ExpressionPort>());
      expect(ports.profileSummaries, isA<ProfileSummariesPort>());
      expect(ports.philosophy, isA<PhilosophyPort>());
      expect(ports.ethosStore, isA<EthosStorePort>());
      expect(ports.workflow, isA<WorkflowPort>());
      expect(ports.pipeline, isA<PipelinePort>());
      expect(ports.scheduler, isA<ScheduleTriggerPort>());
      expect(ports.audit, isA<AuditPort>());
      expect(ports.runbook, isA<RunbookPort>());
      expect(ports.kvStorage, isA<KvStoragePort>());
    });

    test('copyWith overrides only the supplied fields', () {
      const original = KnowledgePorts(facts: StubFactsPort());
      final copy = original.copyWith(claims: const StubClaimsPort());
      expect(copy.facts, same(original.facts));
      expect(copy.claims, isA<ClaimsPort>());
      expect(copy.entities, isNull);
    });
  });
}
