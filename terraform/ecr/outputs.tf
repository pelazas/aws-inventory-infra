output "repository_url" {
  description = "The URL of the ECR repo"
  value       = aws_ecr_repository.main.repository_url
}