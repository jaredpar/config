" Vim syntax file
" Language: PowerShell
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
syn keyword psConditional if else switch elseif
syn keyword psRepeat while foreach default for do until break continue
syn keyword psKeyword return where filter in trap throw
syn keyword psKeyword function nextgroup=psFunction skipwhite
syn match psFunction /[a-z-.]\+/ contained
syn match psComment /#.*/
syn match psCmdlet /\w\+-\w\+/
syn match psCmdlet /new-object/ nextgroup=psStandaloneType skipwhite
syn match psCmdlet /remove-variable/ nextgroup=psVariableName skipwhite
syn match psCmdlet /set-content/ nextgroup=psVariableName skipwhite

" Type declarations
syn match psType /\[[a-z0-9_:.]\+\]/
syn match psStandaloneType /[a-z0-9_.]\+/ contained
syn keyword psScope global local private script contained

" Variables and other user defined items
syn match psVariable /\$\w\+/ nextgroup=psIndexer	
syn match psVariable /\${\w\+:\\\w\+}/ nextgroup=psIndexer
syn match psVariable /\$\w\+:\w\+/ contains=psScope nextgroup=psIndexer
syn match psVariableName /\w\+/ contained
syn match psVariableName /\w\+:\\\w\+/ contained

" Operators
syn match psOperatorStart /-c\?/ nextgroup=psOperator
syn keyword psOperator and not or as band bor is isnot lt le gt ge contained
syn keyword psOperator bnot eq ne match notmatch contained
syn keyword psOperator like notlike replace ireplace f contained
syn match psOperator /(not)\?contains/ contained

" Constants 
syn region psString start=/"/ skip=/`"/ end=/"/ keepend contains=psVariable
syn region psString start=/'/ skip=/`"/ end=/'/ keepend contains=psVariable
syn match psNumber /\<[0-9]\+/
syn match psFloat /\<[0-9.]\+/

" Array indexers
syn match psIndexer /\[[a-z0-9"'$]\+\]/ contained contains=psString,psNumber,psFloat,psVariable

if version >= 508 || !exists("did_ps_syn_inits")
  if version < 508
    let did_ps_syn_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif

	"Constants
  HiLink psString 						String
	HiLink psNumber 						Number
	HiLink psFloat							Float

	"Keywords
	HiLink psConditional 			Conditional
	HiLink psFunction					Function
	HiLink psOperator 					Operator
	HiLink psRepeat						Repeat
	HiLink psKeyword						Keyword
	HiLink psCmdlet						Statement

	"Identifiers
	HiLink psVariable					Identifier
	HiLink psVariableName			Identifier

	"Types
	HiLink psType							Type
	HiLink psScope							Type
	HiLink psStandaloneType		Type

	"Comment
	HiLink psComment						Comment

	"Special
	HiLink psIndexer						Special

  delcommand HiLink
endif

