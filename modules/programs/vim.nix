{ config, lib, ... }:

let
  cfg = config.programs.vim;
in
{
  config = lib.mkIf cfg.enable {
    programs.vim.settings = {
      expandtab = true;
      shiftwidth = 2;
      tabstop = 2;
      number = true;
    };

    programs.vim.extraConfig = ''
      set autoindent
      set smartindent
      set softtabstop=2

      " Filetype-specific indentation
      filetype plugin indent on
      autocmd FileType nix setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
    '';
  };
}
