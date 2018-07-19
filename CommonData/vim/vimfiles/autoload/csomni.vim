" List of keywords and a pattern to match them
let s:list_keyword = [ 'class', 'catch', 'do', 'finally', 'for', 'foreach', 'interface', 'implements', 'namespace', 'struct', 'try' , 'this', 'while', 'using' ] 
let s:list_access = ['public', 'private', 'protected', 'internal' ] 
let s:list_empty = ['empty list' ]
let s:pat_keyword = '\C\<'.join(s:list_keyword, '\>\|\<') . '\>'
let s:pat_access = '\C\<'.join(s:list_access, '\>\|\<'). '\>'
let s:pat_line_comment = '\/\/.*'
let s:pat_comment = s:pat_line_comment
let s:pat_operator = '\.\|='
let s:pat_name = '\<\w\+\>'

" Dictionary types used in this scrpt
" @type scope_info (si)
"   .scope : class | method
"   .line : line number of the scope start
"   .name : qualified name of the scope
"
" @type token (tk)
"   .kind:   csKeyword | csDot | csOther | csConst | csParenOpen
"           csParenClose | csBraceOpen | csBraceClose | csAccess
"   .token: actual token text
"   .col:  starting column of the token.  1 based
" 
" @type var_info (vi)
"   .name : name of the variable
"   .si_scope : scope info for the variable
"   .line : line number where the variable is defined
"   .typename : qualified name of the type

" Tokenize a line of Csharp.  Returns a list of tokens where 
" token. (type token)
func! <SID>CsTokenize(argLine)
    let list_result = []
    let line = a:argLine

    " Regex for a token
    let pat_token = '[^[:alnum:]]\|\(\w\+\)\|\.\|\s\+'

    " Loop variables
    let index = 0
    let linelen = strlen(line)

    while index < linelen

        let endindex = matchend(line, pat_token, index)

        " If it didn't match anything in particular then process
        " a single character
        if endindex == -1
            let endindex = index + 1
        endif

        let token = strpart(line, index, endindex - index)
        let token = substitute(token, '\s', '', 'g')    "Remove spaces
        let result = { 'kind' : 'unknown', 'token' : token, 'col' : index + 1 }

        " Update the index now so that any of the if/else blocks can operate
        " easily.  For instance they can continue without causing an infinite
        " loop
        let index = endindex

        " Now than we have a token classify it
        if token == ""
            continue
        elseif token == 'true\|false\|\d\+'
            let result.kind = 'csConst'
        elseif token =~ s:pat_keyword
            let result.kind = 'csKeyword'
        elseif token =~ s:pat_access
            let result.kind = 'csAccess'
        elseif token == "."
            let result.kind = 'csDot'
        elseif token == '('
            let result.kind = 'csParenOpen'
        elseif token == ')'
            let result.kind = 'csParenClose'
        elseif token == '{'
            let result.kind = 'csBraceOpen'
        elseif token == '}'
            let result.kind = 'csBraceClose'
        elseif token =~ s:pat_name
            let result.kind = 'csName'
        endif

        " Add the result to the list
        call extend(list_result, [result])

    endwhile
     
    return list_result

endfunc

" Qualify a type name.  Returns "" if the type name
" could not be found
" @param arg_scope (scope_info): Current scope to search in for the type name
" @param arg_name: Unqualified name
" @return fully qualified name if found, otherwise empty string
func! <SID>CsQualifyTypeName(arg_scope, arg_name)
    let si = a:arg_scope
    let name = a:arg_name

    let list_scope = <SID>CsNameToScopes(si.name)
    for scope in list_scope
        let query = '^'.scope.'\.'.name.'$'
        let list_tag = taglist(query)
        for itag in list_tag
            if itag.kind == 'c'
                return itag.namespace.'.'.itag.name
            endif
        endfor
    endfor

    " Lastly check to see if the name is already fully qualified
    let query = '^'.name.'$'
    let list_tag = taglist(query)
    for itag in list_tag
        if itag.kind == 'c'
            return itag.namespace.'.'.itag.name
        endif
    endfor

    return ''
