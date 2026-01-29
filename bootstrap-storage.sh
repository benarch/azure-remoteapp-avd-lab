#!/bin/bash

################################################################################
# Azure Storage Account Bootstrap Script for Terraform State Management
# This script creates a resource group, storage account, and blob container
# for Terraform remote state management with dev/prod workspace support
################################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
LOCATION="${LOCATION:-eastus}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
PROJECT_NAME="avd-lab1"
RANDOM_SUFFIX=$(date +%s | tail -c 4)

# Derived names
STORAGE_RG_NAME="rg-${PROJECT_NAME}-tfstate-${ENVIRONMENT}"
STORAGE_ACCOUNT_NAME="st${PROJECT_NAME//-/}${RANDOM_SUFFIX}"
CONTAINER_NAME="tfstate"

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Azure Storage Bootstrap for Terraform${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# Step 1: Validate Azure CLI login
echo -e "${YELLOW}[1/5]${NC} Validating Azure CLI authentication..."
if ! az account show > /dev/null 2>&1; then
    echo -e "${RED}❌ Not logged in to Azure CLI${NC}"
    echo "Run: az login"
    exit 1
fi

CURRENT_SUBSCRIPTION=$(az account show --query id -o tsv)
CURRENT_TENANT=$(az account show --query tenantId -o tsv)
CURRENT_USER=$(az account show --query user.name -o tsv)

echo -e "${GREEN}✓${NC} Authenticated as: ${CURRENT_USER}"
echo -e "${GREEN}✓${NC} Subscription ID: ${CURRENT_SUBSCRIPTION}"
echo -e "${GREEN}✓${NC} Tenant ID: ${CURRENT_TENANT}"
echo ""

# Step 2: Validate storage account name uniqueness
echo -e "${YELLOW}[2/5]${NC} Checking storage account name availability..."
ATTEMPT=0
MAX_ATTEMPTS=5

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if az storage account check-name --name "$STORAGE_ACCOUNT_NAME" --query nameAvailable -o tsv | grep -q "true"; then
        echo -e "${GREEN}✓${NC} Storage account name available: ${STORAGE_ACCOUNT_NAME}"
        break
    else
        ATTEMPT=$((ATTEMPT + 1))
        if [ $ATTEMPT -lt $MAX_ATTEMPTS ]; then
            RANDOM_SUFFIX=$((RANDOM_SUFFIX + 1))
            STORAGE_ACCOUNT_NAME="st${PROJECT_NAME//-/}${RANDOM_SUFFIX}"
            echo -e "${YELLOW}⚠${NC} Attempting alternative name: ${STORAGE_ACCOUNT_NAME}"
        else
            echo -e "${RED}❌ Failed to find available storage account name${NC}"
            exit 1
        fi
    fi
done
echo ""

# Step 3: Create resource group
echo -e "${YELLOW}[3/5]${NC} Creating resource group: ${STORAGE_RG_NAME}..."
if az group exists --name "$STORAGE_RG_NAME" | grep -q "true"; then
    echo -e "${YELLOW}⚠${NC} Resource group already exists: ${STORAGE_RG_NAME}"
else
    az group create \
        --name "$STORAGE_RG_NAME" \
        --location "$LOCATION" \
        > /dev/null
    echo -e "${GREEN}✓${NC} Resource group created"
fi
echo ""

# Step 4: Create storage account
echo -e "${YELLOW}[4/5]${NC} Creating storage account: ${STORAGE_ACCOUNT_NAME}..."
az storage account create \
    --resource-group "$STORAGE_RG_NAME" \
    --name "$STORAGE_ACCOUNT_NAME" \
    --location "$LOCATION" \
    --sku "Standard_LRS" \
    --kind "StorageV2" \
    --https-only true \
    --access-tier "Hot" \
    --enable-hierarchical-namespace false \
    --min-tls-version "TLS1_2" \
    > /dev/null

echo -e "${GREEN}✓${NC} Storage account created"

# Enable versioning and soft delete
az storage account blob-service-properties update \
    --resource-group "$STORAGE_RG_NAME" \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --enable-versioning true \
    --enable-change-feed true \
    --enable-delete-retention true \
    --delete-retention-days 14 \
    > /dev/null

echo -e "${GREEN}✓${NC} Versioning and soft delete enabled (14-day retention)"
echo ""

# Step 5: Create blob container
echo -e "${YELLOW}[5/5]${NC} Creating blob container: ${CONTAINER_NAME}..."
az storage container create \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --name "$CONTAINER_NAME" \
    --public-access off \
    --auth-mode login \
    > /dev/null

echo -e "${GREEN}✓${NC} Blob container created"
echo ""

# Retrieve and display configuration
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Bootstrap Complete - Configuration Details${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""
echo "Resource Group:      ${STORAGE_RG_NAME}"
echo "Storage Account:     ${STORAGE_ACCOUNT_NAME}"
echo "Container Name:      ${CONTAINER_NAME}"
echo "Location:            ${LOCATION}"
echo ""

# Get storage account credentials
STORAGE_ACCOUNT_KEY=$(az storage account keys list \
    --resource-group "$STORAGE_RG_NAME" \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --query '[0].value' -o tsv)

echo -e "${YELLOW}Backend Configuration:${NC}"
echo ""
echo "Add the following to your 'backend.tf' or use with 'terraform init':"
echo ""
echo "  backend \"azurerm\" {"
echo "    resource_group_name  = \"${STORAGE_RG_NAME}\""
echo "    storage_account_name = \"${STORAGE_ACCOUNT_NAME}\""
echo "    container_name       = \"${CONTAINER_NAME}\""
echo "    key                  = \"env:/\${terraform.workspace}/terraform.tfstate\""
echo "  }"
echo ""

echo -e "${YELLOW}Export these for Terraform (optional):${NC}"
echo ""
echo "  export ARM_RESOURCE_GROUP_NAME=\"${STORAGE_RG_NAME}\""
echo "  export ARM_STORAGE_ACCOUNT_NAME=\"${STORAGE_ACCOUNT_NAME}\""
echo "  export ARM_STORAGE_ACCOUNT_KEY=\"${STORAGE_ACCOUNT_KEY}\""
echo ""

echo -e "${YELLOW}Next Steps:${NC}"
echo ""
echo "1. Copy the backend configuration above to 'backend.tf'"
echo "2. Run: terraform init -reconfigure"
echo "3. Create workspaces:"
echo "   - terraform workspace new dev"
echo "   - terraform workspace new prod"
echo "4. Deploy:"
echo "   - terraform workspace select dev"
echo "   - terraform plan -var-file=terraform.tfvars.dev"
echo "   - terraform apply -var-file=terraform.tfvars.dev"
echo ""
echo -e "${GREEN}✓ Bootstrap completed successfully!${NC}"
