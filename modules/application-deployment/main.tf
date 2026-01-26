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
      Write-Host "========================================" -ForegroundColor Cyan
      Write-Host "Starting AVD Application Deployment..." -ForegroundColor Green
      Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
      Write-Host "========================================" -ForegroundColor Cyan
      
      # Error handling - Continue on error to install as many apps as possible
      $ErrorActionPreference = "Continue"
      $SuccessCount = 0
      $FailCount = 0
      
      # Create log directory
      $LogDir = "C:\AVD-Deployment-Logs"
      $LogFile = "$LogDir\app-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
      New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
      
      function Write-Log {
          param($Message, $Color = "White")
          $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
          $LogMessage = "[$Timestamp] $Message"
          Write-Host $Message -ForegroundColor $Color
          Add-Content -Path $LogFile -Value $LogMessage
      }
      
      Write-Log "Log file: $LogFile" -Color Cyan
      
      # Ensure script runs in 64-bit PowerShell
      if ([System.Environment]::Is64BitProcess -eq $false) {
          Write-Log "Switching to 64-bit PowerShell..." -Color Yellow
          & "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -File $MyInvocation.MyCommand.Definition
          exit $LASTEXITCODE
      }
      
      # Install Chocolatey (package manager for easy installation)
      Write-Log "Installing Chocolatey package manager..." -Color Cyan
      try {
          if (-not (Test-Path "C:\ProgramData\chocolatey\bin\choco.exe")) {
              Write-Log "Downloading and installing Chocolatey..." -Color Yellow
              [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
              Set-ExecutionPolicy Bypass -Scope Process -Force
              $ChocoInstallScript = Invoke-WebRequest -Uri 'https://community.chocolatey.org/install.ps1' -UseBasicParsing
              Invoke-Expression $ChocoInstallScript.Content
              
              if (Test-Path "C:\ProgramData\chocolatey\bin\choco.exe") {
                  Write-Log "Chocolatey installed successfully" -Color Green
                  $SuccessCount++
              } else {
                  Write-Log "Chocolatey installation verification failed" -Color Red
                  $FailCount++
              }
          } else {
              Write-Log "Chocolatey already installed" -Color Green
          }
      } catch {
          Write-Log "Chocolatey installation failed: $($_.Exception.Message)" -Color Red
          Write-Log "Attempting to continue with pre-installed tools..." -Color Yellow
          $FailCount++
      }
      
      # Refresh environment and add Chocolatey to PATH
      $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
      $env:ChocolateyInstall = "C:\ProgramData\chocolatey"
      
      # Verify choco is available
      $ChocoAvailable = $false
      try {
          $ChocoVersion = & choco --version 2>&1
          Write-Log "Chocolatey version: $ChocoVersion" -Color Cyan
          $ChocoAvailable = $true
      } catch {
          Write-Log "Chocolatey not available in PATH" -Color Red
      }
      
      if ($ChocoAvailable) {
          # Define applications with Chocolatey package names
          $applicationsToInstall = @(
              @{ name = "Microsoft Edge"; package = "microsoft-edge" },
              @{ name = "Notepad++"; package = "notepadplusplus" },
              @{ name = "7-Zip"; package = "7zip" },
              @{ name = "Git"; package = "git" },
              @{ name = "GitHub Desktop"; package = "github-desktop" },
              @{ name = "Visual Studio Code"; package = "vscode" },
              @{ name = "VS Code Insiders"; package = "vscode-insiders" }
          )
          
          Write-Log "========================================" -Color Cyan
          Write-Log "Installing $($applicationsToInstall.Count) applications..." -Color Cyan
          Write-Log "========================================" -Color Cyan
          
          # Install applications via Chocolatey
          foreach ($app in $applicationsToInstall) {
              try {
                  Write-Log "Installing $($app.name)..." -Color Yellow
                  $InstallOutput = & choco install $($app.package) -y --no-progress --limit-output 2>&1
                  
                  if ($LASTEXITCODE -eq 0) {
                      Write-Log "✓ $($app.name) installed successfully" -Color Green
                      $SuccessCount++
                  } else {
                      Write-Log "✗ $($app.name) installation returned exit code $LASTEXITCODE" -Color Red
                      Write-Log "  Output: $InstallOutput" -Color Yellow
                      $FailCount++
                  }
              } catch {
                  Write-Log "✗ Failed to install $($app.name): $($_.Exception.Message)" -Color Red
                  $FailCount++
              }
              Start-Sleep -Seconds 2
          }
      } else {
          Write-Log "Skipping application installation - Chocolatey not available" -Color Red
      }
      
      # Summary
      Write-Log "========================================" -Color Cyan
      Write-Log "Deployment Summary" -Color Cyan
      Write-Log "========================================" -Color Cyan
      Write-Log "Successful installations: $SuccessCount" -Color Green
      Write-Log "Failed installations: $FailCount" -Color $(if ($FailCount -gt 0) { "Red" } else { "Green" })
      Write-Log "Log file saved to: $LogFile" -Color Cyan
      Write-Log "========================================" -Color Cyan
      
      if ($FailCount -eq 0) {
          Write-Log "✓ Application deployment completed successfully!" -Color Green
          exit 0
      } elseif ($SuccessCount -gt 0) {
          Write-Log "⚠ Application deployment completed with some failures" -Color Yellow
          exit 0
      } else {
          Write-Log "✗ Application deployment failed" -Color Red
          exit 1
      }
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
