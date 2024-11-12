{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  inputs.disko.url = "github:nix-community/disko/master";
  inputs.disko.inputs.nixpkgs.follows = "nixpkgs";

  outputs = inputs: {
    nixosConfigurations = {
      nixos = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit (inputs.self.packages.x86_64-linux) tfc-hmi;
        };
        modules = [
          inputs.disko.nixosModules.disko
          ./configuration.nix
        ];
      };
      iso = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          targetSystem = inputs.self.nixosConfigurations.nixos;
        };
        modules = [
          ./iso.nix
        ];
      };
    };
    packages.x86_64-linux.default = let
      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    in pkgs.writeShellApplication {
      name = "iso-test";
      runtimeInputs = with pkgs; [
        qemu-utils
        qemu_kvm
      ];
      text = ''
        disk1=disk1.qcow2
        if [ ! -f $disk1 ]; then
          qemu-img create -f qcow2 $disk1 16G
        fi
        exec qemu-kvm \
          -boot c \
          -cpu host \
          -smp cores=2 \
          -M pc \
          -m 2G \
          -device virtio-balloon \
          -device virtio-rng-pci \
          -device nvme,serial=deadbeef,drive=nvm \
          -device usb-ehci \
          -device usb-storage,drive=usbdisk \
          -drive file=$disk1,format=qcow2,if=none,id=nvm,cache=unsafe,werror=report \
          -drive if=pflash,format=raw,unit=0,readonly=on,file=${pkgs.OVMF.firmware} \
          -drive id=usbdisk,if=none,readonly=on,file="$(echo ${inputs.self.nixosConfigurations.iso.config.system.build.isoImage}/iso/*.iso)" \
          -netdev user,id=net0,hostfwd=tcp::2222-:22 \
          -device virtio-net-pci,netdev=net0 # \
          # -vnc :0
      '';
    };
    packages.x86_64-linux.tfc-hmi = let
      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
      version = "2024.11.0";
    in pkgs.stdenv.mkDerivation {
        pname = "tfc-hmi";
        version = version;
        src = pkgs.fetchurl {
          url = "https://github.com/centroid-is/tfc-hmi/releases/download/v${version}/example-elinux.tar.gz";
          sha256 = "9ac27f7fa092db0de2b8a85aa88afd44a247130f808b1207269f3c05a6d0fbfa";
        };
        sourceRoot = ".";
        installPhase = ''
          echo "Source root: $sourceRoot"
          echo "Installing to $out"
          mkdir -p $out
          cp -r * $out/
          export out=$out

          echo "{ pkgs ? import <nixpkgs> {} }:


          (pkgs.buildFHSEnv {
            name = \"flutter-env\";
            targetPkgs = pkgs: (with pkgs; [
              wayland
              libxkbcommon
              fontconfig
              libGL
            ]);
            multiPkgs = pkgs: (with pkgs; []);
            runScript = \"$out/example --bundle=$out\";
          }).env
        " > $out/shell.nix
      '';
    };
  };
}
