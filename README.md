# local LLMs @ vim

## Why?

If you love vim and want to use LLMs you hosting locally with vim this plugin can help you

## Limitations

Only [ollama](https://github.com/ollama/ollama) supported for now

String parsing is funky so sometimes it breaks, working on it...

## Installation

### Using [vim-plug](https://github.com/junegunn/vim-plug)
```sh
Plug 'pentoxide/local-llm.vim'
```

### Dependencies

None for the plugin, but those should be available:
- Curl
- ollama

## Commands

| Command                 | Description                                  |
| ---                     | ---                                          |
| `:LLLmPrompt [prompt]`  | Write a prompt and it return result          |
| `:LLLmExplain [prompt]` | Select and write prompt for explain or help  |

- LLLmPrompt includes "Exclude explanation and example", which sometimes doesn't work
- Selection works with **Visual**, **Visual Line**, or **Visual Block**

## Customization

For now only two option could be customized:
```vim
" Custom endpoint
let g:llm_endpoint = 'http://localhost:11434/api/generate'
" Select llm model
let g:llm_model = 'deepseek-coder-v2:latest'
```

## Mappings

```vim
" Mapping Ctrl-l for prompt in NORMAL mode
nnoremap <C-l> :LLLmPrompt 
" Mapping Ctrl-l for prompt in VISUAL mode
vnoremap <C-l> :LLLmExplain Explain the code above
```

## License

GPL-2.0
