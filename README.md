# local LLMs @ vim

## Why?

If you love vim and wanted to use LLMs hosted locally, this plugin can help you

## Limitations

Only [ollama](https://github.com/ollama/ollama) supported for now

Plugin doesn't check if model supports [FiM](https://deepwiki.com/QwenLM/Qwen3-Coder/3.3-fill-in-the-middle-(fim)). 

## Installation

### Dependencies

None for the plugin, but those should be available:
- [Curl](https://github.com/curl/curl)
- [ollama](https://github.com/ollama/ollama)

### Using [vim-plug](https://github.com/junegunn/vim-plug)
```sh
Plug 'pentoxide/local-llm.vim'
```

## Commands

| Command                 | Description                                           |
| ---                     | ---                                                   |
| `:LLLmPrompt [prompt]`  | Write a prompt and it will return a result            |
| `:LLLmExplain [prompt]` | Select code and write prompt for explaination or help |
| `:LLLmContext [prompt]` | !!!BETA!!! Not fully tested. Sends [FiM](https://deepwiki.com/QwenLM/Qwen3-Coder/3.3-fill-in-the-middle-(fim)) context tokens along with the prompt |
| `:LLLmSetFiM`           | Choose FiM context size: local (full block of the code between empty lines before and after the insertion, whole opened file, TODO: all files in the directory, all files in the repo) |

- System prompt includes "Exclude explanation and example", which sometimes doesn't work
- Selection works with **Visual**, **Visual Line** and **Visual Block**

## Customization

Following option could be customized:
```vim
" Custom endpoint
let g:llm_endpoint = 'http://localhost:11434/api/generate'
" Select llm model
let g:llm_model = 'deepseek-coder-v2:latest'
" Set system prompt
let g:llm_system_prompt = 'You are an expert'
" FiM context, values 1-4 (optional, defaults to 1)
let g:llm_fim_context = 2
```

## Mappings

```vim
" Mapping Ctrl-i for Instruction prompt in NORMAL mode
nnoremap <C-i> :LLLmPrompt 
" Mapping Ctrl-l for FiM prompt in NORMAL mode
nnoremap <C-l> :LLLmContext 
" Mapping Ctrl-l for explaination in VISUAL mode
vnoremap <C-l> :LLLmExplain Explain the code above
" Mapping Alt-l for FiM context selector
nnoremap <A-l> :LLLmSetFiM<CR>
```

## License

GPL-2.0
