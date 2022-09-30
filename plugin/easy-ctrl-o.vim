" easy-ctrl-o.vim       Pull out your Ctrl and O keys!
" Author:               Yichao Zhou (broken.zhou AT gmail) and aselker
" Version:              0.2
" ---------------------------------------------------------------------

if &cp || exists("g:loaded_easy_ctrl_o")
    finish
endif
let g:loaded_easy_ctrl_o = 1
let s:haspy3 = has("python3")

if !exists("g:easy_ctrl_o_chars")
    let g:easy_ctrl_o_chars = { "d": 1, "f": 1 }
endif
if !exists("g:easy_ctrl_o_timeout")
    if s:haspy3
        let g:easy_ctrl_o_timeout = 100
    else
        let g:easy_ctrl_o_timeout = 2000
    endif
endif

if !s:haspy3 && g:easy_ctrl_o_timeout < 2000
    echomsg "Python3 is required when g:easy_ctrl_o_timeout < 2000"
    let g:easy_ctrl_o_timeout = 2000
endif

function! s:EasyCtrlOInsertCharPre()
    if has_key(g:easy_ctrl_o_chars, v:char) == 0
        let s:current_chars = copy(g:easy_ctrl_o_chars)
    endif
endfunction

function! s:EasyCtrlOSetTimer()
    if s:haspy3
        py3 easy_ctrl_o_time = default_timer()
    endif
    let s:localtime = localtime()
endfunction

function! s:EasyCtrlOReadTimer()
    if s:haspy3
        py3 vim.command("let pyresult = %g" % (1000 * (default_timer() - easy_ctrl_o_time)))
        return pyresult
    endif
    return 1000 * (localtime() - s:localtime)
endfunction

function! <SID>EasyCtrlOMap(char)
    if exists("b:easy_ctrl_o_disable") && b:easy_ctrl_o_disable == 1
        return a:char
    endif
    if s:current_chars[a:char] == 0
        let s:current_chars = copy(g:easy_ctrl_o_chars)
        let s:current_chars[a:char] = s:current_chars[a:char] - 1
        call s:EasyCtrlOSetTimer()
        return a:char
    endif

    if s:EasyCtrlOReadTimer() > g:easy_ctrl_o_timeout
        let s:current_chars = copy(g:easy_ctrl_o_chars)
        let s:current_chars[a:char] = s:current_chars[a:char] - 1
        call s:EasyCtrlOSetTimer()
        return a:char
    endif

    let s:current_chars[a:char] = s:current_chars[a:char] - 1
    for value in values(s:current_chars)
        if value > 0
            call s:EasyCtrlOSetTimer()
            return a:char
        endif
    endfor

    let s:current_chars = copy(g:easy_ctrl_o_chars)

    " Workaround for #3, might be less annoying but still not perfect
    let current_line = getline(".")
    let current_line_trimed  = substitute(current_line, '^\s*\(.\{-}\)\s*$', '\1', '')
    let n_chars = eval(join(values(g:easy_ctrl_o_chars), "+")) - 1

    let seq = s:escape_sequence
    if col(".") == len(current_line) + 1 && n_chars == len(current_line_trimed)
        let seq = seq . '0"_D'
    endif

    return seq

endfunction

let s:current_chars = copy(g:easy_ctrl_o_chars)

augroup easy_ctrl_o
    au!
    au InsertCharPre * call s:EasyCtrlOInsertCharPre()
augroup END

for key in keys(g:easy_ctrl_o_chars)
    exec "inoremap <expr>" . key . " <SID>EasyCtrlOMap(\"" . key . "\")"
endfor

if s:haspy3
    py3 from timeit import default_timer
    py3 import vim
    call s:EasyCtrlOSetTimer()
else
    let s:localtime = localtime()
endif

let s:escape_sequence = repeat("\<BS>", eval(join(values(g:easy_ctrl_o_chars), "+"))-1) . "\<C-o>"

" vim:set expandtab tabstop=4 shiftwidth=4:
