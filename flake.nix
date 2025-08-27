{
  description = "A project to learn zig";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-zig-15.url = "github:nixos/nixpkgs/pull/435835/head";
    tree-sitter-zig = {
      url = "github:tree-sitter-grammars/tree-sitter-zig";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-zig-15,
    tree-sitter-zig,
  }: let
    pkgs = nixpkgs.legacyPackages."x86_64-linux";
    tree-sitter-zig-grammar = pkgs.tree-sitter.buildGrammar {
      language = "zig";
      version = "0.0.1";
      src = tree-sitter-zig;
    };
  in {
    devShells."x86_64-linux".default = pkgs.mkShell {
      packages = with pkgs; [
        nixpkgs-zig-15.legacyPackages."x86_64-linux".zig
        zls
        lldb
        tree-sitter-zig-grammar
        vscode-extensions.vadimcn.vscode-lldb
        vscode-extensions.vadimcn.vscode-lldb.adapter

        nixd
        alejandra
        tree-sitter-grammars.tree-sitter-nix
      ];
    };
    shellHook = ''
      export ZIG_GLOBAL_CACHE_DIR="$HOME/.cache/zig"
      export ZIG_LOCAL_CACHE_DIR="$PWD/.zig-cache"

      # Verify Zig installation
      echo "Zig version: $(zig version)"
      echo "ZLS version: $(zls --version)"
      echo "Zig environment:"
      zig env
    '';
  };
}
