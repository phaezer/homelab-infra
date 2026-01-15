# Backend Configuration
# State storage configuration

terraform {
  backend "s3" {
    bucket = "home-tf"
    key    = "terraform.tfstate"
    region = "us-east-1"
    # endpoints = {
    # s3 = "https://s3.phaezer.io"
    # }
    endpoint = "https://s3.phaezer.io"
    # profile  = "home"
    # insecure                    = true
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_metadata_api_check     = true
    force_path_style            = true
  }
}
