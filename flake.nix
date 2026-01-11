{
  description = "Gregory's Git configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      mkGitConfig = pkgs: {
        userName = "Gregory Foster";
        userEmail = "brona90@gmail.com";
        
        extraConfig = {
          init.defaultBranch = "main";
          core.editor = "emacs -nw";
          pull.rebase = false;
          push.autoSetupRemote = true;
          
          # Better diffs
          diff.algorithm = "histogram";
          
          # Reuse recorded resolutions
          rerere.enabled = true;
          
          # Color output
          color.ui = "auto";
          
          # Show branches sorted by most recent commit
          branch.sort = "-committerdate";
        };
        
        aliases = {
          # Status and info
          st = "status";
          s = "status -s";
          
          # Committing
          ci = "commit";
          cm = "commit -m";
          ca = "commit --amend";
          cam = "commit --amend -m";
          
          # Staging
          a = "add";
          aa = "add -A";
          ap = "add -p";
          
          # Branching
          co = "checkout";
          cob = "checkout -b";
          br = "branch";
          brd = "branch -d";
          brD = "branch -D";
          
          # Logging
          l = "log --oneline --graph --decorate";
          lg = "log --oneline --graph --decorate --all";
          ll = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
          
          # Diffing
          d = "diff";
          ds = "diff --staged";
          dc = "diff --cached";
          
          # Stashing
          stash-all = "stash save --include-untracked";
          
          # Pushing/Pulling
          pf = "push --force-with-lease";
          pl = "pull";
          plo = "pull origin";
          psh = "push";
          psho = "push origin";
          
          # Rebasing
          rb = "rebase";
          rbi = "rebase -i";
          rbc = "rebase --continue";
          rba = "rebase --abort";
          
          # Undoing
          unstage = "restore --staged";
          uncommit = "reset --soft HEAD~1";
          
          # Cleanup
          cleanup = "!git branch --merged | grep -v '\\*\\|main\\|master' | xargs -n 1 git branch -d";
        };
        
        ignores = [
          # OS files
          ".DS_Store"
          "Thumbs.db"
          
          # Editor files
          "*~"
          "*.swp"
          "*.swo"
          ".vscode/"
          ".idea/"
          
          # Nix
          "result"
          "result-*"
          ".direnv/"
          
          # Language specific
          "node_modules/"
          "__pycache__/"
          "*.pyc"
          ".pytest_cache/"
          "target/"
          "*.class"
        ];
      };
      
      mkGitignore = ignores: pkgs.writeText "gitignore" 
        (pkgs.lib.concatStringsSep "\n" ignores);
        
    in
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        config = mkGitConfig pkgs;
        
        # Create gitconfig file
        gitconfig = pkgs.writeText "gitconfig" ''
          [user]
            name = ${config.userName}
            email = ${config.userEmail}
          
          [init]
            defaultBranch = ${config.extraConfig.init.defaultBranch}
          
          [core]
            editor = ${config.extraConfig.core.editor}
          
          [pull]
            rebase = ${if config.extraConfig.pull.rebase then "true" else "false"}
          
          [push]
            autoSetupRemote = ${if config.extraConfig.push.autoSetupRemote then "true" else "false"}
          
          [diff]
            algorithm = ${config.extraConfig.diff.algorithm}
          
          [rerere]
            enabled = ${if config.extraConfig.rerere.enabled then "true" else "false"}
          
          [color]
            ui = ${config.extraConfig.color.ui}
          
          [branch]
            sort = ${config.extraConfig.branch.sort}
          
          [alias]
          ${pkgs.lib.concatStringsSep "\n" 
            (pkgs.lib.mapAttrsToList (name: value: "  ${name} = ${value}") config.aliases)}
        '';
        
        gitignore = mkGitignore config.ignores;
        
        # Setup script
        setupGit = pkgs.writeShellScriptBin "setup-git-config" ''
          echo "Setting up Git configuration..."
          
          mkdir -p ~/.config/git
          
          ln -sf ${gitconfig} ~/.config/git/config
          ln -sf ${gitignore} ~/.config/git/ignore
          
          echo "✓ Git config linked to ~/.config/git/config"
          echo "✓ Global gitignore linked to ~/.config/git/ignore"
        '';
        
      in
      {
        packages = {
          default = setupGit;
          setup = setupGit;
        };
        
        apps.default = {
          type = "app";
          program = "${setupGit}/bin/setup-git-config";
        };
        
        # Export config for home-manager
        lib.gitConfig = config;
      }
    ) // {
      lib.mkGitConfig = mkGitConfig;
    };
}
