#!/bin/bash
################################################################################
# AVD Installation Verification Script
# This script checks the status of application deployment on session host VMs
################################################################################

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║    AVD Installation Verification Script                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}✗ Azure CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if logged in to Azure
if ! az account show &> /dev/null; then
    echo -e "${RED}✗ Not logged in to Azure. Please run 'az login' first.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Azure CLI is installed and authenticated${NC}"
echo ""

# Get Terraform outputs
echo -e "${YELLOW}Getting deployment information from Terraform...${NC}"

if [ ! -f ".terraform/terraform.tfstate" ] && [ ! -f "terraform.tfstate" ]; then
    echo -e "${RED}✗ Terraform state not found. Please deploy infrastructure first.${NC}"
    exit 1
fi

# Get resource group name
RESOURCE_GROUP=$(terraform output -raw resource_group_name 2>/dev/null)
if [ -z "$RESOURCE_GROUP" ]; then
    echo -e "${RED}✗ Could not get resource group name from Terraform output${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Resource Group: ${RESOURCE_GROUP}${NC}"

# Get VM names
VM_NAMES=$(terraform output -json session_host_vm_names 2>/dev/null | jq -r '.[]' 2>/dev/null)
if [ -z "$VM_NAMES" ]; then
    echo -e "${RED}✗ Could not get VM names from Terraform output${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Found VMs to verify${NC}"
echo ""

# Check each VM
VM_COUNT=0
SUCCESS_COUNT=0
FAILED_COUNT=0

for VM_NAME in $VM_NAMES; do
    VM_COUNT=$((VM_COUNT + 1))
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Checking VM: ${VM_NAME}${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Check if VM exists and is running
    echo -e "${YELLOW}Checking VM status...${NC}"
    VM_STATUS=$(az vm get-instance-view \
        --resource-group "$RESOURCE_GROUP" \
        --name "$VM_NAME" \
        --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus" \
        -o tsv 2>/dev/null || echo "Unknown")
    
    if [ "$VM_STATUS" == "VM running" ]; then
        echo -e "${GREEN}✓ VM is running${NC}"
    else
        echo -e "${RED}✗ VM status: ${VM_STATUS}${NC}"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        continue
    fi
    
    # Check run command status
    echo -e "${YELLOW}Checking application deployment run command...${NC}"
    RUN_COMMAND_EXISTS=$(az vm run-command show \
        --resource-group "$RESOURCE_GROUP" \
        --vm-name "$VM_NAME" \
        --name "avd-app-deployment" 2>/dev/null || echo "")
    
    if [ -z "$RUN_COMMAND_EXISTS" ]; then
        echo -e "${RED}✗ Run command 'avd-app-deployment' not found${NC}"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        continue
    fi
    
    # Get run command provisioning state
    PROVISIONING_STATE=$(az vm run-command show \
        --resource-group "$RESOURCE_GROUP" \
        --vm-name "$VM_NAME" \
        --name "avd-app-deployment" \
        --query "provisioningState" -o tsv 2>/dev/null || echo "Unknown")
    
    echo -e "  Provisioning State: ${PROVISIONING_STATE}"
    
    # Get run command instance view with output
    echo -e "${YELLOW}Fetching run command output...${NC}"
    INSTANCE_VIEW=$(az vm run-command show \
        --resource-group "$RESOURCE_GROUP" \
        --vm-name "$VM_NAME" \
        --name "avd-app-deployment" \
        --instance-view 2>/dev/null)
    
    if [ -n "$INSTANCE_VIEW" ]; then
        # Extract execution state
        EXECUTION_STATE=$(echo "$INSTANCE_VIEW" | jq -r '.instanceView.executionState // "Unknown"')
        EXECUTION_MESSAGE=$(echo "$INSTANCE_VIEW" | jq -r '.instanceView.executionMessage // "No message"')
        EXIT_CODE=$(echo "$INSTANCE_VIEW" | jq -r '.instanceView.exitCode // "N/A"')
        
        echo -e "  Execution State: ${EXECUTION_STATE}"
        echo -e "  Exit Code: ${EXIT_CODE}"
        
        # Extract stdout and stderr
        STDOUT=$(echo "$INSTANCE_VIEW" | jq -r '.instanceView.output // ""')
        STDERR=$(echo "$INSTANCE_VIEW" | jq -r '.instanceView.error // ""')
        
        if [ "$EXECUTION_STATE" == "Succeeded" ] || [ "$EXIT_CODE" == "0" ]; then
            echo -e "${GREEN}✓ Application deployment completed successfully${NC}"
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
            
            # Show last few lines of output
            if [ -n "$STDOUT" ]; then
                echo -e "\n${YELLOW}Last lines of output:${NC}"
                echo "$STDOUT" | tail -10 | sed 's/^/  /'
            fi
        else
            echo -e "${RED}✗ Application deployment failed or is still running${NC}"
            echo -e "  Message: ${EXECUTION_MESSAGE}"
            FAILED_COUNT=$((FAILED_COUNT + 1))
            
            # Show errors if any
            if [ -n "$STDERR" ] && [ "$STDERR" != "null" ]; then
                echo -e "\n${RED}Error output:${NC}"
                echo "$STDERR" | tail -10 | sed 's/^/  /'
            fi
            
            # Show stdout for debugging
            if [ -n "$STDOUT" ]; then
                echo -e "\n${YELLOW}Output:${NC}"
                echo "$STDOUT" | tail -20 | sed 's/^/  /'
            fi
        fi
    else
        echo -e "${YELLOW}⚠ Could not retrieve instance view${NC}"
    fi
    
    # Check AVD agent installation
    echo -e "\n${YELLOW}Checking AVD agent installation...${NC}"
    EXTENSIONS=$(az vm extension list \
        --resource-group "$RESOURCE_GROUP" \
        --vm-name "$VM_NAME" \
        --query "[?contains(name, 'avd') || contains(name, 'hostpool')].{name:name, state:provisioningState}" \
        -o json 2>/dev/null || echo "[]")
    
    if [ "$EXTENSIONS" != "[]" ]; then
        echo "$EXTENSIONS" | jq -r '.[] | "  ✓ \(.name): \(.state)"'
    else
        echo -e "${YELLOW}  No AVD-specific extensions found${NC}"
    fi
    
    echo ""
done

# Summary
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    Verification Summary                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Total VMs checked: ${VM_COUNT}"
echo -e "${GREEN}Successful deployments: ${SUCCESS_COUNT}${NC}"
echo -e "${RED}Failed deployments: ${FAILED_COUNT}${NC}"
echo ""

if [ $FAILED_COUNT -eq 0 ]; then
    echo -e "${GREEN}✓ All application deployments completed successfully!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo -e "  1. Connect to AVD workspace using Azure Virtual Desktop client"
    echo -e "  2. Login with assigned user credentials"
    echo -e "  3. Launch remote applications from the workspace"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Some deployments failed or are incomplete${NC}"
    echo ""
    echo -e "${YELLOW}Troubleshooting steps:${NC}"
    echo -e "  1. RDP to the VM to check manually"
    echo -e "  2. Check VM boot diagnostics in Azure Portal"
    echo -e "  3. Review full run command output in Azure Portal"
    echo -e "  4. Re-run the deployment if needed"
    echo ""
    exit 1
fi
