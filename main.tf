terraform {
  required_version = ">= 1.8"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.7.0"
    }
  }
}

variable "subscription_id" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "resources_suffix" {
  type = string
}

variable "location" {
  type = string
}

provider "azurerm" {
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

resource "azurerm_resource_group" "main" {
  name     = "resource-group-${var.resources_suffix}"
  location = var.location
}

resource "azurerm_service_plan" "consumption" {
  name                = "app-service-plan-${var.resources_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "P0v3"
}

resource "azurerm_application_insights" "insights" {
  name                = "app-insights-${var.resources_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  application_type    = "web"
}

resource "azurerm_storage_account" "storage" {
  name                     = "stor${var.resources_suffix}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_linux_function_app" "func_app" {
  name                       = "func-app-${var.resources_suffix}"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  service_plan_id            = azurerm_service_plan.consumption.id
  storage_account_name       = azurerm_storage_account.storage.name
  storage_account_access_key = azurerm_storage_account.storage.primary_access_key

  site_config {
    application_stack {
      //python_version = 3.12
      //powershell_core_version = 7
      node_version = "20"
    }
    application_insights_key               = azurerm_application_insights.insights.instrumentation_key
    application_insights_connection_string = azurerm_application_insights.insights.connection_string
    always_on                              = true
  }
}

resource "azurerm_function_app_function" "func_app_func" {
  name            = "func"
  function_app_id = azurerm_linux_function_app.func_app.id
  language        = "Javascript"

  file {
    name    = "func.py"
    content = file("funcs/func.js")
  }

  config_json = jsonencode({
    "bindings" = [
      {
        "authLevel" = "anonymous"
        "name"      = "req"
        "type"      = "httpTrigger"
        "direction" = "in"
        "methods" : [
          "get"
        ]
      },
      {
        "type" : "http",
        "direction" : "out",
        "name" : "res"
      }
    ]
  })
}
