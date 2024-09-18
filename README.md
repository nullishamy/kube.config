# kube.config

This is my personal Kubernetes (through k3s) config, feel free to ~~steal~~ borrow it, but I won't be providing support
and make no assurances that these deployments are quality or robust..

## secrets

You will need to supply some secrets for the cluster to operate, pop them in `deployments/secrets.yaml` and then encrypt it with `sops`:
```yaml
secrets:
    dyndns:
        apiKey: <cf api key>
    smtp:
        password: <smtp password>
    gitlab:
        runnerToken: <runner token>
certs:
    cf:
        crt: <certificate>
        key: <private key>
age:
    key: <age key>
```

## bootstrap

Use `kluctl deploy -t katto` from within `deployments/`, this presumes your `kubeconfig` is properly configured.