resource "azurerm_network_security_group" "main" {
	name = "${var.prefix.host}-NSG"
	location = "${azurerm_resource_group.main.location}"
	resource_group_name = "${azurerm_resource_group.main.name}"

	security_rule {
		name = "SSH"
        	priority = 100
        	direction = "Outbound"
        	access = "Allow"
        	protocol = "Tcp"
        	source_port_range = "*" 
        	destination_port_range = "22"
        	source_address_prefix = "*"
        	destination_address_prefix = "*"
	}

	security_rule {
                name = "HTTPS"
                priority = 150
                direction = "Outbound"
                access = "Allow"
                protocol = "Tcp"
                source_port_range = "*"
                destination_port_range = "8080"
                source_address_prefix = "*"
                destination_address_prefix = "*"
	}

}

resource "azurerm_public_ip" "main" {
	name = "${var.prefix.host}-IP"
	location = "${azurerm_resource_group.main.location}"
	resource_group_name = "${azurerm_resource_group.main.name}"
	allocation_method = "Static"
	domain_name_label = "${var.prefix.name}-${formatdate("DDMMYYhhmmss",timestamp())}"

	tags = {
		environment = "Production"
	}
}

resource "azurerm_network_interface" "main" {
        name = "${var.prefix.host}-nic"
        location = "${azurerm_resource_group.main.location}"
        resource_group_name = "${azurerm_resource_group.main.name}"

        ip_configuration {
                name = "${var.prefix.host}-IP-Config"
                subnet_id = "${azurerm_subnet.internal.id}"
                private_ip_address_allocation = "Dynamic"
		public_ip_address_id = "${azurerm_public_ip.main.id}"
        }
}

resource "azurerm_virtual_machine" "main" {
	name = "${var.prefix.host}-vm"
	location = "${azurerm_resource_group.main.location}"
	resource_group_name = "${azurerm_resource_group.main.name}"
	network_interface_ids = ["${azurerm_network_interface.main.id}"]
	vm_size = "Standard_B1MS"

	storage_image_reference {
		publisher = "Canonical"
		offer = "UbuntuServer"
		sku = "16.04-LTS"
		version = "latest"
	}

	storage_os_disk {
		name = "myosdisk1"
		caching = "ReadWrite"
		create_option = "FromImage"
		managed_disk_type = "Standard_LRS"
	}

	os_profile {
		computer_name = "${var.prefix.host}-machine"
		admin_username = "${var.prefix.user}"
		admin_password = "${var.prefix.password}"
	}

	os_profile_linux_config {
		disable_password_authentication = false
		
		ssh_keys {
			path = "/home/${var.prefix.user}/.ssh/authorized_keys"
			key_data = "${file("~/.ssh/id_rsa.pub")} "
		}
	}

	tags = {
		environment = "staging"	
	}
	
	provisioner "remote-exec" {
		inline = [
			"git clone https://github.com/HMSBennett/Jenkins",
			"cd Jenkins",
			"./jenkinsInstall.sh",
			]
		connection{
			type = "ssh"
			user = "${var.prefix.user}"
			private_key = file("/home/${var.prefix.user}/.ssh/id_rsa")
			host = "${azurerm_public_ip.main.fqdn}"
		}
	}
}
