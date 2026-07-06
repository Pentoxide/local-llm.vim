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
command! -nargs=1 LLLmContext call SendPromptContext(<q-args>)
command! LLLmSetFiM call ShowPopUp()

let g:endpoint = get(g:, 'llm_endpoint', 'http://localhost:11434/api/generate')
let g:model = get(g:, 'llm_model', 'gemma2:2b')
let g:system = get(g:, 'llm_system_prompt', 'You are Qwen3-Coder-Next, an expert software engineer.Respond with concise, correct code.Prefer standard libraries.When asked to write code, show only the code, no explanations, no examples.')
" FiM context size.
" 1 - local blocks of code, see g:block_count
" 2 - opened file
" 3 - all files in current directory
" 4 - entire repo
let g:fim_dict = {1: "local", 2: "full", 3: "directory", 4: "repository"}
let g:fim_context = get(g:, 'llm_fim_context', 1)
let g:block_count = 2

function! ShowPopUp() abort
  let popid = popup_menu(values(g:fim_dict),
                \ #{callback: 'SetFillInTheMiddleContext'})
  call win_execute(popid, 'call cursor(g:fim_context, 1)')
endfunction

function! SetFillInTheMiddleContext(a, choice) abort
  let g:fim_context = a:choice
endfunction

function! GetPrevEmptyLinePos() abort
  let l:block = 1
  let l:lnum = line('.')
  while empty(getline(l:lnum)) && l:lnum > 1
    let l:lnum -= 1
  endwhile
  while l:lnum > 1
    let l:lnum -= 1
    if empty(getline(l:lnum)) && l:block >= g:block_count
      return l:lnum
    elseif empty(getline(l:lnum)) && l:block < g:block_count
      let l:block += 1
      while empty(getline(l:lnum)) && l:lnum > 1
        let l:lnum -= 1
      endwhile
    endif
  endwhile
  return 0
endfunction

function! GetNextEmptyLinePos() abort
  let l:block = 1
  let l:lnum = line('.')
  while empty(getline(l:lnum)) && l:lnum <= line('$')
    let l:lnum += 1
  endwhile
  while l:lnum <= line('$')
    let l:lnum += 1
    if empty(getline(l:lnum)) && l:block >= g:block_count
      return l:lnum
    elseif empty(getline(l:lnum)) && l:block < g:block_count
      let l:block += 1
      while empty(getline(l:lnum)) && l:lnum <= line('$')
        let l:lnum += 1
      endwhile
    endif
  endwhile
  return line('$')
endfunction

function! CopyLinesBetween(start, end) abort
  let l:selection = join(getline(a:start, a:end), "\n")
  let l:selection = substitute(l:selection, '^\n\+\|\n\+$', '', 'g')
  let l:selection = escape(l:selection, '\"')
  let l:selection = substitute(l:selection, '\n', '\\n', 'g')
  let l:selection = substitute(l:selection, '\t', '\\t', 'g')
  return l:selection
endfunction

function! SendPrompt(prompt)
  let s:start_insert_line = getcurpos()[1] + 1
  let g:start = reltime()
  let g:job = job_start(BuildCmd(a:prompt), {'close_cb': 'CloseHandler'})
  echom "[".g:model."] Hallucinating..."
endfunction

function! SendPromptContext(prompt)
  let s:start_insert_line = getcurpos()[1] + 1
  if g:fim_context == 1
    let l:fim_prefix = CopyLinesBetween(GetPrevEmptyLinePos(), s:start_insert_line)
    let l:fim_suffix = CopyLinesBetween(s:start_insert_line + 1 , GetNextEmptyLinePos())
  else
    let l:fim_prefix = CopyLinesBetween(0, s:start_insert_line)
    let l:fim_suffix = CopyLinesBetween(s:start_insert_line + 1 , line('$'))
  endif
  let l:fim = '<|fim_prefix|>' . l:fim_prefix . '<|fim_suffix|>' . l:fim_suffix . '<|fim_middle|> '
  if g:fim_context > 2
    let l:fim_files = '<|file_sep|>{file_path1}\n{file_content1}'
    let l:fim = l:fim_files . l:fim
  endif
  if g:fim_context == 4
    let l:fim_repo = '<|repo_name|>{repo_name}'
    let l:fim = l:fim_repo . l:fim_files
  endif
  let l:prompt = join([a:prompt, l:fim], "")
  " echom l:prompt
  let g:start = reltime()
  let g:job = job_start(BuildCmd(l:prompt), {'close_cb': 'CloseHandler'})
  echom "[".g:model."] Hallucinating... (FiM: ". g:fim_dict[g:fim_context] .")"
endfunction

function! SendPromptExplain(prompt)
  let s:start_insert_line = getcurpos()[1]
  let l:selection = CopyLinesBetween("'<", "'>")
  let l:prompt = join([l:selection, " ", a:prompt], "")
  let g:start = reltime()
  let g:job = job_start(BuildCmd(l:prompt), {'close_cb': 'CloseHandler'})
  echom "[".g:model."] Hallucinating..."
endfunction

function! BuildCmd(prompt)
  return ['curl', '-s', g:endpoint, '-d',
    \ '{"model":"' . g:model . '",' .
    \ '"system":"' . g:system . '",' .
    \ '"prompt":"' . a:prompt . '",' .
    \ '"stream":false,' .
    \ '"options":{"temperature":1.0,"top-p":0.95,"top-k":40,"min-p":0.01,"num_ctx":65536}' . 
    \ '}' ]
endfunction

func! CloseHandler(channel)
  while ch_status(a:channel) == 'buffered'
    let l:result = ch_readraw(a:channel)
    let l:dict = json_decode(l:result)
    if has_key(l:dict, 'error')
        echohl ErrorMsg | echom "Service alive but returned an error: " . l:dict['error'] | echohl None
    else
        " echom l:result
        let l:message = split(l:dict.response, '\n')
        if len(l:message) > 0 && l:message[0] =~ '^```'
          call remove(l:message, 0)
        endif
        if len(l:message) > 0 && l:message[-1] =~ '^```'
          call remove(l:message, -1)
        endif
        call append(s:start_insert_line - 1, l:message)
        let l:intokps = l:dict.prompt_eval_count / ( l:dict.prompt_eval_duration / 1000000000.0 )
        let l:outtokps = l:dict.eval_count / ( l:dict.eval_duration / 1000000000.0 )
        echom "[".g:model."] Hallucination finished (".reltimestr(reltime(g:start))." sec., " .
            \ "In: " . l:intokps . " tok/s, "
            \ "Out: " . l:outtokps . " tok/s)"
    endif
  endwhile
endfunc
