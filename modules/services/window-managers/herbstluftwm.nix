{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.xsession.windowManager.herbstluftwm;

in {
  meta.maintainers = [ maintainers.thibautmarty ];

  options = {
    xsession.windowManager.herbstluftwm = {
      enable = mkEnableOption "herbstluftwm window manager";

      package = mkOption {
        type = types.package;
        default = pkgs.herbstluftwm;
        defaultText = literalExample "pkgs.herbstluftwm";
        description = "Package to use for running herbstluftwm.";
      };

      autostart = mkOption {
        description = "Autostart file.";
        default = null;
        type = types.submodule {
          options = {
            text = mkOption {
              default = null;
              type = types.nullOr types.lines;
              description = ''
                Text of the file. If this option is null then
                <link linkend="opt-xsession.windowManager.herbstluftwm.autostart.source">xsession.windowManager.herbstluftwm.autostart.source</link>
                must be set.
              '';
            };

            source = mkOption {
              type = types.path;
              description = ''
                Path of the source file or directory. If
                <link linkend="opt-xsession.windowManager.herbstluftwm.autostart.text">xsession.windowManager.herbstluftwm.autostart.text</link>
                is non-null then this option will automatically point to a file
                containing that text.
              '';
            };
          };
        };
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = [ cfg.package ];
      xsession.windowManager.command = "${cfg.package}/bin/herbstluftwm";
    }

    (mkIf (cfg.autostart != null) {
      xdg.configFile."herbstluftwm/autostart" = {
        source = cfg.autostart.source;
        text = cfg.autostart.text;
        executable = true;
        onChange = ''
          if ${cfg.package}/bin/herbstclient silent version 2> /dev/null ; then
            $DRY_RUN_CMD ${cfg.package}/bin/herbstclient -q reload
          fi
        '';
      };

      # Spawn the wmexec command if the package changed to load the current executable
      # This is possible only if herbstluftwm is currently running
      home.activation.ExecHerbstluftwm = ''
        if ${cfg.package}/bin/herbstclient silent version 2> /dev/null && \
          [[ "$(realpath $(command -v herbstluftwm || echo notfound))" != "${cfg.package}/bin/herbstluftwm" ]] ; then
          $DRY_RUN_CMD ${cfg.package}/bin/herbstclient -q wmexec ${cfg.package}/bin/herbstluftwm
        fi
      '';
    })
  ]);
}
