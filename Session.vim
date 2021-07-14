let SessionLoad = 1
let s:so_save = &g:so | let s:siso_save = &g:siso | setg so=0 siso=0 | setl so=-1 siso=-1
let v:this_session=expand("<sfile>:p")
silent only
silent tabonly
cd ~/repos/perso/linkhut-ext
if expand('%') == '' && !&modified && line('$') <= 1 && getline(1) == ''
  let s:wipebuf = bufnr('%')
endif
set shortmess=aoO
badd +31 src/elm/Popup.elm
badd +161 ~/.elm/0.19.1/packages/elm/browser/1.0.2/src/Browser.elm
badd +223 ~/.elm/0.19.1/packages/mdgriffith/elm-ui/1.1.8/src/Element.elm
badd +2 extension/popup/linkhut.css
badd +1 ~/rc/nvim_lua/after/ftplugin/elm_treesitter.vim
badd +342 ~/.elm/0.19.1/packages/mdgriffith/elm-ui/1.1.8/src/Internal/Model.elm
badd +65 ~/.elm/0.19.1/packages/elm/core/1.0.5/src/Platform/Cmd.elm
argglobal
%argdel
$argadd src/elm/Popup.elm
edit src/elm/Popup.elm
argglobal
setlocal fdm=expr
setlocal fde=nvim_treesitter#foldexpr()
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=20
setlocal fml=1
setlocal fdn=10
setlocal fen
let s:l = 31 - ((30 * winheight(0) + 20) / 41)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 31
normal! 0
tabnext 1
if exists('s:wipebuf') && len(win_findbuf(s:wipebuf)) == 0&& getbufvar(s:wipebuf, '&buftype') isnot# 'terminal'
  silent exe 'bwipe ' . s:wipebuf
endif
unlet! s:wipebuf
set winheight=1 winwidth=20 shortmess=filnxtToOFcI
let s:sx = expand("<sfile>:p:r")."x.vim"
if filereadable(s:sx)
  exe "source " . fnameescape(s:sx)
endif
let &g:so = s:so_save | let &g:siso = s:siso_save
set hlsearch
let g:this_session = v:this_session
let g:this_obsession = v:this_session
let g:this_obsession_status = 2
doautoall SessionLoadPost
unlet SessionLoad
" vim: set ft=vim :
