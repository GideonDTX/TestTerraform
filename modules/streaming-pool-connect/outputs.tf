output "bootstrap_servers" {
  value = oci_streaming_stream_pool.this.kafka_settings[*].bootstrap_servers
}

output "connect_configuration_topic_list" {
  value = <<-EOT
  ${oci_streaming_connect_harness.this.id}-config
  ${oci_streaming_connect_harness.this.id}-offset
  ${oci_streaming_connect_harness.this.id}-status
  EOT
}
