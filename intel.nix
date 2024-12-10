{ config, lib, pkgs, ... }:

{
  hardware.graphics = {
    extraPackages = with pkgs; [
      intel-media-driver    # VAAPI
      vpl-gpu-rt           # Video Processing Library
      intel-ocl
    ];
  };

  hardware.cpu.intel.updateMicrocode = lib.mkDefault true;
}