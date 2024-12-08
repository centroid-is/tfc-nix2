{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

  inputs.disko.url = "github:nix-community/disko/master";
  inputs.disko.inputs.nixpkgs.follows = "nixpkgs";

  inputs.tfc-packages.url = "github:centroid-is/flakes?ref=v2024.12.2";

  outputs = inputs: let
    # Helper function to create a NixOS configuration and its test environment
    mkSystem = {name, configPath}: let
      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
      
      # Create the base system configuration
      baseSystem = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit (inputs) tfc-packages;
        };
        modules = [
          inputs.disko.nixosModules.disko
          configPath
        ];
      };

      # Create the ISO configuration
      isoSystem = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          targetSystem = baseSystem;
        };
        modules = [
          ./iso.nix
        ];
      };

      # Create the QEMU test script
      testScript = pkgs.writeShellApplication {
        name = "${name}-test";
        runtimeInputs = with pkgs; [
          qemu-utils
          qemu_kvm
        ];
        text = ''
          disk1=${name}-disk.qcow2
          if [ ! -f $disk1 ]; then
            qemu-img create -f qcow2 $disk1 32G
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
            -drive id=usbdisk,if=none,readonly=on,file="$(echo ${isoSystem.config.system.build.isoImage}/iso/*.iso)" \
            -netdev user,id=net0,hostfwd=tcp::2222-:22 \
            -device virtio-net-pci,netdev=net0 \
            -vnc :0
        '';
      };
    in {
      nixosConfiguration = baseSystem;
      nixosIsoConfiguration = isoSystem;
      package = testScript;
    };

  in {
    nixosConfigurations = {
      # Main TFC system
      tfc = mkSystem {
        name = "tfc";
        configPath = ./configuration.nix;
      }.nixosConfiguration;

      # Linescan system
      linescan = mkSystem {
        name = "linescan";
        configPath = ./linescan/configuration.nix;
      }.nixosConfiguration;

      # ISO configurations
      iso = mkSystem {
        name = "tfc";
        configPath = ./configuration.nix;
      }.nixosIsoConfiguration;

      linescan-iso = mkSystem {
        name = "linescan";
        configPath = ./linescan/configuration.nix;
      }.nixosIsoConfiguration;
    };

    # Test packages
    packages.x86_64-linux = {
      default = (mkSystem {
        name = "tfc";
        configPath = ./configuration.nix;
      }).package;

      linescan = (mkSystem {
        name = "linescan";
        configPath = ./linescan/configuration.nix;
      }).package;
    };
  };
}
