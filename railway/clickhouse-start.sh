#!/bin/sh
set -e
mkdir -p /etc/clickhouse-server/config.d
cat > /etc/clickhouse-server/config.d/railway-listen.xml << 'XML'
<clickhouse>
  <listen_host>::</listen_host>
  <listen_host>0.0.0.0</listen_host>
  <trace_log remove="remove"/>
  <text_log remove="remove"/>
  <metric_log remove="remove"/>
  <asynchronous_metric_log remove="remove"/>
  <processors_profile_log remove="remove"/>
  <query_metric_log remove="remove"/>
  <query_thread_log remove="remove"/>
  <query_views_log remove="remove"/>
  <asynchronous_insert_log remove="remove"/>
  <opentelemetry_span_log remove="remove"/>
  <background_schedule_pool_log remove="remove"/>
</clickhouse>
XML
exec /entrypoint.sh
