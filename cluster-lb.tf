
resource "azurerm_lb" "cluster-lb" {
    name                = "${local.cluster_name}-lb"
    location            = "${azurerm_resource_group.cluster-rg.location}"
    resource_group_name = "${azurerm_resource_group.cluster-rg.name}"

    frontend_ip_configuration {
        name                 = "PublicIPAddress"
        public_ip_address_id = "${azurerm_public_ip.cluster-pip.id}"
    }

    tags = "${local.default_tags}"
}

resource "azurerm_lb_backend_address_pool" "cluster-lb-be-addr-pool" {
    resource_group_name = "${azurerm_resource_group.cluster-rg.name}"
    loadbalancer_id     = "${azurerm_lb.cluster-lb.id}"
    name                = "LoadBalancerBEAddressPool"
}

resource "azurerm_lb_rule" "lb-rule-sf-tcp-gw" {
    resource_group_name     = "${azurerm_resource_group.cluster-rg.name}"
    loadbalancer_id         = "${azurerm_lb.cluster-lb.id}"
    backend_address_pool_id = "${azurerm_lb_backend_address_pool.cluster-lb-be-addr-pool.id}"

    name                           = "LBRule"
    protocol                       = "Tcp"
    frontend_port                  = 19000
    backend_port                   = 19000
    frontend_ip_configuration_name = "${azurerm_lb.cluster-lb.frontend_ip_configuration[0].name}"
    idle_timeout_in_minutes        = 5
    enable_floating_ip             = false
    probe_id                       = "${azurerm_lb_probe.lb-probe-sf-tcp-gw.id}"
}

resource "azurerm_lb_probe" "lb-probe-sf-tcp-gw" {
    resource_group_name     = "${azurerm_resource_group.cluster-rg.name}"
    loadbalancer_id         = "${azurerm_lb.cluster-lb.id}"
    name                    = "FabricGatewayProbe"
    port                    = 19000
}


resource "azurerm_lb_rule" "lb-rule-sf-http-gw" {
    resource_group_name     = "${azurerm_resource_group.cluster-rg.name}"
    loadbalancer_id         = "${azurerm_lb.cluster-lb.id}"
    backend_address_pool_id = "${azurerm_lb_backend_address_pool.cluster-lb-be-addr-pool.id}"

    name                           = "LBHttpRule"
    protocol                       = "Tcp"
    frontend_port                  = 19080
    backend_port                   = 19080
    frontend_ip_configuration_name = "${azurerm_lb.cluster-lb.frontend_ip_configuration[0].name}"
    idle_timeout_in_minutes        = 5
    enable_floating_ip             = false
    probe_id                       = "${azurerm_lb_probe.lb-probe-sf-http-gw.id}"
}

resource "azurerm_lb_probe" "lb-probe-sf-http-gw" {
    resource_group_name     = "${azurerm_resource_group.cluster-rg.name}"
    loadbalancer_id         = "${azurerm_lb.cluster-lb.id}"
    name                    = "FabricHttpGatewayProbe"
    port                    = 19080
}



resource "azurerm_lb_rule" "lb-rule-app-http" {
    resource_group_name     = "${azurerm_resource_group.cluster-rg.name}"
    loadbalancer_id         = "${azurerm_lb.cluster-lb.id}"
    backend_address_pool_id = "${azurerm_lb_backend_address_pool.cluster-lb-be-addr-pool.id}"

    name                           = "AppPortLBRule1"
    protocol                       = "Tcp"
    frontend_port                  = 80
    backend_port                   = 80
    frontend_ip_configuration_name = "${azurerm_lb.cluster-lb.frontend_ip_configuration[0].name}"
    idle_timeout_in_minutes        = 5
    enable_floating_ip             = false
    probe_id                       = "${azurerm_lb_probe.lb-probe-app-http.id}"
}

resource "azurerm_lb_probe" "lb-probe-app-http" {
    resource_group_name     = "${azurerm_resource_group.cluster-rg.name}"
    loadbalancer_id         = "${azurerm_lb.cluster-lb.id}"
    name                    = "AppPortProbe1"
    port                    = 80
}




resource "azurerm_lb_rule" "lb-rule-app-https" {
    resource_group_name     = "${azurerm_resource_group.cluster-rg.name}"
    loadbalancer_id         = "${azurerm_lb.cluster-lb.id}"
    backend_address_pool_id = "${azurerm_lb_backend_address_pool.cluster-lb-be-addr-pool.id}"

    name                           = "AppPortLBRule2"
    protocol                       = "Tcp"
    frontend_port                  = 443
    backend_port                   = 443
    frontend_ip_configuration_name = "${azurerm_lb.cluster-lb.frontend_ip_configuration[0].name}"
    idle_timeout_in_minutes        = 5
    enable_floating_ip             = false
    probe_id                       = "${azurerm_lb_probe.lb-probe-app-https.id}"
}

resource "azurerm_lb_probe" "lb-probe-app-https" {
    resource_group_name     = "${azurerm_resource_group.cluster-rg.name}"
    loadbalancer_id         = "${azurerm_lb.cluster-lb.id}"
    name                    = "AppPortProbe2"
    port                    = 443
}

resource "azurerm_lb_nat_pool" "lb-inbound-nat-pool" {
    resource_group_name     = "${azurerm_resource_group.cluster-rg.name}"
    loadbalancer_id         = "${azurerm_lb.cluster-lb.id}"

    name                           = "LoadBalancerBEAddressNatPool"
    protocol                       = "Tcp"
    frontend_port_start            = 3389
    frontend_port_end              = 4500
    backend_port                   = 3389
    frontend_ip_configuration_name = "${azurerm_lb.cluster-lb.frontend_ip_configuration[0].name}"
    
}


