output "be_parameter_names" {
  description = "List of Backend parameter names"
  value       = [for p in aws_ssm_parameter.be_params : p.name]
}

output "ai_parameter_names" {
  description = "List of AI parameter names"
  value       = [for p in aws_ssm_parameter.ai_params : p.name]
}

output "be_parameter_arns" {
  description = "Map of Backend parameter ARNs"
  value       = { for k, p in aws_ssm_parameter.be_params : k => p.arn }
}

output "ai_parameter_arns" {
  description = "Map of AI parameter ARNs"
  value       = { for k, p in aws_ssm_parameter.ai_params : k => p.arn }
}
