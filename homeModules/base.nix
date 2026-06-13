{
  lib,
  username,
  osConfig,
  system,
  pkgs,
  ...
}:
let
  homeDirectory = if system == "aarch64-darwin" then "/Users/${username}" else "/home/${username}";
in
{
  imports = osConfig.noa.homeManager.modules;

  config = {
    programs.home-manager.enable = true;

    home = {
      inherit username homeDirectory;
      sessionVariables = {
        LANG = "en_US.UTF-8";
        LANGUAGE = "en_US";
        # Do not track
        ALGOLIA_CLI_TELEMETRY = 0; # Algolia
        AMPLIFY_DISABLE_TELEMETRY = 1; # AWS Amplify
        APOLLO_TELEMETRY_DISABLED = 1; # Apollo Router/Rover
        ARDUINO_METRICS_ENABLED = "false"; # Arduino
        ASTRO_TELEMETRY_DISABLED = 1; # Astro
        AZURE_CORE_COLLECT_TELEMETRY = 0; # Azure
        CALCOM_TELEMTRY_DISABLED = 1; # Cal.com
        CHECKPOINT_DISABLE = 1; # Prisma, Terraform
        CLOUDSDK_CORE_DISABLE_USAGE_REPORTING = "true"; # Google Cloud SDK
        DA_TEST_DISABLE_TELEMETRY = 1; # JavaScript Debugger (VSCode)
        DATAHUB_TELEMETRY_ENABLED = "false"; # DataHub
        DDB_LOCAL_TELEMETRY = 0; # DynamoDB
        DISABLE_ZAPIER_ANALYTICS = 1; # Zapier
        DO_NOT_TRACK = 1; # https://consoledonottrack.com
        DOTNET_CLI_TELEMETRY_OPTOUT = 1; # .NET
        DOTNET_INTERACTIVE_CLI_TELEMETRY_OPTOUT = 1; # .NET Interactive
        EXPO_NO_TELEMETRY = 1; # Expo
        GATSBY_TELEMETRY_DISABLED = 1; # Gatsby
        GH_TELEMETRY = "false"; # GitHub CLI
        GOTELEMETRY = "false"; # Go
        HASURA_GRAPHQL_ENABLE_TELEMETRY = "false"; # Hasura
        HOMEBREW_NO_ANALYTICS = 1;
        MSSQL_TELEMETRY_ENABLED = "false"; # Azure SQL Edge
        NEXT_TELEMETRY_DISABLED = 1; # Next.js
        NG_CLI_ANALYTICS = "false"; # Angular CLI
        NUXT_TELEMETRY_DISABLED = 1; # Nuxt.js
        OMO_SEND_ANONYMOUS_TELEMETRY = 0; # oh-my-openagent
        SAM_CLI_TELEMETRY = 0; # AWS SAM
        SFDX_DISABLE_TELEMETRY = "true"; # Salesforce CLI
        SLS_TELEMETRY_DISABLED = 1; # Serverless Framework
        SST_TELEMETRY_DISABLED = 1; # SST
        STORYBOOK_DISABLE_TELEMETRY = 1; # Storybook
        STRAPI_TELEMETRY_DISABLED = "true";
        STRIPE_CLI_TELEMETRY_OPTOUT = 1; # Stripe
        TELEMETRY_DISABLED = 1;
        YARN_ENABLE_TELEMETRY = 0; # Yarn
      };
      stateVersion = "26.05";
    };

    sops = {
      age.keyFile = "${homeDirectory}/.config/sops/age/keys.txt";
      # defaultSopsFile = "${secretsPath}/home.yaml";
    };

    # Disable GPG for sops-nix systemd user service
    # Workaround for https://github.com/Mic92/sops-nix/issues/356
    systemd.user.services.sops-nix.Service.Environment = lib.mkForce [
      "SOPS_GPG_EXEC=${pkgs.coreutils}/bin/false"
    ];

    xdg.userDirs = lib.mkIf (system != "aarch64-darwin") {
      enable = true;
      createDirectories = true;
    };
  };

  options = {
    noa.nixpkgs.allowedUnfreePackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of unfree packages allowed to be installed.";
    };
  };
}
