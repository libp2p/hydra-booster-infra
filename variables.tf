variable "name" {
  type        = string
  description = ""
  default     = "hydra-test"
}
variable "hydra_count" {
  type        = number
  description = "how many hydras to start"
  default     = 134
}
variable "hydra_nheads" {
  type        = number
  description = "how many heads to start for each hydra"
  default     = 15
}
