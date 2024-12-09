{ config, lib, pkgs, ... }:

{
  hardware.opengl = {
    extraPackages = with pkgs; [
      intel-media-driver    # VAAPI
      vpl-gpu-rt           # Video Processing Library
    ];
  };

  hardware.cpu.intel.updateMicrocode = lib.mkDefault true;
}