packer {
    required_version = ">= 1.7.0"
    required_plugins {
        hyperv = {
            version = ">= 1.0.0"
            source  = "github.com/hashicorp/hyperv"
        }
        git = {
            version = ">= 0.3.0"
            source  = "github.com/ethanmdavidson/git"
        }
    }
}
