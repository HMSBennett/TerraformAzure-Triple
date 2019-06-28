resource "azurerm_network_security_group" "first" {
	name = "${var.host}-NSG"
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

resource "azurerm_public_ip" "first" {
	name = "${var.host}-IP"
	location = "${azurerm_resource_group.main.location}"
	resource_group_name = "${azurerm_resource_group.main.name}"
	allocation_method = "Static"
	domain_name_label = "${var.user}${var.host}-${formatdate("DDMMYYhhmmss",timestamp())}"

	tags = {
		environment = "Production"
	}
}

resource "azurerm_network_interface" "first" {
        name = "${var.host}-nic"
        location = "${azurerm_resource_group.main.location}"
        resource_group_name = "${azurerm_resource_group.main.name}"
	network_security_group_id = "${azurerm_network_security_group.first.id}"

        ip_configuration {
                name = "${var.host}-IP-Config"
                subnet_id = "${azurerm_subnet.internal.id}"
                private_ip_address_allocation = "Dynamic"
		public_ip_address_id = "${azurerm_public_ip.first.id}"
        }
}

resource "azurerm_virtual_machine" "first" {
	name = "${var.host}-vm"
	location = "${azurerm_resource_group.main.location}"
	resource_group_name = "${azurerm_resource_group.main.name}"
	network_interface_ids = ["${azurerm_network_interface.first.id}"]
	vm_size = "Standard_B1MS"

	storage_image_reference {
		publisher = "Canonical"
		offer = "UbuntuServer"
		sku = "16.04-LTS"
		version = "latest"
	}

	storage_os_disk {
		name = "hostosdisk"
		caching = "ReadWrite"
		create_option = "FromImage"
		managed_disk_type = "Standard_LRS"
	}

	os_profile {
		computer_name = "${var.host}-machine"
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
			"git clone https://github.com/HMSBennett/Jenkins",
			"cd Jenkins",
			"./jenkinsInstall.sh",
			]
		connection{
			type = "ssh"
			user = "hms"
			private_key = file("/home/hms/.ssh/id_rsa")
			host = "${azurerm_public_ip.first.fqdn}"
		}
	}

	provisioner "local-exec" {
		command = "yes y | ssh-keygen -t rsa -f /home/hms/.ssh/id_rsa -q -P ''"
	}

	provisioner "local-exec" {
		command = "ssh-copy-id ${azurerm_public_id.first.domain_name_label}"
	}

        provisioner "local-exec" {
                command = "ssh ${azurerm_public_id.first.domain_name_label}"
        }

        provisioner "local-exec" {
                command = "yes y | ssh-keygen -t rsa -f /home/hms/.ssh/id_rsa -q -P ''"
        }
        
	provisioner "local-exec" {
                command = "ssh-copy-id ${azurerm_public_id.second.domain_name_label}"
        }

        provisioner "local-exec" {
                command = "ssh ${azurerm_public_id.second.domain_name_label}"
        }

        provisioner "local-exec" {
                command = "yes y | ssh-keygen -t rsa -f /home/hms/.ssh/id_rsa -q -P ''"
        }

        provisioner "local-exec" {
                command = "ssh-copy-id ${azurerm_public_id.third.domain_name_label}"
        }

        provisioner "local-exec" {
                command = "exit"
        }

        provisioner "local-exec" {
                command = "exit"
        }
}
