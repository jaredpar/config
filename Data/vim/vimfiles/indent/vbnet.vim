if exists("b:did_indent") 
    finish
endif
let b:did_indent=1

echo "VbNet indent loaded"

" Set our indent expressions
setlocal indentexpr=VbIndentGet(v:lnum)
setlocal indentkeys+==end

func! VbStripAccessModifiers(line)

    let pat = '\cpublic\|private\|friend'
    let index = matchend(a:line, pat)

    " Make sure there is one
    if -1 == index 
        return a:line
    endif

    return strpart(a:line, index + 1)
endfunc

" Get the value for increasing indent on the passed in 
" line
func! VbGetIncreaseIndent(lnum)
   return indent(a:lnum) + &shiftwidth 
endfunc

func! VbIndentBlockEnd(lnum)

    " Scroll backwards until we find the indentifier for the previous block
    let cur_lnum = a:lnum - 1
    while cur_lnum >= 0
        let cur_line = getline(cur_lnum)
        let cur_line = VbStripAccessModifiers(cur_line)

        if -1 == match(cur_line, '\cclass\|if\')
            let cur_lnum = cur_lnum - 1
        else
            break
        endif
    endwhile

    " Check for 0 
    if cur_lnum <= 0
        return -1
    endif

    " Return the indent of the indentifier line
    return indent(cur_lnum)
endfunc

func! VbIndentGet(cur_lnum)

    " Get the line just entered
    let cur_line = getline(a:cur_lnum)

    " If the current word is 'end' then decrease the indent
    if -1 != match(cur_line, '\c\s*end.*')
        return VbIndentBlockEnd(a:cur_lnum)
    endif

    return -1
endfunc

