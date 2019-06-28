resource "azurerm_resource_group" "main" {
	name = "${var.prefix}-Group"
	location = "uksouth"
}
