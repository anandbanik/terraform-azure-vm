#!/bin/sh
echo "Setting environment variables for Terraform"
export ARM_SUBSCRIPTION_ID=4e1a2fb0-7ff7-4dfc-89dd-55e8a7647486
export ARM_CLIENT_ID=4cbdd08e-ecb7-49fb-9ade-11069320bf34
export ARM_CLIENT_SECRET=da2b89ce-58f9-4136-8efa-a4c8138225a5
export ARM_TENANT_ID=fc5be58e-67a5-4d7f-88f6-abf551a10766

# Not needed for public, required for usgovernment, german, china
export ARM_ENVIRONMENT=public