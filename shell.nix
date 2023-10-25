{ pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
	nativeBuildInputs = with pkgs.buildPackages; [
		pkg-config
		nim
		imagemagick
		nimlsp
	];
}


