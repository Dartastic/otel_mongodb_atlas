// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_mongodb_atlas/otel_mongodb_atlas.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_mongodb_atlas-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('find records CLIENT span', () async {
    await tracedMongodbAtlasDataApi<String>(
      action: 'find',
      collection: 'orders',
      database: 'app',
      cluster: 'Cluster0',
      dataSource: 'mongodb-atlas',
      invoke: () async => const MongodbAtlasResult(
        value: 'rows',
        documentCount: 3,
      ),
    );
    final a = attrsOf(spans.findSpanByName('find orders')!);
    expect(a['db.system'], 'mongodb');
    expect(a['db.operation'], 'find');
    expect(a['db.collection.name'], 'orders');
    expect(a['mongodb.atlas.action'], 'find');
    expect(a['db.name'], 'app');
    expect(a['mongodb.atlas.cluster'], 'Cluster0');
    expect(a['mongodb.atlas.data_source'], 'mongodb-atlas');
    expect(a['mongodb.atlas.document_count'], 3);
  });

  test('vectorSearch records CLIENT span', () async {
    await tracedMongodbAtlasSearch<String>(
      index: 'embeddings_idx',
      collection: 'movies',
      database: 'app',
      vector: true,
      invoke: () async => const MongodbAtlasResult(
        value: 'hits',
        documentCount: 10,
      ),
    );
    final a = attrsOf(spans.findSpanByName('vectorSearch movies')!);
    expect(a['db.operation'], r'$vectorSearch');
    expect(a['mongodb.atlas.search.index'], 'embeddings_idx');
    expect(a['mongodb.atlas.document_count'], 10);
  });

  test('suppression skips spans', () async {
    await runWithoutMongodbAtlasInstrumentationAsync(() async {
      await tracedMongodbAtlasDataApi<String>(
        action: 'find',
        collection: 'c',
        invoke: () async => const MongodbAtlasResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('find '), isEmpty);
  });
}
