IAC                 =  docker run --rm -v "$(CURDIR)":/infra -v ~/.azure:/root/.azure -w /infra mcr.microsoft.com/azure-cli:latest
TAG_FILE            = .latest_tag

SUB_POC             = 4bd1dd4a-806c-4094-9dc7-35256e6611aa

TENANT             ?= 846acb46-c759-470a-893c-510ff1ffd9ef

# Service Principal 1: Create infrastructure resources
SP1_NAME		   ?= sp-poc
SP1_DESC		   ?= SP POC

KEY_SAVE			= security  add-generic-password
KEY_FIND			= security find-generic-password

MK_PATH             = infrastructure/provisioning
SCRIPT_PATH         = ./$(MK_PATH)/scripts

include $(MK_PATH)/bootstrap.mk

cli-login:
	@echo "Authenticating as admin user..."
	@$(IAC) az login -t $(TENANT) > /dev/null

iac-login:
	@$(SCRIPT_PATH)/sp_login.sh "$(SP1_NAME)" "$(SP1_DESC)" "$(TENANT)" "$(KEY_FIND)" "$(IAC)"