variable "name" {
  type        = string
  description = ""
}

variable "hydra_count" {
  type        = number
  description = "how many hydras to start"
}

variable "hydra_nheads" {
  type        = number
  description = "how many heads to start for each hydra"
  default     = 15
}

variable "ecs_cluster_id" {
  type = string
}

variable "vpc_subnets" {
  type = list(string)
}

variable "security_groups" {
  type = list(string)
}

variable "task_role_arn" {
  type = string
}

variable "execution_role_arn" {
  type = string
}

variable "grafana_secrets" {
  type = list(map(string))
}

variable "hydra_secrets" {
  type = list(map(string))
}

variable "docker_pull_secret_arn" {
  type = string
}

variable "hydra_environment" {
  type = list(map(string))
}

variable "grafana_config_endpoint" {
  type = string
}

variable "hydra_image" {
  type = string
}

variable "log_group_name" {
  type = string
}
