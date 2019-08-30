
variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}
variable "env" {}
variable "app" {}

variable "sf_username" {}
variable "sf_password" {}
variable "sf_tcp_gateway_port" {
    default = 19000
}
variable "sf_http_gateway_port" {
    default = 19080
}
variable "sf_cluster_vault_url" {}
variable "sf_cluster_cert_url" {}
variable "sf_cluster_cert_thumb" {}

variable "vnet_address_space" {
    default = "10.0.0.0/16"
}
variable "subnet1_address_space" {
    default = "10.0.0.0/24"
}