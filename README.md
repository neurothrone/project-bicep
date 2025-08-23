# Project Bicep

## Login

Login to Azure CLI with the following command and choose the subscription you want to deploy to.

```shell
az login
```

## Create the Resource Groups

The commands below assume that you have a `secrets.json` file with the secrets for the key vaults. You can find an
example in the `secrets.example.json` file or rename it to `secrets.json` and fill in the secrets.

The commands below will create the resources for the dev, test and prod environments.

> **Note:** The commands below assume that you are in the `project-bicep` (root) directory.

```shell
# Create the resources for the dev environment
az deployment sub create \
  --location swedencentral \
  --template-file main.bicep \
  --parameters @infra/parameters/dev.json \
  --parameters @infra/secrets.json

# Create the resources for the test environment
az deployment sub create \
  --location swedencentral \
  --template-file main.bicep \
  --parameters @infra/parameters/test.json \
  --parameters @infra/secrets.json

# Create the resources for the prod environment
az deployment sub create \
  --location swedencentral \
  --template-file main.bicep \
  --parameters @infra/parameters/prod.json \
  --parameters @infra/secrets.json
```

## Tips

### Bicep

#### Useful links

- https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/
- https://learn.microsoft.com/en-us/azure/templates/
- https://azure.github.io/bicep/

### Key Vault secret names

Azure Key Vault secret names must follow these rules:

- Can contain only alphanumeric characters and dashes (-)
- Cannot use underscores (_), spaces, or special characters
- Must be between 1 and 127 characters
- Are case-insensitive

#### Links

- https://learn.microsoft.com/en-us/azure/key-vault/general/about-keys-secrets-certificates

### Purge the Key Vaults

If, like me, you have been a bit too enthusiastic with your key vault experiments and now face conflicts, you can purge
them with the following commands.

```shell
az keyvault list-deleted

az keyvault purge --name <keyvault-name>
```

