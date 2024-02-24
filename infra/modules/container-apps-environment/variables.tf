variable "name" {
  description = "The name of the container app environment"
  type        = string
}

variable "location" {
  description = "The location to create the container app environment"
  type        = string
  default     = "Resource Group Location" # This needs to be replaced with actual resource group location if not dynamic
}

variable "internal" {
  description = "Indicates if the environment is internal"
  type        = bool
  default     = true
}

variable "infrastructure_subnet_id" {
  description = "The ID of the infrastructure subnet"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace"
  type        = string
  
}