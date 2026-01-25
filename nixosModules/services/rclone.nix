{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.noa.rclone;
in
{
  options.noa.rclone = {
    enable = lib.mkEnableOption "Rclone Mount Service";

    allowUsers = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Allow non-root users to access FUSE mounts.";
    };

    mountPoint = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/rclone";
      description = "Mount point directory.";
    };

    rcloneRemote = lib.mkOption {
      type = lib.types.str;
      default = "remote:";
      description = "Rclone remote to mount.";
    };

    rcloneConfigPath = lib.mkOption {
      type = lib.types.path;
      description = "Path to the Rclone configuration file.";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra arguments to pass to rclone mount.";
    };

    consistencyCheck = {
      enable = lib.mkEnableOption "Periodic consistency check for RAID/Union remotes";

      sourceRemote = lib.mkOption {
        type = lib.types.str;
        example = "gdrive:cloud";
        description = "The source remote (reference) for the check.";
      };

      targetRemote = lib.mkOption {
        type = lib.types.str;
        example = "onedrive:cloud";
        description = "The target remote to compare against.";
      };

      schedule = lib.mkOption {
        type = lib.types.str;
        default = "weekly";
        description = "Systemd OnCalendar format for the check schedule.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.rclone ];
    programs.fuse.userAllowOther = cfg.allowUsers;

    fileSystems.${cfg.mountPoint} = {
      device = cfg.rcloneRemote;
      fsType = "rclone";
      options = [
        "nodev"
        "nofail"
        "rw"
        "args2env"
        "config=${cfg.rcloneConfigPath}"
        "cache_dir=/var/cache/rclone"
        "vfs_cache_mode=full"
        "vfs_cache_max_size=20G"
        "vfs_cache_max_age=168h"
        "log_level=INFO"
        "syslog"
      ]
      ++ lib.optionals cfg.allowUsers [ "allow_other" ]
      ++ cfg.extraArgs;
    };

    systemd.services."rclone-consistency-check" = lib.mkIf cfg.consistencyCheck.enable {
      description = "Rclone Consistency Check between ${cfg.consistencyCheck.sourceRemote} and ${cfg.consistencyCheck.targetRemote}";

      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        Type = "oneshot";
        User = "root";
        CPUSchedulingPolicy = "idle";
        IOSchedulingClass = "idle";
      };

      script = ''
        echo "Starting Rclone consistency check..."
        ${pkgs.rclone}/bin/rclone check \
          "${cfg.consistencyCheck.sourceRemote}" \
          "${cfg.consistencyCheck.targetRemote}" \
          --config "${cfg.rcloneConfigPath}" \
          --one-way \
          --log-level INFO \
          --syslog

        if [ $? -eq 0 ]; then
          echo "✅ Consistency check passed: Remotes are in sync."
        else
          echo "❌ Consistency check FAILED: Differences found!"
          exit 1
        fi
      '';
    };

    systemd.timers."rclone-consistency-check" = lib.mkIf cfg.consistencyCheck.enable {
      description = "Timer for Rclone consistency check";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.consistencyCheck.schedule;
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    };
  };
}
