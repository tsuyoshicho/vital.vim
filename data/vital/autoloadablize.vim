" ___vital___
" NOTE: lines between '" ___vital___' is generated by :Vitalize.
" Do not modify the code nor insert new lines before '" ___vital___'
function! s:_SNR() abort
  if has('patch-8.2.1347')
    return expand('<SID>')
  else
    return printf('<SNR>%s_', matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze__SNR$'))
  endif
endfunction
execute join(['function! ${autoload_import}() abort', printf("return map(${funcdict}, \"vital#_${plugin_name}#function('%s' . v:key)\")", s:_SNR()), 'endfunction'], "\n")
delfunction s:_SNR
" ___vital___
