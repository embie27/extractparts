{
  description = "Command line tool to find parts in long music documents.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: {

    packages.x86_64-linux.extractparts = nixpkgs.legacyPackages.x86_64-linux.writeShellApplication {
      name = "extractparts";
      runtimeInputs = with nixpkgs.legacyPackages.x86_64-linux;
        [
          pdftk
          poppler_utils
          tesseract
          imagemagick
        ];
      text = builtins.readFile ./extractparts.sh;
    };

    packages.x86_64-linux.default = self.packages.x86_64-linux.extractparts;

  };
}
