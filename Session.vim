let SessionLoad = 1
let s:so_save = &g:so | let s:siso_save = &g:siso | setg so=0 siso=0 | setl so=-1 siso=-1
let v:this_session=expand("<sfile>:p")
silent only
silent tabonly
cd ~/code/personal/linkhut-webextension
if expand('%') == '' && !&modified && line('$') <= 1 && getline(1) == ''
  let s:wipebuf = bufnr('%')
endif
let s:shortmess_save = &shortmess
if &shortmess =~ 'A'
  set shortmess=aoOA
else
  set shortmess=aoO
endif
badd +1 extension/background/authorize.js
badd +17 extension/background/main.js
badd +44 extension/options/elm-options-loader.js
badd +48 extension/popup/elm-popup-loader.js
badd +1 package-lock.json
badd +13 package.json
badd +1 src/Popup.elm
badd +9 src/Options.elm
badd +3 extension/background/logger.js
badd +1 extension/popup/popup.html
badd +1 extension/popup/elm.js
badd +1 README.md
badd +13 DEV.md
badd +27 TODO.md
badd +1 src/Colors.elm
badd +1 ~/.elm/0.19.1/packages/elm/url/1.0.0/src/Url/Builder.elm
badd +302 ~/rc/nvim/lua/pyrho/plugins/conf/heirline.lua
badd +0 ~/rc/nvim/snippets/elm.json
badd +1310 ~/.elm/0.19.1/packages/mdgriffith/elm-ui/1.1.8/src/Element.elm
badd +524 ~/.elm/0.19.1/packages/mdgriffith/elm-ui/1.1.8/src/Element/Font.elm
badd +177 ~/.elm/0.19.1/packages/mdgriffith/elm-ui/1.1.8/src/Element/Input.elm
badd +1867 ~/.elm/0.19.1/packages/mdgriffith/elm-ui/1.1.8/src/Internal/Model.elm
badd +1 TDO
badd +1 elm.json
argglobal
%argdel
set stal=2
tabnew +setlocal\ bufhidden=wipe
tabnew +setlocal\ bufhidden=wipe
tabrewind
edit src/Popup.elm
let s:save_splitbelow = &splitbelow
let s:save_splitright = &splitright
set splitbelow splitright
let &splitbelow = s:save_splitbelow
let &splitright = s:save_splitright
wincmd t
let s:save_winminheight = &winminheight
let s:save_winminwidth = &winminwidth
set winminheight=0
set winheight=1
set winminwidth=0
set winwidth=1
argglobal
balt ~/.elm/0.19.1/packages/mdgriffith/elm-ui/1.1.8/src/Element.elm
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=20
setlocal fml=1
setlocal fdn=10
setlocal fen
silent! normal! zE
let &fdl = &fdl
let s:l = 531 - ((18 * winheight(0) + 18) / 37)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 531
normal! 065|
tabnext
edit extension/background/logger.js
argglobal
balt extension/background/authorize.js
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=20
setlocal fml=1
setlocal fdn=10
setlocal fen
silent! normal! zE
let &fdl = &fdl
let s:l = 3 - ((2 * winheight(0) + 18) / 37)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 3
normal! 018|
tabnext
edit TODO.md
argglobal
setlocal fdm=expr
setlocal fde=Foldexpr_markdown(v:lnum)
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=20
setlocal fml=1
setlocal fdn=10
setlocal fen
2
normal! zo
let s:l = 25 - ((24 * winheight(0) + 18) / 37)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 25
normal! 017|
tabnext 1
set stal=1
if exists('s:wipebuf') && len(win_findbuf(s:wipebuf)) == 0 && getbufvar(s:wipebuf, '&buftype') isnot# 'terminal'
  silent exe 'bwipe ' . s:wipebuf
endif
unlet! s:wipebuf
set winheight=1 winwidth=20
let &shortmess = s:shortmess_save
let s:sx = expand("<sfile>:p:r")."x.vim"
if filereadable(s:sx)
  exe "source " . fnameescape(s:sx)
endif
let &g:so = s:so_save | let &g:siso = s:siso_save
let g:this_session = v:this_session
let g:this_obsession = v:this_session
let g:this_obsession_status = 2
doautoall SessionLoadPost
unlet SessionLoad
" vim: set ft=vim :
