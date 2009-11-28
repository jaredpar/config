
if exists("b:current_compiler")
  finish
endif
let b:current_compiler = "build"
if exists(":CompilerSet") != 2  " older Vim always used :setlocal
  command -nargs=* CompilerSet setlocal <args>
endif

func! Make_bclib()
    cd bclib
    :cd!
    :make! 
    cd ..
endfunc

CompilerSet makeprg=msbuild\ /t:build

map <C-F2> :call Make_bclib()<CR>
