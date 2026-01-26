################################################################################
# Application Deployment Module - Main Configuration
# Deploys applications via Run Command with inline PowerShell
################################################################################

# Run Command Extension for application deployment on each session host
# Using RunCommand instead of CustomScript because Windows only allows one CustomScriptExtension
resource "azurerm_virtual_machine_run_command" "app_deployment" {
  count              = length(var.vm_ids)
  name               = "avd-app-deployment"
  location           = var.location
  virtual_machine_id = var.vm_ids[count.index]

  source {
    script = <<-EOF
      Write-Host "Starting AVD Application Deployment..." -ForegroundColor Green
      
      # Error handling
      $ErrorActionPreference = "Stop"
      
      # Ensure script runs in 64-bit PowerShell
      if ([System.Environment]::Is64BitProcess -eq $false) {
          Write-Host "Running 64-bit PowerShell..." -ForegroundColor Yellow
          & "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList $MyInvocation.MyCommand.Definition
          exit
      }
      
      # Install Chocolatey (package manager for easy installation)
      Write-Host "Installing Chocolatey..." -ForegroundColor Cyan
      try {
          if (-not (Test-Path "C:\ProgramData\chocolatey\bin\choco.exe")) {
              [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
              Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
              Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
              Write-Host "Chocolatey installed successfully" -ForegroundColor Green
          } else {
              Write-Host "Chocolatey already installed" -ForegroundColor Green
          }
      } catch {
          Write-Host "Chocolatey installation failed: $_" -ForegroundColor Yellow
      }
      
      # Add Chocolatey to PATH
      $env:Path += ";C:\ProgramData\chocolatey\bin"
      
      # Define applications with Chocolatey package names
      $applicationsToInstall = @(
          @{ name = "Microsoft Edge"; package = "microsoft-edge"; args = "" },
          @{ name = "Notepad++"; package = "notepadplusplus"; args = "" },
          @{ name = "7Zip"; package = "7zip"; args = "" },
          @{ name = "Git"; package = "git"; args = "" },
          @{ name = "Github Desktop"; package = "github-desktop"; args = "" },
          @{ name = "Visual Studio Code"; package = "vscode"; args = "" },
          @{ name = "Visual Studio Code Insiders"; package = "vscode-insiders"; args = "" }
      )
      
      # Install applications via Chocolatey
      Write-Host "Installing applications..." -ForegroundColor Cyan
      foreach ($app in $applicationsToInstall) {
          try {
              Write-Host "Installing $($app.name)..." -ForegroundColor Yellow
              & choco install $($app.package) -y --limit-output --no-progress 2>&1 | Out-Null
              Write-Host "$($app.name) installed" -ForegroundColor Green
          } catch {
              Write-Host "Failed to install $($app.name): $_" -ForegroundColor Yellow
          }
      }
      
      Write-Host "Application deployment completed successfully!" -ForegroundColor Green
    EOF
  }

  timeouts {
    create = "60m"
    delete = "30m"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "app-deployment-${count.index + 1}"
    }
  )
}
