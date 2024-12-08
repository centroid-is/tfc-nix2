{ config, lib, pkgs, modulesPath, tfc-packages, ... }:

{
  # Import the base configuration from parent directory
  imports = [ 
    ./base-configuration.nix 
  ];

  # Your customizations here
  networking.hostName = lib.mkForce "linescan";
  
#   # Override or add settings
#   users.users.tfc.password = "different-password";
  
  environment.systemPackages = lib.mkMerge [
    (with pkgs; [
        git
        htop
    ])
  ];
}