endfunc

" Find a variable with the specified information
" @param arg_scope (scope_info) : Scope to search in
" @param arg_name: name of the variable
" @param arg_line: starting line to look from
" @return var_info for the variable (empty if not found)
func! <SID>CsFindVariable(arg_scope, arg_name, arg_line)
    let si_scope = a:arg_scope
    let cur_lnum = a:arg_line
    let name = a:arg_name

    let vi = { 'name' : name, 'si_scope' : si_scope, 'line' : -1, 'typename' : '' }

    " If this is a method, see if it's a variable local to the method
    if si_scope.scope == 'method'
        while cur_lnum > si_scope.line 
            let list_token = <SID>CsTokenize(getline(cur_lnum))
            
            if len(list_token) >= 3
                        \ && list_token[0].kind == 'csName'
                        \ && list_token[1].kind == 'csName'
                        \ && list_token[1].token == name
                
                let third = list_token[2]
                if third.token== ';' || third.token== '='
                    let vi.typename = <SID>CsQualifyTypeName(si_scope, list_token[0].token)
                    let vi.line = cur_lnum
                    break
                endif
            endif

            let cur_lnum -= 1
        endwhile

        " If it was a local variable then return it
        if vi.typename != '' && vi.line != -1
            return vi 
        endif
    endif


    " Not a local variable, check the parameter list if this is a method
    if si_scope.scope == 'method' 
        let done = 0
        let cur_lnum = si_scope.line

        " State machine to walk through the parameters
        " States: beforeparen, inparen, aftertype, aftername
        let state = 'beforeparen'
        while done == 0
            let list_token = <SID>CsTokenize(getline(cur_lnum))
            let index = 0
            let last_type = ''

            while done == 0 && index < len(list_token)
                let tk = list_token[index]
    
                if state == 'beforeparen'
                    if tk.kind == 'csParenOpen'
                        let state = 'inparen'
                    endif
                elseif state == 'inparen'
                    if tk.kind == 'csParenClose'
                        let done = 1
                    elseif tk.kind == 'csName'
                        let last_type = tk.token
                        let state = 'aftertype'
                    endif
                elseif state == 'aftertype'
                    if tk.kind == 'csName'
                        
                        " This could be our variable
                        if tk.token == name
                            let done = 1
                            let vi.typename = <SID>CsQualifyTypeName(si_scope, last_type)
                            let vi.line = cur_lnum
                        endif

                        let state = 'aftername'
                    endif
                elseif state == 'aftername'
                    if tk.token == ','
                        let state = 'inparen'
                    elseif tk.kind == 'csParenClose'
                        let done = 1
                    endif
                endif
                let index +=1 
            endwhile

            let cur_lnum += 1
        endwhile

        " If it was a parameter then return it
        if vi.typename != '' && vi.line != -1
            return vi 
        endif
    endif

    " If the scope is a method or a class then check the owning class for
    " a field or property of that name
    if si_scope.scope == 'method' || si_scope.scope == 'class'
        let class_name = ''
        if si_scope.scope == 'class'
            let class_name = si_scope.name
        else
            let class_name = <SID>CsRemoveRightName(si_scope.name)
        endif

        "todo: finish this up

    return {}
endfunc

" Remove the right name of the qualified name.  Returns "" 
" if the name is not qualified
" @param arg_name
" @return name with the right part remove
func! <SID>CsRemoveRightName(arg_name)
    let name = a:arg_name
    let index = match(name, '\.\w\+$')

    if index == -1
        return ''
    endif

    return strpart(name, 0, index)
endfunc

" Get the items in all of the available scopes that match the pattern
" passed in.  
" @param arg_list_scope - scopes to search
" @param arg_query - query within each scope
" @return list of items in the available scope
func! <SID>CsGetScopeItems(arg_list_scope, arg_query)

    let list_items = []
    for scope in a:arg_list_scope
        let query = '^'.scope.'\.'.a:arg_query.'$'
        for itag in taglist(query)

            let item = { 'word' : itag.name, 'kind' : itag.kind}

            " Strip the item to it's last word
            let dot_index = match(item.word, '\.\w\+$')
            if dot_index >= 0
                let item.word = strpart(item.word, dot_index+1)
            endif

            call extend(list_items, [item])
        endfor
    endfor

    return list_items
