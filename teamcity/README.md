# TeamCity

This Helm chart installs a TeamCity server with a PostgreSQL database and exposes it via a service.
It also creates a service account with a token that can TeamCity can use to access the cluster API and run builds.

## Prerequisites

- A Kubernetes cluster. [How to set it up](../os/README.md#install-k3s).
- kubectl installed and configured to access the cluster.
- Helm installed.
- cert-manager installed (`kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.3/cert-manager.yaml`).
- [nginx ingress controller](https://docs.nginx.com/nginx-ingress-controller/install/helm/open-source/) installed in the cluster. Check with `k get ingressclasses`.

## Setup

1. Install TeamCity operator via Helm:

    ```shell
    helm upgrade --install teamcity-operator \
    -n teamcity-operator --create-namespace \
    https://github.com/JetBrains/teamcity-operator/releases/download/0.0.20/teamcity-operator-0.0.20.tgz
    ```

2. Run `cp values.yaml values.secrets.yaml` and populate the missing values in the new file.

3. Set shell variables:

    ```shell
    NAMESPACE='teamcity-prod'
    RELEASE_NAME='teamcity-prod'
    ```

4. Creates the namespace:

    ```shell
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    ```

5. Create a secret with Postgres credentials if it doesn't exist:

    ```shell
    kubectl --namespace $NAMESPACE create secret generic "$(yq -r '.postgres.secretName' values.secrets.yaml)" \
      --from-literal=POSTGRES_USER='teamcity' \
      --from-literal=POSTGRES_PASSWORD="$(head -c12 /dev/urandom | base64)"
    ```    

   Note: you can replace the password with any other string if you don't want a random base64-encoded string.

6. Install the chart:

    ```shell
    helm install $RELEASE_NAME . --namespace $NAMESPACE --create-namespace --values values.secrets.yaml
    ```
   
    Note: the main node stateful set will not be ready untill the license agreement is accepted. 
   
7. Get the superuser token from the log and accept the license agreement:

    ```shell
    kubectl --namespace $NAMESPACE logs statefulsets/main-node | grep Super
    ```
   
    Note: It may take a minute for the application to start and log the superuser token.

8. Go to the TeamCity web UI and use the superuser token to accept the license agreement. The main node stateful set should now be ready.

9. Get the created secret token value:

    ```shell
   kubectl get secret teamcity --namespace $NAMESPACE --output jsonpath='{.data.token}' | base64 -d
    ```

10. Save the token value from the output of the last command. It can be used in kubeconfig on by an application to access the cluster API from the internet without an mTLS proxy.

## TODO

1. Check if `app.kubernetes.io/name: teamcity`, `app.kubernetes.io/part-of: teamcity`, or `ingressList: -name: teamcity` need to use `{{ .Release.Name }}`.
