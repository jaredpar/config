" Vim syntax file
" Language:	Msh
" Maintainer:	
" 	Jared Parsons <jaredp@beanseed.org>
"   Peter Provost <peter@provost.org>
" Last Change:	2005 Dec 19
" Remark:	Initial MSH syntax

" Compatible VIM syntax file start
if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

" MSH doesn't care about case
syn case ignore

" List of actual keywords and core language components
syn keyword mshConditional if else switch elseif
syn keyword mshRepeat while foreach default for do until break continue
syn keyword mshKeyword return where filter in trap throw
syn keyword mshKeyword function nextgroup=mshFunction skipwhite
syn match mshFunction /\w\+/ contained
syn match mshComment /#.*/
syn match mshCmdlet /\w\+-\w\+/
syn match mshCmdlet /new-object/ nextgroup=mshStandaloneType skipwhite
syn match mshCmdlet /remove-variable/ nextgroup=mshVariableName skipwhite
syn match mshCmdlet /set-content/ nextgroup=mshVariableName skipwhite

" Type declarations
syn match mshType /\[[a-z0-9_:.]\+\]/
syn match mshStandaloneType /[a-z0-9_.]\+/ contained
syn keyword mshScope global local private script contained

" Variables and other user defined items
syn match mshVariable /\$\w\+/ nextgroup=mshIndexer	
syn match mshVariable /\${\w\+:\\\w\+}/ nextgroup=mshIndexer
syn match mshVariable /\$\w\+:\w\+/ contains=mshScope nextgroup=mshIndexer
syn match mshVariableName /\w\+/ contained
syn match mshVariableName /\w\+:\\\w\+/ contained

" Operators
syn match mshOperatorStart /-c\?/ nextgroup=mshOperator
syn keyword mshOperator and not or as band bor is isnot lt le gt ge contained
syn keyword mshOperator bnot eq ne match notmatch contained
syn keyword mshOperator like notlike replace ireplace f contained
syn match mshOperator /(not)\?contains/ contained

" Constants 
syn region mshString start=/"/ skip=/`"/ end=/"/ keepend contains=mshVariable
syn region mshString start=/'/ skip=/`"/ end=/'/ keepend contains=mshVariable
syn match mshNumber /\<[0-9]\+/
syn match mshFloat /\<[0-9.]\+/

" Array indexers
syn match mshIndexer /\[[a-z0-9"'$]\+\]/ contained contains=mshString,mshNumber,mshFloat,mshVariable

if version >= 508 || !exists("did_msh_syn_inits")
  if version < 508
    let did_msh_syn_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif

	"Constants
  HiLink mshString 						String
	HiLink mshNumber 						Number
	HiLink mshFloat							Float

	"Keywords
	HiLink mshConditional 			Conditional
	HiLink mshFunction					Function
	HiLink mshOperator 					Operator
	HiLink mshRepeat						Repeat
	HiLink mshKeyword						Keyword
	HiLink mshCmdlet						Statement

	"Identifiers
	HiLink mshVariable					Identifier
	HiLink mshVariableName			Identifier

	"Types
	HiLink mshType							Type
	HiLink mshScope							Type
	HiLink mshStandaloneType		Type

	"Comment
	HiLink mshComment						Comment

	"Special
	HiLink mshIndexer						Special

  delcommand HiLink
endif

