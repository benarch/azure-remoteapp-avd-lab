################################################################################
# Application Groups Module - Main Configuration
# Creates Desktop and RemoteApp application groups
# Note: Using local user authentication - no AAD user assignment
################################################################################

# Desktop Application Group
resource "azurerm_virtual_desktop_application_group" "desktop" {
  name                = var.desktop_app_group_name
  location            = var.location
  resource_group_name = var.resource_group_name
  host_pool_id        = var.host_pool_id
  type                = "Desktop"
  friendly_name       = "Default Desktop"
  description         = "Default desktop application group"

  tags = merge(
    var.common_tags,
    {
      Name = var.desktop_app_group_name
    }
  )
}

# RemoteApp Application Group (Primary)
resource "azurerm_virtual_desktop_application_group" "remoteapp" {
  name                = var.remoteapp_app_group_name
  location            = var.location
  resource_group_name = var.resource_group_name
  host_pool_id        = var.host_pool_id
  type                = "RemoteApp"
  friendly_name       = "RemoteApp Applications"
  description         = "RemoteApp application group for published applications"

  tags = merge(
    var.common_tags,
    {
      Name = var.remoteapp_app_group_name
    }
  )
}

# Link RemoteApp Application Group to Workspace
resource "azurerm_virtual_desktop_workspace_application_group_association" "remoteapp" {
  workspace_id         = var.workspace_id
  application_group_id = azurerm_virtual_desktop_application_group.remoteapp.id
}

# Link Desktop Application Group to Workspace
resource "azurerm_virtual_desktop_workspace_application_group_association" "desktop" {
  workspace_id         = var.workspace_id
  application_group_id = azurerm_virtual_desktop_application_group.desktop.id
}

################################################################################
# RemoteApp Applications - Publish applications to the RemoteApp group
################################################################################

# File Explorer
resource "azurerm_virtual_desktop_application" "file_explorer" {
  name                         = "FileExplorer"
  application_group_id         = azurerm_virtual_desktop_application_group.remoteapp.id
  friendly_name                = "File Explorer"
  description                  = "Windows File Explorer"
  path                         = "C:\\Windows\\explorer.exe"
  command_line_argument_policy = "DoNotAllow"
  show_in_portal               = true
  icon_path                    = "C:\\Windows\\explorer.exe"
  icon_index                   = 0
}

# Microsoft Edge
resource "azurerm_virtual_desktop_application" "edge" {
  name                         = "MicrosoftEdge"
  application_group_id         = azurerm_virtual_desktop_application_group.remoteapp.id
  friendly_name                = "Microsoft Edge"
  description                  = "Microsoft Edge Browser"
  path                         = "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe"
  command_line_argument_policy = "DoNotAllow"
  show_in_portal               = true
  icon_path                    = "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe"
  icon_index                   = 0
}

# Task Manager
resource "azurerm_virtual_desktop_application" "taskmgr" {
  name                         = "TaskManager"
  application_group_id         = azurerm_virtual_desktop_application_group.remoteapp.id
  friendly_name                = "Task Manager"
  description                  = "Windows Task Manager"
  path                         = "C:\\Windows\\System32\\Taskmgr.exe"
  command_line_argument_policy = "DoNotAllow"
  show_in_portal               = true
  icon_path                    = "C:\\Windows\\System32\\Taskmgr.exe"
  icon_index                   = 0
}

# Notepad (Built-in)
resource "azurerm_virtual_desktop_application" "notepad" {
  name                         = "Notepad"
  application_group_id         = azurerm_virtual_desktop_application_group.remoteapp.id
  friendly_name                = "Notepad"
  description                  = "Windows Notepad"
  path                         = "C:\\Windows\\System32\\notepad.exe"
  command_line_argument_policy = "DoNotAllow"
  show_in_portal               = true
  icon_path                    = "C:\\Windows\\System32\\notepad.exe"
  icon_index                   = 0
}

# Notepad++
resource "azurerm_virtual_desktop_application" "notepadplusplus" {
  name                         = "NotepadPlusPlus"
  application_group_id         = azurerm_virtual_desktop_application_group.remoteapp.id
  friendly_name                = "Notepad++"
  description                  = "Notepad++ Text Editor"
  path                         = "C:\\Program Files\\Notepad++\\notepad++.exe"
  command_line_argument_policy = "DoNotAllow"
  show_in_portal               = true
  icon_path                    = "C:\\Program Files\\Notepad++\\notepad++.exe"
  icon_index                   = 0
}

# Visual Studio Code
resource "azurerm_virtual_desktop_application" "vscode" {
  name                         = "VisualStudioCode"
  application_group_id         = azurerm_virtual_desktop_application_group.remoteapp.id
  friendly_name                = "Visual Studio Code"
  description                  = "Visual Studio Code Editor"
  path                         = "C:\\Program Files\\Microsoft VS Code\\Code.exe"
  command_line_argument_policy = "DoNotAllow"
  show_in_portal               = true
  icon_path                    = "C:\\Program Files\\Microsoft VS Code\\Code.exe"
  icon_index                   = 0
}

# Visual Studio Code Insiders
resource "azurerm_virtual_desktop_application" "vscode_insiders" {
  name                         = "VisualStudioCodeInsiders"
  application_group_id         = azurerm_virtual_desktop_application_group.remoteapp.id
  friendly_name                = "Visual Studio Code Insiders"
  description                  = "Visual Studio Code Insiders Edition"
  path                         = "C:\\Program Files\\Microsoft VS Code Insiders\\Code - Insiders.exe"
  command_line_argument_policy = "DoNotAllow"
  show_in_portal               = true
  icon_path                    = "C:\\Program Files\\Microsoft VS Code Insiders\\Code - Insiders.exe"
  icon_index                   = 0
}

# Git Bash
resource "azurerm_virtual_desktop_application" "git_bash" {
  name                         = "GitBash"
  application_group_id         = azurerm_virtual_desktop_application_group.remoteapp.id
  friendly_name                = "Git Bash"
  description                  = "Git Bash Terminal"
  path                         = "C:\\Program Files\\Git\\git-bash.exe"
  command_line_argument_policy = "DoNotAllow"
  show_in_portal               = true
  icon_path                    = "C:\\Program Files\\Git\\git-bash.exe"
  icon_index                   = 0
}

# 7-Zip File Manager
resource "azurerm_virtual_desktop_application" "sevenzip" {
  name                         = "SevenZip"
  application_group_id         = azurerm_virtual_desktop_application_group.remoteapp.id
  friendly_name                = "7-Zip File Manager"
  description                  = "7-Zip Archive Manager"
  path                         = "C:\\Program Files\\7-Zip\\7zFM.exe"
  command_line_argument_policy = "DoNotAllow"
  show_in_portal               = true
  icon_path                    = "C:\\Program Files\\7-Zip\\7zFM.exe"
  icon_index                   = 0
}
