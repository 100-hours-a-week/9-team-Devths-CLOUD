output "cluster_name" {
  description = "Kubernetes cluster name"
  value       = local.cluster_name
}

# ============================================================================
# 워커노드 ASG Outputs
# ============================================================================

output "k8s_worker_asg_id" {
  description = "Auto Scaling Group ID for Kubernetes worker nodes"
  value       = module.k8s_worker_asg.asg_id
}

output "k8s_worker_asg_name" {
  description = "Auto Scaling Group name for Kubernetes worker nodes"
  value       = module.k8s_worker_asg.asg_name
}

output "k8s_worker_asg_arn" {
  description = "Auto Scaling Group ARN for Kubernetes worker nodes"
  value       = module.k8s_worker_asg.asg_arn
}

output "k8s_worker_launch_template_id" {
  description = "Launch Template ID for Kubernetes worker nodes"
  value       = module.k8s_worker_asg.launch_template_id
}

output "k8s_worker_launch_template_name" {
  description = "Launch Template name for Kubernetes worker nodes"
  value       = module.k8s_worker_asg.launch_template_name
}

# ============================================================================
# 보안그룹 및 IAM
# ============================================================================

output "k8s_master_security_group_id" {
  description = "Security group ID attached to the Kubernetes control-plane nodes"
  value       = local.use_network_managed_master_sg ? local.network_k8s_master_security_group_id : module.master_security_group[0].security_group_id
}

output "k8s_worker_security_group_id" {
  description = "Security group ID attached to the Kubernetes worker nodes"
  value       = local.use_network_managed_worker_sg ? local.network_k8s_worker_security_group_id : module.worker_security_group[0].security_group_id
}

output "k8s_master_iam_role_name" {
  description = "IAM role name attached to the Kubernetes control-plane nodes"
  value       = module.iam.ec2_role_name
}

output "k8s_master_iam_role_arn" {
  description = "IAM role ARN attached to the Kubernetes control-plane nodes"
  value       = module.iam.ec2_role_arn
}

# ============================================================================
# Helper Commands
# ============================================================================

output "list_worker_instances_command" {
  description = "Command to list instances in the K8s worker ASG"
  value       = "aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names ${module.k8s_worker_asg.asg_name} --query 'AutoScalingGroups[0].Instances[*].[InstanceId,LifecycleState,HealthStatus]' --output table"
}

output "ssm_start_session_info" {
  description = "Information to connect to a control-plane node with AWS Systems Manager"
  value       = "First get instance ID from ASG, then run: aws ssm start-session --target <INSTANCE_ID>"
}

output "worker_join_command" {
  description = "Command to join worker nodes to the cluster"
  value       = "sudo /usr/local/bin/k8s-worker-join.sh"
}

output "join_command_ssm_path" {
  description = "SSM Parameter Store path for the kubeadm join command"
  value       = local.join_command_ssm_path
}
