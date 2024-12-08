{ config, lib, pkgs, modulesPath, tfc-packages, ... }:

{
  # Import the base configuration from parent directory
  imports = [ 
    ../configuration.nix 
  ];

  # Your customizations here
  networking.hostName = "custom-tfc";
  
  # Override or add settings
  users.users.tfc.password = "different-password";
  
  environment.systemPackages = with pkgs; [
    git
    htop
  ];
}