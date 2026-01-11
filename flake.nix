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
          diff.algorithm = "histogram";
          rerere.enabled = true;
          color.ui = "auto";
          branch.sort = "-committerdate";
        };
        
        aliases = {
          st = "status";
          s = "status -s";
          ci = "commit";
          cm = "commit -m";
          ca = "commit --amend";
          cam = "commit --amend -m";
          a = "add";
          aa = "add -A";
          ap = "add -p";
          co = "checkout";
          cob = "checkout -b";
          br = "branch";
          brd = "branch -d";
          brD = "branch -D";
          l = "log --oneline --graph --decorate";
          lg = "log --oneline --graph --decorate --all";
          ll = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
          d = "diff";
          ds = "diff --staged";
          dc = "diff --cached";
          stash-all = "stash save --include-untracked";
          pf = "push --force-with-lease";
          pl = "pull";
          plo = "pull origin";
          psh = "push";
          psho = "push origin";
          rb = "rebase";
          rbi = "rebase -i";
          rbc = "rebase --continue";
          rba = "rebase --abort";
          unstage = "restore --staged";
          uncommit = "reset --soft HEAD~1";
        };
        
        ignores = [
          ".DS_Store"
          "Thumbs.db"
          "*~"
          "*.swp"
          "*.swo"
          ".vscode/"
          ".idea/"
          "result"
          "result-*"
          ".direnv/"
          "node_modules/"
          "__pycache__/"
          "*.pyc"
          ".pytest_cache/"
          "target/"
          "*.class"
        ];
      };
        
    in
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        config = mkGitConfig pkgs;
        
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
        
        gitignore = pkgs.writeText "gitignore" 
          (pkgs.lib.concatStringsSep "\n" config.ignores);

        gitWrapper = pkgs.stdenv.mkDerivation {
          name = "git-with-config";
          nativeBuildInputs = [ pkgs.makeWrapper ];
          dontUnpack = true;
          dontBuild = true;
          installPhase = ''
            mkdir -p $out/bin
            makeWrapper ${pkgs.git}/bin/git $out/bin/git \
              --set GIT_CONFIG_GLOBAL ${gitconfig} \
              --set GIT_CONFIG_SYSTEM /dev/null
          '';
        };
        
      in
      {
        packages = {
          default = gitWrapper;
          git = gitWrapper;
        };
        
        apps.default = {
          type = "app";
          program = "${gitWrapper}/bin/git";
        };

        devShells.default = pkgs.mkShell {
          packages = [ gitWrapper ];
          shellHook = ''
            echo "Git with custom configuration"
            echo "Run 'git config --list' to see your config"
          '';
        };
        
        lib.gitConfig = config;
      }
    ) // {
      lib.mkGitConfig = mkGitConfig;
    };
}