endfunc

" Break a qualified name into it's scopes
" @param name - qualified name
" @return list of scopes that name represents
func! <SID>CsNameToScopes(arg_name)
   let list_scope = [a:arg_name]
   let list_token = <SID>CsTokenize(a:arg_name)
   let index = len(list_token) - 3

   while index >= 0
       let name = <SID>CsNameFromTokens(list_token, index)
       call extend(list_scope, [name])
       let index -= 2
   endwhile

   return list_scope
endfunc

" Given a list of tokens and an index create the biggest name
" possible.  So if we're given the tokens
"   Foo | . | Bar | .
" and the index is 3 we will return
"   Foo.Bar
" Leave off the trailing token since it doesn't make any sense
"
" For some reason tags only supports one level of namespaces 
" so we can not return a three part name.  Instead we shorten
" it to only the 2 involved
func! <SID>CsNameFromTokens(list_token, last_index)

    let name = ""
    let index = a:last_index
    let name_count = 0

    while index >= 0

        let token = a:list_token[index]

        if token.kind == 'csDot'
            let name = '.'.name
        elseif token.kind == 'csName'
            let name = token.token . name
            let name_count = name_count + 1

            if name_count == 2
                let index = -1
            endif
        else
            break
        end

        let index = index - 1

    endwhile

    while name =~ '^.*\.$'
        let name = strpart(name, 0, len(name) - 1)
    endwhile

    return name

endfunc

" Determines the scope based on the line number passed in.  Returns a
" dictionary with the following information
"
" @param arg_line: Starting line number
" @return scope_info for that line.  {} if no scope could be found
func! <SID>CsDetermineScope(arg_line)

    let cur_lnum = a:arg_line

    while cur_lnum > 0
        let line = getline(cur_lnum)
        let list_token = <SID>CsTokenize(line)
        let len = len(list_token)

        if 0 == len
            let cur_lnum -= 1
            continue
        endif

        " Remove the access modifier
        if list_token[0].kind == 'csAccess'
            call remove(list_token, 0)
        endif

        if len >= 3
                    \ && list_token[0].kind == 'csName'
                    \ && list_token[1].kind == 'csName'
                    \ && list_token[2].kind == 'csParenOpen'
            " If we now have 2 names followed by an open 
            " paren then this is a method
            let query = '^.*\.'.list_token[1].token . '$'
            let list_tag = taglist(query)

            for itag in list_tag
                if itag.kind == 'm'
                    return {'scope' : 'method', 'line' : cur_lnum, 'name' : itag.name}
                endif
            endfor

            " Could not find a matching method name
            return {}
        elseif len(list_token) >= 2
                    \ && list_token[0].kind == 'csKeyword'
                    \ && list_token[0].token == 'class'
                    \ && list_token[1].kind == 'csName'
            " It's a class.
            let query = '^.*\.'.list_token[1].token . '$'
            let list_tag = taglist(query)
            for itag in list_tag
                if itag.kind == 'c'
                    return {'scope' : 'method', 'line': cur_lnum, 'name' : itag.name }
                endif
            endfor

            " Could not find a matching class
            return {}
        else
            " Unknown list of tokens, just continue
        endif

        let cur_lnum -= 1
    endwhile

    return {}
endfunc

" Build the scope list based on the line number
" @param lnum - line number to start from
" @return List of scopes
func! <SID>CsGetScopesForPosition(lnum)

    let list_scope = []
    let info = <SID>CsDetermineScope(a:lnum)
    if empty(info)
        return list_scope
    endif

    " Tokenize the line and re-combine the parts
    let list_token = <SID>CsTokenize(info.name)
    let len = len(list_token) - 1

    while len >= 0
        let name = <SID>CsNameFromTokens(list_token, len)
        call extend(list_scope, [name])
        let len -= 2    "Move past the name and dot"
    endwhile

    return list_scope
