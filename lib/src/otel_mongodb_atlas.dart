// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_mongodb_atlas_suppression.dart';

const _tracerName = 'dartastic_otel_libs_mongodb_atlas';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

/// Pair returned from `tracedMongodbAtlas*` callbacks.
class MongodbAtlasResult<T> {
  const MongodbAtlasResult({required this.value, this.documentCount});
  final T value;
  final int? documentCount;
}

/// Wraps a MongoDB Atlas Data API call (insertOne, find, aggregate,
/// updateMany, etc.) in a CLIENT span. db.system=mongodb.
Future<T> tracedMongodbAtlasDataApi<T>({
  required String action,
  required String collection,
  required Future<MongodbAtlasResult<T>> Function() invoke,
  String? database,
  String? cluster,
  String? dataSource,
}) async {
  if (mongodbAtlasInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'db.system': 'mongodb',
    'db.operation': action,
    'db.collection.name': collection,
    'mongodb.atlas.action': action,
    if (database != null) 'db.name': database,
    if (cluster != null) 'mongodb.atlas.cluster': cluster,
    if (dataSource != null) 'mongodb.atlas.data_source': dataSource,
  };

  final span = _tracer().startSpan(
    '$action $collection',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.documentCount != null) {
      span.addAttributes(OTel.attributes([
        OTel.attributeInt('mongodb.atlas.document_count', r.documentCount!),
      ]));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}

/// Wraps a MongoDB Atlas Search aggregation pipeline ($search /
/// $vectorSearch) in a CLIENT span.
Future<T> tracedMongodbAtlasSearch<T>({
  required String index,
  required String collection,
  required Future<MongodbAtlasResult<T>> Function() invoke,
  String? database,
  bool vector = false,
}) async {
  if (mongodbAtlasInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'db.system': 'mongodb',
    'db.operation': vector ? r'$vectorSearch' : r'$search',
    'db.collection.name': collection,
    'mongodb.atlas.search.index': index,
    if (database != null) 'db.name': database,
  };

  final span = _tracer().startSpan(
    vector ? 'vectorSearch $collection' : 'search $collection',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.documentCount != null) {
      span.addAttributes(OTel.attributes([
        OTel.attributeInt('mongodb.atlas.document_count', r.documentCount!),
      ]));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
