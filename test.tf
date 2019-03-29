# Configure the Microsoft Azure Provider
provider "azurerm" {
    subscription_id = "4e1a2fb0-7ff7-4dfc-89dd-55e8a7647486"
    client_id       = "4cbdd08e-ecb7-49fb-9ade-11069320bf34"
    client_secret   = "da2b89ce-58f9-4136-8efa-a4c8138225a5"
    tenant_id       = "fc5be58e-67a5-4d7f-88f6-abf551a10766"
}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "rgterraformdemo" {
    name     = "rg-terraform-demo"
    location = "westus"

    tags {
        environment = "Terraform Demo"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "vnetterraformdemo" {
    name                = "vnet-terraform-demo"
    address_space       = ["192.168.0.0/20"]
    location            = "westus"
    resource_group_name = "${azurerm_resource_group.rgterraformdemo.name}"

    tags {
        environment = "Terraform Demo"
    }
}

# Create subnet
resource "azurerm_subnet" "appsubnetterraformdemo" {
    name                 = "app-subnet-terraform-demo"
    resource_group_name  = "${azurerm_resource_group.rgterraformdemo.name}"
    virtual_network_name = "${azurerm_virtual_network.vnetterraformdemo.name}"
    address_prefix       = "192.168.0.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "pubipterraformdemo" {
    name                         = "pub-ip-terraform-demo"
    location                     = "westus"
    resource_group_name          = "${azurerm_resource_group.rgterraformdemo.name}"
    allocation_method            = "Dynamic"

    tags {
        environment = "Terraform Demo"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "nsgappterraformdemo" {
    name                = "nsg-app-terraform-demo"
    location            = "westus"
    resource_group_name = "${azurerm_resource_group.rgterraformdemo.name}"

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags {
        environment = "Terraform Demo"
    }
}

# Create network interface
resource "azurerm_network_interface" "nicvmterraformdemo" {
    name                      = "nic-vm-terraform-demo"
    location                  = "westus"
    resource_group_name       = "${azurerm_resource_group.rgterraformdemo.name}"
    network_security_group_id = "${azurerm_network_security_group.nsgappterraformdemo.id}"

    ip_configuration {
        name                          = "vmNicConfiguration"
        subnet_id                     = "${azurerm_subnet.appsubnetterraformdemo.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.pubipterraformdemo.id}"
    }

    tags {
        environment = "Terraform Demo"
    }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${azurerm_resource_group.rgterraformdemo.name}"
    }

    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "storageaccounttfdemo" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = "${azurerm_resource_group.rgterraformdemo.name}"
    location                    = "westus"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags {
        environment = "Terraform Demo"
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "vmterraformdemo" {
    name                  = "vm-terraform-demo"
    location              = "westus"
    resource_group_name   = "${azurerm_resource_group.rgterraformdemo.name}"
    network_interface_ids = ["${azurerm_network_interface.nicvmterraformdemo.id}"]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "tfOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    /*
    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }
    */
    storage_image_reference {
        publisher = "OpenLogic"
        offer     = "CentOS"
        sku       = "7.5"
        version   = "latest"
    }


    os_profile {
        computer_name  = "vm-tf-demo"
        admin_username = "tfdemouser"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/tfdemouser/.ssh/authorized_keys"
            key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDPKq60Kb9QyFfwFWUZDN32wqBvcaQG9/k6vZvlMZGKmQtuW2H/WMKx2V8c3dEOxm2X0Hsio0AiWXMdhGx5/G/xa5eesK0TwAlRXRTuZ4+/9L1SwLEgCRMQ7mBn+laW6AyN5e5q8cr7P1lAXzmNTH6KqxYkdM29qTz+qGwKgFgMZjU3ct7wWwjbybLIlZ4SMFR5OuaDDw7FfGdPHxj4If1qi9hDnFSALGHOMO+o3tf4rlZzOEqjYk1DSeDtyXD0B8lnc4xBVvCneW/JZ71p7sAEbdiRrneTW6QjzKdnkLQ9u9vX5ATj96Mg2KfMF1tt1m96hNYh4u1axPx0kLehipIB anandbanik@Anands-MBP"
        }
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.storageaccounttfdemo.primary_blob_endpoint}"
    }

    tags {
        environment = "Terraform Demo"
    }
}