endfunc


" Called to find the text that is being completed for the line.  
" @return Returns the other column which when combined with the 
"   current column creates a selection to be replaced.  If no
"   completion is possible then -1 is returned
func! <SID>CsFindReplacePosition()
    let line = getline('.')
    let list_token = <SID>CsTokenize(line)
    let len = len(list_token)

    " If there are no tokens on the current line then we don't have to
    " worry because we are in a blank space so we're replacing nothing
    if len == 0
        return col('.')
    endif

    let last_token = list_token[len-1]
    if last_token.kind == 'csDot'
        " Complet was called immediately after hitting a dot.  To prevent
        " omni complete from auto-inserting some text we will hack around 
        " and return "." as the base.  Then we pre-pend every entry with "."
        " and add "." to the possible match list.  
        return last_token.col
    elseif last_token.kind == 'csName'
                \ && len > 1
                \ && list_token[len-2].kind == 'csDot'
        return list_token[len-1].col - 1
    else
        return col('.')
    endif
endfunc

" Find the completion
" @param arg_base - text being replaced
" @return possible matches
func! <SID>CsFindComplete(arg_base)
    
    let cur_lnum = line('.')
    let scope_info = <SID>CsDetermineScope(cur_lnum)
    let list_token = <SID>CsTokenize(getline(cur_lnum))
    let list_token_len = len(list_token)
    let list_scope = []

    " If we can't determine the scope then there is nothing to do
    if empty(scope_info)
        return []
    endif

    " Determine the type of replacement
    if list_token_len == 0
        " No tokens on the current line.  This means that all subscopes of our
        " current scope are valid.  Tokenize and recombine the names
        call extend(list_scope, <SID>CsNameToScopes(scope_info.name))
    else

        let last_token = list_token[list_token_len-1]

        " When determining the type of replacement we need to do some work
        " for .somename.  Since the arg_base already holds the info we 
        " can ignore it and reduce the amount of cases that we need
        " to handle
        if list_token_len > 2
                    \ && last_token.kind == 'csName'
                    \ && last_token.token == a:arg_base
                    \ && list_token[list_token_len-2].kind == 'csDot'
            call remove(list_token, list_token_len - 1)
            let list_token_len -= 1
            let last_token = list_token[list_token_len]
        endif

        if list_token_len >= 2
                    \ && last_token.kind == 'csDot'
                    \ && list_token[list_token_len-2].kind == 'csKeyword'
                    \ && list_token[list_token_len-2].token == 'this'
            " It's a this. replacement.   
            if scope_info.scope == 'method'
                let class_name = <SID>CsRemoveRightName(scope_info.name)
                call extend(list_scope, [class_name])
            elseif scope_info.scope == 'class'
                call extend(list_scope, [scope_info.name])
            else
                echo "Unrecognized scope value"
            endif
        elseif list_token_len >= 2
                    \ && last_token.kind == 'csDot'
                    \ && list_token[list_token_len-2].kind == 'csName'
            " It's a variable. replacement.  Find the variable and add it's
            " type name to the list of scopes
            let vi = <SID>CsFindVariable(scope_info, list_token[list_token_len-2].token, cur_lnum)
            if empty(vi)
                return []
            endif

            call extend(list_scope, [vi.typename])
        endif
    endif
             
    let query = '.*'
    if a:arg_base != ''
        let query = a:arg_base.'.*'
    endif

    return <SID>CsGetScopeItems(list_scope, query)
endfunc

func! csomni#Complete(findStart, base)

    if a:findStart == 1 
        return <SID>CsFindReplacePosition()
    elseif a:base == '.'
        let list_result = <SID>CsFindComplete('')

        for result in list_result
            let result.word = '.'.result.word
        endfor

        call add(list_result, { 'word' : '.', 'kind' : 'm' })
        return list_result
    else
        return <SID>CsFindComplete(a:base)
    endif

endfunc
