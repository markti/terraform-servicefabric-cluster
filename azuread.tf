resource "azuread_application" "cluster-app" {
  name                       = "${var.app}-cluster-app-${var.env}"
}

resource "azuread_application" "client-app" {
  name                       = "${var.app}-client-app-${var.env}"
}