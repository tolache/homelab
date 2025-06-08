# CloudFlare Tunnel

## Prerequisites

Requires a Kubernetes cluster. [Documentation](../os/README.md#install-k3s).

## Setup

> [!NOTE]  
> The repo paths are relative to the repo root.

1. Create the `.env` file:

    ```shell
    cp ./cloudflared/.env.example ./cloudflared/.env
    ```

1. Set values in the `.env` file.

1. Load the values into the shell. Further steps will use substitution on the shell level.

    ```shell
    source ./cloudflared/.env
    ```

1. Create a tunnel in CloudFlare:

    ```shell
    cloudflared tunnel login
    cloudflared tunnel create $TUNNEL_NAME
    # note the created tunnel ID and set the TUNNEL_ID variable
    cloudflared tunnel route dns $TUNNEL_NAME k8s.$DOMAIN_NAME
    ```

1. Create the tunnel secret:

    ```shell
    kubectl create secret generic tunnel-credentials --from-file=credentials.json=$HOME/.cloudflared/$TUNNEL_ID.json
    ```

1. Deploy cloudflared:

    ```shell
    bash -c 'export $(grep -v "^#" ./cloudflared/.env | xargs) && envsubst "\${TUNNEL_NAME} \${DOMAIN_NAME} \${K8S_API_SERVER_NAME}" < ./cloudflared/cloudflared.yaml | kubectl apply -f -'
    ```

1. Create service account credentials for accessing the cluster API through the internet without an mTLS proxy.

    ```shell
    kubectl create serviceaccount $SERVICE_ACCOUNT_NAME
    bash -c 'export $(grep -v "^#" ./cloudflared/.env | xargs) && envsubst "\${SERVICE_ACCOUNT_NAME}" < ./cloudflared/service-account-secret.yaml | kubectl apply -f -'
    bash -c 'export $(grep -v "^#" ./cloudflared/.env | xargs) && envsubst "\${SERVICE_ACCOUNT_NAME}" < ./cloudflared/service-account-role-binding.yaml | kubectl apply -f -'
    kubectl get secret $SERVICE_ACCOUNT_NAME-token -o jsonpath='{.data.token}' | base64 -d
    ```

1. Save the token value from the output of the last command. It can be used in kubeconfig on by an application.
