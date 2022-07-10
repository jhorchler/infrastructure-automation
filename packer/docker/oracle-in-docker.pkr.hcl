# initialize required plugins
packer {
    required_version = ">= 1.8.0"
    required_plugins {
        docker = {
            version = ">= 1.0.5"
            source  = "github.com/hashicorp/docker"
        }
        git = {
            version = ">= 0.3.2"
            source = "github.com/ethanmdavidson/git"
        }
    }
}

# define data sources
data "git-commit" "cwd-head" { }

# define installation source
source "docker" "oraimage" {

    # base image pulled from registry if needed
    image = "oraclelinux:8-slim"

    # instead of export, comit to an image
    commit = true

}

# build the new image
build {
    sources = ["docker.oraimage"]
}
