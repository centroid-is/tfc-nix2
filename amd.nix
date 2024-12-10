{ config, lib, pkgs, ... }:

{
  hardware.graphics = {
    extraPackages = with pkgs; [
      mesa.opencl
      amdvlk
    ];
  };

  hardware.cpu.amd.updateMicrocode = lib.mkDefault true;
}
