## Build the ISO image

```bash
nix build -L .#nixosConfigurations.iso.config.system.build.isoImage
ls -l ./result/iso
````

## Run QEMU with the ISO image

```bash
nix run -L .
````


### SSH into the VM

```bash
ssh -p 2222 tfc@localhost
```

### Rebuild the VM

```bash
rm disk1.qcow2
nix run -L .
```

# Building various images

## Run in qemu
```bash
nix run -L .#default # or nix run -L .
```
For linescan example:
```bash
GITHUB_TOKEN=<your token> nix run -L .#linescan --impure
```
