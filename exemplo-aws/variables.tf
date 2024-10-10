variable "docker_port" {
  description = "Porta do container"
  type        = number
  default     = 8082
}

variable "container_name" {
  description = "Nome para o container"
  type        = string
  default     = "SysAdminTerraformServerInstance"
}

variable "docker_image" {
  description = "Nome da imagem docker"
  type        = string
  default     = "zilgostardust/memory-bound:0.1"
}

variable "instance_name" {
  description = "Nome da instancia"
  type        = string
  default     = "SysAdminTerraformServerInstance"
}