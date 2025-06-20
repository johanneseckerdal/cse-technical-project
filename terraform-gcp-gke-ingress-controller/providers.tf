# Providers
provider "cloudflare" {
  api_token  = var.cloudflare_api_token
}
provider "google" {
  project = var.gcp_project_id
}

data "google_client_config" "default" {}

provider "helm" {
  kubernetes {
    host                   = "https://${google_container_cluster.example.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(google_container_cluster.example.master_auth.0.cluster_ca_certificate)
  }
}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.example.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.example.master_auth.0.cluster_ca_certificate)
}


provider "random" {}
