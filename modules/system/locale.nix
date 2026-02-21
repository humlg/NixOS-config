{ config, lib, pkgs, ... }:

{

  # Set your time zone.
  time.timeZone = "Europe/Prague";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  # Fine-grained locale settings
  i18n.extraLocaleSettings = {
    LC_ADDRESS        = "cs_CZ.UTF-8";
    LC_IDENTIFICATION = "cs_CZ.UTF-8";
    LC_MEASUREMENT    = "cs_CZ.UTF-8"; # metric units, Celsius
    LC_MONETARY       = "cs_CZ.UTF-8";
    LC_NAME           = "cs_CZ.UTF-8";
    LC_NUMERIC        = "cs_CZ.UTF-8";
    LC_PAPER          = "cs_CZ.UTF-8";
    LC_TELEPHONE      = "cs_CZ.UTF-8";
    LC_TIME           = "cs_CZ.UTF-8"; # DD.MM.YYYY, 24h clock
  };  
}