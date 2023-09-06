output "neo4j_password" {
  value     = random_password.neo4j.result
  sensitive = true
}
