{ config, lib, ... }:

let
  cfg = config.programs.neovim;
in
{
  config = lib.mkIf cfg.enable {
    programs.neovim.extraConfig = ''
      set expandtab
      set shiftwidth=2
      set tabstop=2
      set number

      set autoindent
      set smartindent
      set softtabstop=2

      " Filetype-specific indentation
      filetype plugin indent on
      autocmd FileType nix setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab

      " Source wallust colors if available
      if filereadable(expand("~/.cache/wallust/colors-wal.vim"))
        source ~/.cache/wallust/colors-wal.vim
      endif
    '';
  };
}
