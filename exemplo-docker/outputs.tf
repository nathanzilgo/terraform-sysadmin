output "container_id" {
  description = "ID do Container Docker"
  value       = docker_container.nginx.id
}

output "image_id" {
  description = "ID da Imagem Docker"
  value       = docker_image.nginx.id
}
