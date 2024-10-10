{
  description = "sf cert training dev environment";
  inputs = {
      nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
      devenv.url = "github:cachix/devenv";
      phps.url = "github:loophp/nix-shell";
      systems.url = "github:nix-systems/default";
  };

  outputs = inputs @ {
    flake-parts,
    systems,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [inputs.devenv.flakeModule];
      systems = import systems;

      perSystem = { system, ... }: let
        pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [inputs.phps.overlays.default];
        };

        php = pkgs.api.buildPhpFromComposer {
          php = pkgs.php81;
          src = inputs.self;
          withExtensions = ["xdebug"];
          extraConfig = ''
            memory_limit=-1
            xdebug.file_link_format="phpstorm://open?file=%f&line=%l"
            xdebug.mode=debug
          '';
        };
        packages = [
          php
          php.packages.composer
        ];
      in {
        formatter = pkgs.alejandra;
        devenv.shells = {
          default = {
            inherit packages;
            dotenv.disableHint = true;
          };
       };
      };
    };
}
