// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_mongodb_atlas/otel_mongodb_atlas.dart';

/// Traces MongoDB Atlas Data calls with OpenTelemetry.
///
/// `otel_mongodb_atlas` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each MongoDB Atlas Data call in
/// [tracedMongodbAtlasDataApi]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'mongodb-atlas-example');

  // Wraps a MongoDB Atlas Data API call (insertOne, find, aggregate, updateMany, etc.) in a CLIENT span.
  final mongodbAtlasDataApiId = await tracedMongodbAtlasDataApi<String>(
    action: 'example',
    collection: 'orders',
    database: 'example',
    cluster: 'example',
    dataSource: 'example',
    invoke: () async {
      // Make the MongoDB Atlas Data call here, then report what it returned.
      const id = 'mongodb_atlas_8f3a2c';
      return const MongodbAtlasResult(value: id, documentCount: 3);
    },
  );
  OTelLog.info('tracedMongodbAtlasDataApi returned $mongodbAtlasDataApiId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutMongodbAtlasInstrumentationAsync.
  await runWithoutMongodbAtlasInstrumentationAsync(
    () => tracedMongodbAtlasDataApi<String>(
      action: 'example',
      collection: 'orders',
      database: 'example',
      cluster: 'example',
      dataSource: 'example',
      invoke: () async {
        const id = 'mongodb_atlas_8f3a2c';
        return const MongodbAtlasResult(value: id, documentCount: 3);
      },
    ),
  );

  await OTel.shutdown();
}
