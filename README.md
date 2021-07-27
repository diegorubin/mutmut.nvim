# mutmut.nvim

Displays mutmut mutant found in code.

![example.png example](/doc/example.png)

![showdiff.png showdiff](/doc/showdiff.png)

## Requirements

- Neovim 0.4.4+

## Installation

Using [packer.nvim](https://github.com/wbthomason/packer.nvim).

```
use {'diegorubin/mutmut.nvim'}
```

## Settings

```
require'mutmut'.setup {
    prescript = "Mutation: ",
    sqlite3_command = "sqlite3",
    mutmut_cache_file = "./.mutmut-cache"
}
```

## Commands

- __MutmutApply:__ execute mutmut apply for mutation found in current line
- __MutmutShowDiff:__ open window to show mutation diff
