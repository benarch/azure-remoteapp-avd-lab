# AVD Environment Post-Deployment Details

## Access Methods

### Windows App (Recommended)
The Windows App is the replacement for the Remote Desktop client on macOS.

**Download**: [Windows App on Mac App Store](https://apps.apple.com/app/windows-app/id1295203466)

### Windows App Web
Access directly from your browser:

**URL**: https://windows.cloud.microsoft/

---

## Local User Credentials

The following local users are created on each session host VM:

| Username   | Password           | Description       |
|------------|--------------------|--------------------|
| `avduser1` | `LocalUser123456!` | AVD Local User 1   |
| `avduser2` | `LocalUser123456!` | AVD Local User 2   |
| `avduser3` | `LocalUser123456!` | AVD Local User 3   |
| `avduser4` | `LocalUser123456!` | AVD Local User 4   |

> **Note**: These passwords are set via the `local_user_password` variable in `terraform.tfvars.password`. Update them before deployment for production use.

---

## Admin Credentials

| Username   | Password           | Description              |
|------------|--------------------| --------------------------|
| `avdadmin` | `AvdAdmin123456!`  | VM Administrator Account  |

> **Note**: The admin password is set via `vm_admin_password` variable.

---

## Connection Instructions

### Option 1: Windows App (macOS)

1. Install **Windows App** from the Mac App Store
2. Open the app and sign in (or skip if not using Azure AD)
3. Click **Add Workspace** or **Add PC**
4. For direct RDP connection:
   - Enter the session host private IP or hostname
   - Use credentials: `hostname\avduser1` (e.g., `sh-dev-vm-1-dev\avduser1`)
   - Enter password: `LocalUser123456!`

### Option 2: Windows App Web

1. Go to https://windows.cloud.microsoft/
2. Sign in with your Microsoft account (if required)
3. For direct RDP, you may need to use a VPN or Bastion to reach the private network
4. Connect using local credentials as shown above

### Option 3: Direct RDP (if network accessible)

1. Open any RDP client
2. Connect to session host private IP (e.g., `192.168.100.x`)
3. Username: `sh-dev-vm-1-dev\avduser1` (format: `hostname\username`)
4. Password: `LocalUser123456!`

---

## Environment Details

| Setting                | Dev Value              | Prod Value              |
|------------------------|------------------------|-------------------------|
| Resource Group         | `rg-avd-lab1-dev`      | `rg-avd-lab1-prod`      |
| Host Pool              | `hpl-avd-lab1-dev`     | `hpl-avd-lab1-prod`     |
| Workspace              | `ws-avd-lab1-dev`      | `ws-avd-lab1-prod`      |
| Desktop App Group      | `dag-avd-lab1-desktop-dev` | `dag-avd-lab1-desktop-prod` |
| RemoteApp App Group    | `dag-avd-lab1-remoteapp-dev` | `dag-avd-lab1-remoteapp-prod` |
| Session Host VM Prefix | `sh-dev-`              | `sh-prod-`              |

---

## Network Information

| Setting          | Value                |
|------------------|----------------------|
| VNet CIDR        | `192.168.100.0/22`   |
| AVD Subnet       | `192.168.100.0/24`   |
| Bastion Subnet   | `192.168.101.0/24`   |

---

## Security Notes

⚠️ **Important**: 
- Change all default passwords before production deployment
- The passwords shown above are defaults from `terraform.tfvars.password`
- Consider using Azure Key Vault for production password management
- Restrict network access using NSG rules for production environments

---

## Troubleshooting

### Cannot connect to session host
1. Verify VM is running: `az vm get-instance-view -g rg-avd-lab1-dev -n sh-dev-vm-1-dev`
2. Check private IP: `terraform output session_host_private_ips`
3. Ensure network connectivity (VPN/Bastion may be required)

### Login fails with local user
1. Use format: `hostname\username` (e.g., `sh-dev-vm-1-dev\avduser1`)
2. Verify local users were created (check CustomScriptExtension logs)
3. RDP directly and check: `net user` to list local accounts

### Session host not registered
1. Check DSC extension status in Azure Portal
2. Verify registration token is valid (expires after set period)
3. Review host pool session hosts in Azure Virtual Desktop portal

---

**Last Updated**: 2026-01-29  
**Project**: AVD Lab 1  
**Authentication**: Local Users (No AD/Entra Join)
