# CloudFlare Tunnel

This cloudflared deployment exposes the Kubernetes cluster API to the internet
and creates a cluster admin token-based service account for accessing the cluster API from across the internet
without an mTLS proxy.

## Prerequisites

- A Kubernetes cluster. [How to set it up](../os/README.md#install-k3s).
- A free CloudFlare account.
- A domain name.
- [cloudflared](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/) command-line tool installed and configured to access your CloudFlare account.
- kubectl installed and configured to access the cluster.
- Helm installed.
- [yq](https://github.com/mikefarah/yq) installed.

## Setup

> [!NOTE]  
> The repo paths are relative to the repo root.

1. Run `cp ./cloudflared/values.yaml ./cloudflared/values.secrets.yaml` and populate the missing values in the new file.

2. Create a tunnel in CloudFlare:

    ```shell
    TUNNEL_NAME="$(yq -r '.tunnel.name' ./cloudflared/values.secrets.yaml)"
    DOMAIN_NAME="$(yq -r '.domainName' ./cloudflared/values.secrets.yaml)"
    cloudflared tunnel login
    cloudflared tunnel create $TUNNEL_NAME
    TUNNEL_ID="use note the tunnel ID from the command output above"
    cloudflared tunnel route dns $TUNNEL_NAME k8s.$DOMAIN_NAME
    ```

3. Create the tunnel secret:

    ```shell
    RELEASE_NAME="cloudflared-prod"
    kubectl get namespace $RELEASE_NAME || kubectl create namespace $RELEASE_NAME
    kubectl create secret generic tunnel-credentials --from-file=credentials.json=$HOME/.cloudflared/$TUNNEL_ID.json --namespace $RELEASE_NAME
    ```

4. Deploy cloudflared:

    ```shell
    helm install $RELEASE_NAME ./cloudflared \
      --namespace $RELEASE_NAME \
      --create-namespace \
      --values ./cloudflared/values.secrets.yaml
    ```

5. Get the created secret token value:

    ```shell
    SERVICE_ACCOUNT_NAME="$(yq -r '.k8s.serviceAccountName' ./cloudflared/values.secrets.yaml)"
    kubectl get secret $SERVICE_ACCOUNT_NAME-token --namespace $RELEASE_NAME --output jsonpath='{.data.token}' | base64 -d
    ```

6. Save the token value from the output of the last command. It can be used in kubeconfig on by an application to access the cluster API from the internet without an mTLS proxy.
