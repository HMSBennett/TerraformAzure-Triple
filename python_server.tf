resource "azurerm_network_security_group" "third" {
	name = "${var.server}-NSG"
	location = "${azurerm_resource_group.main.location}"
	resource_group_name = "${azurerm_resource_group.main.name}"

	security_rule {
                name = "Server"
                priority = 200
                direction = "Outbound"
                access = "Allow"
                protocol = "Tcp"
                source_port_range = "*"
                destination_port_range = "8088"
                source_address_prefix = "*"
                destination_address_prefix = "*"
        }

}

resource "azurerm_public_ip" "third" {
	name = "${var.server}-IP"
	location = "${azurerm_resource_group.main.location}"
	resource_group_name = "${azurerm_resource_group.main.name}"
	allocation_method = "Static"
	domain_name_label = "${var.user}-${formatdate("DDMMYYhhmmss",timestamp())}"

	tags = {
		environment = "Production"
	}
}

resource "azurerm_network_interface" "third" {
        name = "${var.server}-nic"
        location = "${azurerm_resource_group.main.location}"
        resource_group_name = "${azurerm_resource_group.main.name}"

        ip_configuration {
                name = "${var.server}-IP-Config"
                subnet_id = "${azurerm_subnet.internal.id}"
                private_ip_address_allocation = "Dynamic"
		public_ip_address_id = "${azurerm_public_ip.third.id}"
        }
}

resource "azurerm_virtual_machine" "third" {
	name = "${var.server}-vm"
	location = "${azurerm_resource_group.main.location}"
	resource_group_name = "${azurerm_resource_group.main.name}"
	network_interface_ids = ["${azurerm_network_interface.third.id}"]
	vm_size = "Standard_B1MS"

	storage_image_reference {
		publisher = "Canonical"
		offer = "UbuntuServer"
		sku = "16.04-LTS"
		version = "latest"
	}

	storage_os_disk {
		name = "serverosdisk"
		caching = "ReadWrite"
		create_option = "FromImage"
		managed_disk_type = "Standard_LRS"
	}

	os_profile {
		computer_name = "${var.server}-machine"
		admin_username = "${var.user}"
		admin_password = "${var.password}"
	}

	os_profile_linux_config {
		disable_password_authentication = false
		
		ssh_keys {
			path = "/home/${var.user}/.ssh/authorized_keys"
			key_data = "${file("~/.ssh/id_rsa.pub")} "
		}
	}

	tags = {
		environment = "staging"	
	}
	
	provisioner "remote-exec" {
		inline = [
			"echo Third VM Runs ---------------------------------------------"
			]
		connection{
			type = "ssh"
			user = "${var.user}"
			private_key = file("/home/${var.user}/.ssh/id_rsa")
			host = "${azurerm_public_ip.third.fqdn}"
		}
	}
}
