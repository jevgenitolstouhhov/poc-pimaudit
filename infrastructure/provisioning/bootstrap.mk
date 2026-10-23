.PHONY: sp-create-poc

sp-create-poc:
	@echo "🔐 Verifying ambient administrative login session..."
	@USER=$$($(IAC) az account show --query "user.name" -o tsv 2>/dev/null); \
	if [ -z "$$USER" ]; then \
		echo "❌ Error: You must be logged into 'az login' with your personal admin credentials first."; \
		exit 1; \
	fi; \
	echo "👤 Authenticated as: $$USER"

	@echo "🔍 Checking if Service Principal '$(SP1_NAME)' already exists in Entra ID..."; \
	APP_ID=$$($(IAC) az ad sp list --display-name "$(SP1_NAME)" --query "[0].appId" -o tsv 2>/dev/null); \
	if [ -n "$$APP_ID" ]; then \
		echo "🔄 Identity found ($$APP_ID). Rotating expired/existing credentials..."; \
		PAYLOAD=$$($(IAC) az ad sp credential reset --id "$$APP_ID" \
			--years 1 --query '[appId, password]' -o tsv 2>/dev/null); \
	else \
		echo "🚀 Principal does not exist. Provisioning fresh identity & configuring Contributor RBAC..."; \
		PAYLOAD=$$($(IAC) az ad sp create-for-rbac --name "$(SP1_NAME)" --skip-assignment \
			--years 1 --query '[appId, password]' -o tsv 2>/dev/null); \
	fi; \
	if [ -z "$$PAYLOAD" ]; then \
		echo "❌ Error: Failed to retrieve token payload from Entra graph engine. Make sure you are authenticated as admin."; \
		exit 1; \
	fi; \
	\
	TOKENS=( $$PAYLOAD ); APP_ID=$${TOKENS[0]}; SECRET=$${TOKENS[1]}; \
	\
	echo "🤝 Assigning 'Contributor' role..."; \
	$(IAC) az role assignment create --assignee "$$APP_ID" --role "Contributor" \
		--scope "/subscriptions/$(SUB_POC)" >/dev/null; \
	\
	echo "🔒 Sealing generated tokens into securely hardware-backed macOS Keychain records..."; \
	$(KEY_SAVE) -a "$(SP1_NAME)-app-id" -s "$(SP1_DESC)" -w "$$APP_ID" -U; \
	$(KEY_SAVE) -a "$(SP1_NAME)-secret" -s "$(SP1_DESC)" -w "$$SECRET" -U; \
	echo "ℹ️  App ID registered for $(SP1_NAME): $$APP_ID"