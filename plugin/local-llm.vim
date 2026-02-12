" Title:        Vim local LLM
" Description:  A plugin to provide interface for local llms
" Last Change:  12 Feb 2026
" Maintainer:   Pentoxide <https://github.com/Pentoxide>

if exists("g:loaded_local_llm")
    finish
endif
let g:loaded_local_llm = 1

command! -nargs=1 LLLmPrompt call SendPrompt(<q-args>)
command! -range -nargs=1 LLLmExplain call SendPromptExplain(<q-args>)

let g:endpoint = get(g:, 'llm_endpoint', 'http://localhost:11434/api/generate')
let g:model = get(g:, 'llm_model', 'gemma2:2b')

function! SendPrompt(prompt)
  let s:start_insert_line = getcurpos()[1]
  let l:instruction = " Exclude explanation and examples, give me only the code."
  let l:prompt = SafeString(join([a:prompt, l:instruction], ""))
  let g:job = job_start(BuildCmd(l:prompt), {'close_cb': 'CloseHandler'})
  echom "Hallucinating..."
endfunction

function! SendPromptExplain(prompt)
  let reg_a = getreg('a')
  silent normal! gv"ay
  let l:selection = substitute(getreg('a'), '\n', '\\n', "g")
  call setreg('a', reg_a)
  let s:start_insert_line = getcurpos()[1]
  let l:prompt = SafeString(join([l:selection, " ", a:prompt], ""))
  let g:job = job_start(BuildCmd(l:prompt), {'close_cb': 'CloseHandler'})
  echom "Hallucinating..."
endfunction

function! SafeString(param1)
  let l:parsed = substitute(a:param1, ' ', '\\ ', "g")
  return l:parsed
endfunction

function! BuildCmd(prompt)
  let l:cmd = 'curl -s '
  let l:cmd .= g:endpoint
  let l:cmd .= ' -d {\"model\":\"'
  let l:cmd .= g:model
  let l:cmd .= '\",\"prompt\":\"'
  let l:cmd .= a:prompt
  let l:cmd .= '\",\"temperature\":0.7,\"stream\":false}'
  " echom l:cmd
  return l:cmd
endfunction

func! CloseHandler(channel)
  while ch_status(a:channel) == 'buffered'
    let l:result = ch_readraw(a:channel)
    let l:dict = json_decode(l:result)
    let l:message = split(l:dict.response, '\n')
    " call remove(l:message, 0)
    " call remove(l:message, -1)
    call append(s:start_insert_line - 1, l:message)
    echom "Hallucination finished"
  endwhile
endfunc
