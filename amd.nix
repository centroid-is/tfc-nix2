{ config, lib, pkgs, ... }:

{
  hardware.opengl = {
    extraPackages = with pkgs; [
      rocm-opencl-icd
      amdvlk
    ];
  };

  hardware.cpu.amd.updateMicrocode = lib.mkDefault true;
}
