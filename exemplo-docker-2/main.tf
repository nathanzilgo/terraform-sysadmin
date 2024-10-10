terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

provider "docker" {}

resource "docker_image" "memory-bound" {
  name         = var.docker_image
  keep_locally = false
}

resource "docker_container" "memory-bound" {
  image = docker_image.memory-bound.image_id
  name  = var.container_name

  ports {
    internal = 8082
    external = 8082
  }
}
