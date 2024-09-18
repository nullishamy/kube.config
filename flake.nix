{
  description = "A devShell example";

  inputs = {
    nixpkgs.url      = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url  = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
      in
      {
        devShell = pkgs.mkShell {
          buildInputs =
          let
          custom-kubernetes-helm = with pkgs; wrapHelm kubernetes-helm {
            plugins = with pkgs.kubernetes-helmPlugins; [
              helm-secrets
              helm-diff
              helm-s3
              helm-git
            ];
          };
          custom-helmfile = pkgs.helmfile-wrapped.override {
            inherit (custom-kubernetes-helm) pluginsDir;
          }; 
          in with pkgs; [
            kubectl
            kluctl
            custom-helmfile
            sops
            custom-kubernetes-helm
          ];
          env = {
            KUBECONFIG = "/home/amy/code/kube.config/kubeconfig";
          };
        };
      }
    );
}
