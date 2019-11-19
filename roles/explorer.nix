{ config, ... }:

let
  sources = import ../nix/sources.nix;
  iohkLib = import ../lib.nix { };
  cluster = "mainnet";
  targetEnv = iohkLib.cardanoLib.environments.${cluster};
  host = "explorer.example.org";
in {
  imports = [
    (sources.cardano-node + "/nix/nixos")
    (sources.cardano-explorer + "/nix/nixos")
  ];
  services.graphql-engine.enable = true;
  services.cardano-graphql.enable = true;
  services.cardano-node = {
    environment = cluster;
    topology = iohkLib.cardanoLib.mkEdgeTopology { edgeNodes = iohkLib.cardanoLib.environments.${cluster}.edgeNodes; edgePort = 7777; };
    enable = true;
  };
  services.cardano-exporter = {
    enable = true;
    inherit (targetEnv) genesisFile genesisHash;
    inherit cluster;
    socketPath = "/run/cardano-node/node-core-0.socket";
  };
  services.cardano-explorer-api.enable = true;
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  services.nginx = {
    enable = true;                                          # Enable Nginx
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    virtualHosts."${host}" = {                              # Explorer hostname
      enableACME = true;                                    # Use ACME certs
      forceSSL = true;                                      # Force SSL
      locations."/".proxyPass = "http://localhost:3100/";   # Proxy Explorer
    };
  };

  security.acme.certs = {
    "${host}" = {
      email = "acme@example.org";
    };
  };

}
