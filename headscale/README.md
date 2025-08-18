# Headscale

This deployment provides a Headscale server

## Prerequisites

- [Kubernetes cluster](../os/README.md#install-k3s).
- [CloudFlare Tunnel](../cloudflared/README.md) for remote access.
- kubectl installed and configured to access the cluster.
- Helm installed.

## Deployment

> [!NOTE]  
> The repo paths are relative to the repo root.

1. Run `cp ./headscale/values.yaml ./headscale/values.secrets.yaml` and populate the missing values.

    Note: Alternatively, you can modify the `./headscale/values.yaml` file in place. In this case, you will need to skip the `--values ./headscale/values.secrets.yaml` argument in the next step's `helm install`.

2. Deploy resources:

    ```shell
    RELEASE_NAME="headscale-prod"
    helm install $RELEASE_NAME ./headscale \
      --namespace $RELEASE_NAME \
      --create-namespace \
      --values ./headscale/values.secrets.yaml
    ```

3. Verify headscale is running:

    ```shell
    kubectl --namespace $RELEASE_NAME exec -it deployments/headscale -- headscale configtest
    ```

    Expected output example:

    ```log
    2025-06-15T08:41:51Z INF Opening database database=sqlite3 path=/var/lib/headscale/db.sqlite
    2025-06-15T08:41:51Z INF Using policy manager version: 2
    ```

4. Download the Headscale CLI release for your platform:

    ```shell
    PLATFORM="darwin" # darwin/linux
    ARCHITECTURE="arm64" # arm64/amd64
    HEADSCALE_CLI_RELEASE_NAME=$(gh --repo juanfont/headscale release list --json name,isLatest --jq '.[] | select(.isLatest).name') # e.g., v0.26.1
    HEADSCALE_CLI_VERSION=${HEADSCALE_CLI_RELEASE_NAME#v} # e.g., 0.26.1
    HEADSCALE_CLI_ASSET_NAME="headscale_${HEADSCALE_CLI_VERSION}_${PLATFORM}_${ARCHITECTURE}"
    curl -LO https://github.com/juanfont/headscale/releases/download/$HEADSCALE_CLI_RELEASE_NAME/$HEADSCALE_CLI_ASSET_NAME
    ```

    Or go to the [Headscale releases page](https://github.com/juanfont/headscale/releases) on GitHub and download the latest release for your platform) and download the appropriate asset manually.

5. Move the Headscale CLI to a directory in your PATH:

    ```shell
    sudo mv $HEADSCALE_CLI_ASSET_NAME /usr/local/bin/headscale
    chmod +x /usr/local/bin/headscale
    ```

6. Create a Headscale API key:

    ```shell
    HEADSCALE_API_KEY=$(kubectl --namespace headscale exec -it deployments/headscale-prod -- headscale apikeys create --expiration 90d)
    ```

7. Create Headscale configuration file:

    ```shell
    cat >> /etc/headscale/config.yaml<< EOF
    cli:
      address: $K8S_API_SERVER_NAME:30180
      api_key: $HEADSCALE_API_KEY
    EOF
    ```

8. Verify Headscale server is responding:

    ```shell
     headscale nodes list
    ```

## Cleanup

To remove Headscale, run:

```shell
RELEASE_NAME="headscale-prod"
helm uninstall $RELEASE_NAME --namespace $RELEASE_NAME
```
