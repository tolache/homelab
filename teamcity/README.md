# TeamCity

This Helm chart installs a TeamCity server with a PostgreSQL database and exposes it via a service.

## Prerequisites

- A Kubernetes cluster. [How to set it up](../os/README.md#install-k3s).
- kubectl installed and configured to access the cluster.
- Helm installed.
- [yq](https://github.com/mikefarah/yq) installed.

## Setup

1. Run `cp values.yaml values.secrets.yaml` and populate the missing values in the new file.

2. Set shell variables:

    ```shell
    NAMESPACE='teamcity-prod'
    RELEASE_NAME='teamcity-prod'
    ```

3. Creates the namespace:
    
    ```shell
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    ```

4. Create a secret with Postgres credentials if it doesn't exist:

    ```shell
    kubectl --namespace $NAMESPACE create secret generic "$(yq -r '.postgres.secretName' values.secrets.yaml)" \
      --from-literal=POSTGRES_USER='teamcity' \
      --from-literal=POSTGRES_PASSWORD="$(head -c12 /dev/urandom | base64)"
    ```    
    
    Note: you can replace the password with any other string if you don't want a random base64-encoded string.

5. Install the chart:

    ```shell
    helm install $RELEASE_NAME . --namespace $NAMESPACE --create-namespace --values values.secrets.yaml
    ```
