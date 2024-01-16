// Requirements
variable "resourcetags" {
  type        = map
  description = "Common Tags used for these resources"
}

variable "resGroupName" {
    type        = string
    description = "ResourceGroup for Deployment"
}

variable region {
    type        = string
    description = "Region that resources should be deployed"
}

variable "prefix" {
    type        = string
    description = "Prefix of the name of the AVD machine(s) and Resources"
}

// AVD Hostpool Variables
variable "start_vm_on_connect" {
  type          = bool
  default       = true
  description   = "Enables or disables the Start VM on Connection Feature. (default is False)" 
}   

variable "personal_desktop_assignment_type" {
    type        = string
    default     = "Automatic"
    validation {
        condition     = contains(["Automatic", "Direct"], var.personal_desktop_assignment_type)
        error_message = "Possible values Automatic (Auto Assign) or Direct (Admin Assign). Changing this value forces a new resouce to be created!"
    }
}

variable "validate_environment" {
    type        = bool
    default     = false
    description = "Allows you to test service changes before they are deployed to production. (default is False)" 
}

variable "custom_rdp_properties" {
    type        = string
    default     = "audiocapturemode:i:1;audiomode:i:0;"
    description = "A valid custom RDP properties string for the Virtual Desktop Host Pool."
}

variable "poolType" {
    type        = string
    default     = "Personal"
    validation {
        condition     = contains(["Pooled", "Personal"], var.poolType)
        error_message = "Possible values Pooled or Personal."
    }
}

variable "load_balancer_type" {
    type        = string
    default     = "DepthFirst"
    validation {
        condition     = contains(["DepthFirst", "BreadthFirst", "Persistent"], var.load_balancer_type)
        error_message = "Possible values BreadthFirst or DepthFirst for Pooled, and Persistent for Personal"
    }
}

variable "maximum_sessions_allowed" {
    type        = number
    default     = 999999

}


// AVD DAG Variables
variable "DAG_Type" {
    type        = string
    default     = "Desktop"
    validation {
        condition     = contains(["Desktop", "RemoteApp"], var.DAG_Type)
        error_message = "Possible values Desktop or RemoteApp."
    }
}