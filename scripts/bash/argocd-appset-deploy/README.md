# ArgoCD ApplicationSet – Example Deployment Script

This folder contains a Bash script and template for generating
and deploying an [ArgoCD ApplicationSet](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/)
using environment-specific configuration and HashiCorp Vault for secrets.

## What’s Included

- `argocd-appset-generate-and-deploy.sh`
  A Bash script that:
  - loads env-specific variables
  - fetches secrets from Vault
  - generates an ApplicationSet manifest using `envsubst`
  - deploys it via ArgoCD CLI

- `applicationsets/template.yaml`
  A templated `ApplicationSet` manifest using `${...}` placeholders.

- `example-env/shell.env`
  Example environment variables used by the script.

## Usage

### 1. Prepare your environment

Create a directory with your environment name under `environments/`, and copy the example `shell.env`:

Edit `environments/dev/shell.env` to match your setup.

Note: Do not commit real secrets or credentials. This is an example only.

### 2. Run the script

```bash
./argocd-appset-generate-and-deploy.sh <environment-name> [flags]
```

#### Example

```bash
./argocd-appset-generate-and-deploy.sh dev --upsert --verbose
```

#### Available flags

* `-d`, `--dry-run` – Generate and show manifest without applying changes
* `-u`, `--upsert` – Create or update resources in ArgoCD
* `-v`, `--verbose` – Print the generated YAML manifest to stdout

## Vault Configuration

The script expects a Git repo password/token to be stored in Vault at a path defined like this:

```bash
REPO_VAULT_PASSWORD_PATH="secret/example/<environment-name>/argo"
REPO_VAULT_PASSWORD_KEY="gitLabAccessToken"
```

Example:

```bash
REPO_VAULT_PASSWORD_PATH="secret/example/development/argo"
REPO_VAULT_PASSWORD_KEY="gitLabAccessToken"
```

It retrieves the secret using:

```bash
vault kv get --field="${REPO_VAULT_PASSWORD_KEY}" "${REPO_VAULT_PASSWORD_PATH}"
```

Make sure the Vault CLI is authenticated before running the script.

## Environment Variables

These must be defined in `environments/<env>/shell.env`:

| Variable           | Description                                |
| ------------------ | ------------------------------------------ |
| `APPSET_NAMESPACE` | Namespace for the generated ApplicationSet |
| `ARGOCD_DOMAIN`    | ArgoCD domain used for SSO login           |
| `ARGOCD_NAMESPACE` | Namespace where ArgoCD is deployed         |
| `CLUSTER_NAME`     | Logical name of the target K8s cluster     |
| `CLUSTER_URL`      | API server URL of the target K8s cluster   |
| `PROJECT_NAME`     | ArgoCD project name                        |
| `ENVIRONMENT`      | The environment name (same as folder)      |

## ApplicationSet Template

The file `applicationsets/template.yaml` contains a YAML template using
environment variables (in `${...}` syntax), rendered by `envsubst`.

Update fields like:

```yaml
repoURL: "https://github.com/your-org/your-repo.git"
targetRevision: "main"
```

These can be hardcoded in the template or passed dynamically via environment variables.

## Dependencies

Ensure the following tools are available in your system:

* `vault` (HashiCorp Vault CLI)
* `argocd` (ArgoCD CLI)
* `envsubst` (from GNU gettext)

