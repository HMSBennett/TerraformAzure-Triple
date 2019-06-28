resource "azurerm_network_security_group" "third" {
	name = "${var.server}-NSG"
	location = "${azurerm_resource_group.main.location}"
	resource_group_name = "${azurerm_resource_group.main.name}"

	security_rule {
		name = "SSH"
        	priority = 100
        	direction = "Inbound"
        	access = "Allow"
        	protocol = "Tcp"
        	source_port_range = "*" 
        	destination_port_range = "22"
        	source_address_prefix = "*"
        	destination_address_prefix = "*"
	}
	
	security_rule {
                name = "Server"
                priority = 200
                direction = "Inbound"
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
	domain_name_label = "${var.user}${var.server}-${formatdate("DDMMYYhhmmss",timestamp())}"

	tags = {
		environment = "Production"
	}
}

resource "azurerm_network_interface" "third" {
        name = "${var.server}-nic"
        location = "${azurerm_resource_group.main.location}"
        resource_group_name = "${azurerm_resource_group.main.name}"
        network_security_group_id = "${azurerm_network_security_group.third.id}"

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
		admin_username = "hms"
		admin_password = "${var.password}"
	}

	os_profile_linux_config {
		disable_password_authentication = false
		
		ssh_keys {
			path = "/home/hms/.ssh/authorized_keys"
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
			user = "hms"
			private_key = file("/home/hms/.ssh/id_rsa")
			host = "${azurerm_public_ip.third.fqdn}"
		}
	}
}
