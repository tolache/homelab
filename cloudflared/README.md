# CloudFlare Tunnel

## Setup

> [!NOTE]  
> The repo paths are relative to the repo root.

1. Create the `.env` file:

    ```shell
    cp ./cloudflared/.env.example ./cloudflared/.env
    ```

1. Set values in the `.env` file.

1. Create a tunnel in CloudFlare:

    ```shell
    cloudflared tunnel login
    cloudflared tunnel create ${TUNNEL_NAME}
    # note the created tunnel ID and set the TUNNEL_ID variable
    cloudflared tunnel route dns ${TUNNEL_NAME} k8s.${DOMAIN_NAME}
    ```

1. Create the tunnel secret:

    ```shell
    kubectl create secret generic tunnel-credentials --from-file=credentials.json=${HOME}/.cloudflared/${TUNNEL_ID}.json
    ```

1. Deploy cloudflared ():

    ```shell
    bash -c 'export $(grep -v "^#" ./cloudflared/.env | xargs) && envsubst "\${TUNNEL_NAME} \${DOMAIN_NAME} \${K8S_API_SERVER_NAME}" < ./cloudflared/cloudflared.yaml | kubectl apply -f -'
    ```
