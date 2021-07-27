augroup Mutmut
  autocmd!
augroup end

command! MutmutApply lua require'mutmut'.apply()
command! MutmutShowDiff lua require'mutmut'.showdiff()
