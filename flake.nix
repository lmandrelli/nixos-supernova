{
  description = "Configuration NixOS avec Home Manager et Flakes";

  inputs = {
    # Canal principal NixOS
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    # Canal stable pour packages spécifiques
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";
    
    # Canal fixe pour Android Studio (version actuelle)
    nixpkgs-android-studio.url = "github:NixOS/nixpkgs/5e2a59a5b1a82f89f2c7e598302a9cacebb72a67";
    
    # nixpkgs master pour OpenCode et derniers packages
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    
    # Specific nixpkgs commit for tamarin-prover
    nixpkgs-tamarin = {
      url = "github:NixOS/nixpkgs/a421ac6595024edcfbb1ef950a3712b89161c359";
    };
    
    # Home Manager pour la gestion des configurations utilisateur
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Support matériel spécialisé
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    
    # Hyprland - gestionnaire de fenêtres Wayland moderne
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
  };

  outputs = { self, nixpkgs, nixpkgs-stable, nixpkgs-android-studio, nixpkgs-master, nixpkgs-tamarin, home-manager, nixos-hardware, hyprland, ... }@inputs: {
    nixosConfigurations = {
      # Remplacez "nixos" par le nom de votre machine si différent
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          # Overlay pour rendre les packages stable disponibles
          ({ config, pkgs, ... }: {
            nixpkgs.overlays = [
              (final: prev: {
                stable = import nixpkgs-stable {
                  system = prev.system;
                  config.allowUnfree = true;
                };
                
                android-studio-channel = import nixpkgs-android-studio {
                  system = prev.system;
                  config.allowUnfree = true;
                  config.android_sdk.accept_license = true;
                };
                
                master = import nixpkgs-master {
                  system = prev.system;
                  config.allowUnfree = true;
                };
                
                tamarin = import nixpkgs-tamarin {
                  system = prev.system;
                  config.allowUnfree = true;
                };
              })
            ];
          })
          # Configuration matérielle générée automatiquement
          ./hardware-configuration.nix
          # Notre configuration principale
          ./configuration.nix
          
          # Intégration de Home Manager comme module NixOS
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.lmandrelli = import ./home.nix;

	    # CORRECTION: Activation du système de sauvegarde automatique
            # Ceci permet à Home Manager de sauvegarder les fichiers existants
            # avant de les remplacer par sa propre configuration
            home-manager.backupFileExtension = "hm-backup";
            
            # Allow unfree packages in home-manager
            nixpkgs.config.allowUnfree = true;
          }
        ];
      };
    };
  };
}
