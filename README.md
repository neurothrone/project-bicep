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
  --template-file infra/main.bicep \
  --parameters @infra/parameters/dev.json \
  --parameters @infra/secrets.json \
  --confirm-with-what-if

# Create the resources for the test environment
az deployment sub create \
  --location swedencentral \
  --template-file infra/main.bicep \
  --parameters @infra/parameters/test.json \
  --parameters @infra/secrets.json \
  --confirm-with-what-if

# Create the resources for the prod environment
az deployment sub create \
  --location swedencentral \
  --template-file infra/main.bicep \
  --parameters @infra/parameters/prod.json \
  --parameters @infra/secrets.json \
  --confirm-with-what-if
```

## Tips

### Bicep

#### Useful links

- https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/
- https://learn.microsoft.com/en-us/azure/templates/
- https://azure.github.io/bicep/

### Secrets

#### Key Vault secret names

Azure Key Vault secret names must follow these rules:

- Can contain only alphanumeric characters and dashes (\-)
- Cannot use underscores (\_), spaces, or special characters
- Must be between 1 and 127 characters
- Are case-insensitive

Examples:

- **Valid**: `favorite-color`, `color1`
- **Invalid**: `favorite_color`, `COLOR VALUE`

##### Links

- https://learn.microsoft.com/en-us/azure/key-vault/general/about-keys-secrets-certificates

#### App settings (Web App) name rules

App settings names must follow these rules:

- Can contain only letters, numbers (0–9), periods (.), and underscores (_)
- Dashes (\-) are not allowed

Examples:

- **Valid**: `FAVORITE_COLOR`, `favoriteColor`
- **Invalid**: `favorite-color`

##### Links

- https://learn.microsoft.com/en-us/azure/app-service/configure-common#configure-app-settings

#### One name that works for both (recommended)

If you use the same key as the Key Vault secret name and the App Service app setting (Key Vault reference), pick a
format valid for both:

- Use letters and numbers only (e.g., camelCase)
- **Recommended**: `favoriteColor`, `secretColor`
- **Avoid**: `SECRET_COLOR` (Key Vault rejects \_), `SECRET-COLOR` (App settings reject \-)

### What‑If noise around Key Vault

What‑If can show false positives for Key Vault and app settings that reference it. Here are some of the issues that you
can expect to see:

- ***Symptom***: `.../accessPolicies/add (Unsupported)`:
    - ***Why***: What‑If cannot read `accessPolicies` when the parent Key Vault is not yet created, and this child type does
      not fully support What‑If.
    - ***Impact***: Not a deployment failure.

- ***Symptom***: `NestedDeploymentShortCircuited ... invalid copy count [length(parameters('secretsObject').secrets)]`
    - ***Why***: `secretsObject` is marked `@secure()`. What‑If cannot evaluate the length of secure parameters before
      deployment.
    - ***Impact***: Not a deployment failure; the loop runs during deployment.

### Purge the Key Vaults

If, like me, you have been a bit too enthusiastic with your key vault experiments and now face conflicts, you can purge
them with the following commands.

```shell
az keyvault list-deleted

az keyvault purge --name <keyvault-name>
```
