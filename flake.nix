{
  description = "Owncast Admin";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "aarch64-linux" "i686-linux" "x86_64-linux" ];

      forAllSystems = f:
        nixpkgs.lib.genAttrs supportedSystems (system: f system);

      nixpkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlay ];
        });
    in
    {
      overlay = final: prev: with prev; {
        owncast-admin =
          mkYarnPackage {
            pname = "owncast-admin";
            version = "unstable-2021-09-07";

            src = ./.;
            packageJSON = ./package.json;
            yarnLock = ./yarn.lock;

            buildInputs = [ nodejs ];

            buildPhase = ''
              export HOME=$PWD/yarn_home
              yarn --offline build
            '';

            installPhase = ''
              mkdir -p $out/admin
              cp -r out/* $out/admin
            '';

            meta = {
              homepage = "https://owncast.online";
              description = "Owncast admin interface";
              license = lib.licenses.mit;
            };
          };
      };

      packages = forAllSystems (system: {
        inherit (nixpkgsFor.${system}) owncast-admin;
      });

      defaultPackage = forAllSystems (system:
        self.packages.${system}.owncast-admin);

      devShell = self.defaultPackage;
    };
}
