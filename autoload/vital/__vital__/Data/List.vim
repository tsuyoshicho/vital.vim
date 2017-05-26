" Utilities for list.

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:Closure = a:V.import('Data.Closure')
endfunction

function! s:_vital_depends() abort
  return ['Data.Closure']
endfunction


function! s:pop(list) abort
  return remove(a:list, -1)
endfunction

function! s:push(list, val) abort
  call add(a:list, a:val)
  return a:list
endfunction

function! s:shift(list) abort
  return remove(a:list, 0)
endfunction

function! s:unshift(list, val) abort
  return insert(a:list, a:val)
endfunction

function! s:cons(x, xs) abort
  return [a:x] + a:xs
endfunction

function! s:uncons(xs) abort
  if len(a:xs) < 1
    throw 'vital: Data.List: uncons() requires non empty list'
  endif
  " This is pair (tuple)
  return [a:xs[0], a:xs[1:]]
endfunction

function! s:conj(xs, x) abort
  return a:xs + [a:x]
endfunction

function! s:map(xs, f) abort
  let l:Call = s:_get_caller(a:f)
  let result = []
  for x in a:xs
    call add(result, l:Call(a:f, [x]))
  endfor
  return result
endfunction

function! s:filter(xs, f) abort
  let l:Call = s:_get_caller(a:f)
  let result = []
  for x in a:xs
    if l:Call(a:f, [x])
      call add(result, x)
    endif
  endfor
  return result
endfunction

" Removes duplicates from a list.
function! s:uniq(list) abort
  return s:uniq_by(a:list, 'v:val')
endfunction

" Removes duplicates from a list.
function! s:uniq_by(list, f) abort
  let l:Call  = s:_get_caller(a:f)
  let applied = []
  let result  = []
  for x in a:list
    let y = l:Call(a:f, [x])
    if !s:has(applied, y)
      call add(result, x)
      call add(applied, y)
    endif
  endfor
  return result
endfunction

function! s:clear(list) abort
  if !empty(a:list)
    unlet! a:list[0 : len(a:list) - 1]
  endif
  return a:list
endfunction

" Concatenates a list of lists.
" XXX: Should we verify the input?
function! s:concat(list) abort
  let memo = []
  for Value in a:list
    let memo += Value
  endfor
  return memo
endfunction

" Take each elements from lists to a new list.
function! s:flatten(list, ...) abort
  let limit = a:0 > 0 ? a:1 : -1
  let memo = []
  if limit == 0
    return a:list
  endif
  let limit -= 1
  for Value in a:list
    let memo +=
          \ type(Value) == type([]) ?
          \   s:flatten(Value, limit) :
          \   [Value]
    unlet! Value
  endfor
  return memo
endfunction

" Sorts a list with expression to compare each two values.
" a:a and a:b can be used in string expression ({f}).
function! s:sort(list, f) abort
  if type(a:f) is type(function('function'))
    return sort(a:list, a:f)
  else
    " Give up job safety (atomically)
    let s:sort_expr = a:f
    return sort(a:list, 's:_compare_by_string_expr')
  endif
endfunction

" Lifts the string expression to the function.
" s:sort_expr must be defined as the string expression of the binary function
" before this is called.
" a:a and a:b are used in s:sort_expr .
function! s:_compare_by_string_expr(a, b) abort
  return eval(s:sort_expr)
endfunction


" Sorts a list using a set of keys generated by mapping the values in the list
" through the given {unary_f}.
function! s:sort_by(list, unary_f) abort
  "FIXME: Don't branch
  if has('nvim') || v:version >= 800
    " Compares unary_func(a:x) and unary_func(a:y) .
    " Doesn't return if the type of a:x and a:y is mismatched,
    " or the types is unexpected.
    function! s:_compare_with(x, y) abort closure
      let l:Call = s:_get_caller(a:unary_f)
      let x = l:Call(a:unary_f, [a:x])
      let y = l:Call(a:unary_f, [a:y])

      let type_pair = [type(x), type(x)]
      return type_pair ==# [type(10), type(10)] ? s:_basic_comparator(x, y)
      \    : type_pair ==# [type(''), type('')] ? s:_basic_comparator(x, y)
      \    : type_pair ==# [type([]), type([])] ? s:_list_comparator(x, y)
      \    : type_pair ==# [type({}), type({})] ? 1
      \    : type_pair ==# [type(function('function')), type(function('function'))]
      \       ? execute('throw "vital: Data.List: sort_by() cannot compare a function and a function"', 1)
      \       : execute(printf("throw 'vital: Data.List: sort_by() cannot compare %s and %s'", string(x), string(y)), 1)
    endfunction
    return sort(a:list, function('s:_compare_with'))
  else
    "FIXME: This is a workaround of closure, this has not async safety for s:sort_by_compare_with_scope !
    let s:sort_by_compare_with_unary_func = a:unary_f
    function! s:_compare_with(x, y) abort
      let l:Call = s:_get_caller(s:sort_by_compare_with_unary_func)
      let x = l:Call(s:sort_by_compare_with_unary_func, [a:x])
      let y = l:Call(s:sort_by_compare_with_unary_func, [a:y])

      let type_pair = [type(x), type(x)]
      return type_pair ==# [type(10), type(10)] ? s:_basic_comparator(x, y)
      \    : type_pair ==# [type(''), type('')] ? s:_basic_comparator(x, y)
      \    : type_pair ==# [type([]), type([])] ? s:_list_comparator(x, y)
      \    : type_pair ==# [type({}), type({})] ? 1
      \    : type_pair ==# [type(function('function')), type(function('function'))]
      \       ? execute('throw "vital: Data.List: sort_by() cannot compare a function and a function"', 1)
      \       : execute(printf("throw 'vital: Data.List: sort_by() cannot compare %s and %s'", string(x), string(y)), 1)
    endfunction
    return sort(a:list, function('s:_compare_with'))
  endif
endfunction

" The basic comparator for Number and String
function! s:_basic_comparator(x, y) abort
  return a:x ># a:y ? 1
  \    : a:x <# a:y ? -1
  \                 : 0
endfunction

" The comparator of the dictionary order
function! s:_list_comparator(xs, ys) abort
  let [xlen, ylen] = [len(a:xs), len(a:ys)]
  if xlen isnot ylen
    return s:_basic_comparator(xlen, ylen)
  endif

  for z in s:zip(a:xs, a:ys)
    let [x, y] = z
    let order = s:_basic_comparator(x, y)
    if order isnot 0
      return order
    endif
  endfor

  " if a:xs equals a:ys
  return 0
endfunction

" Returns a maximum value in {list} through given {function}.
" Returns 0 if {list} is empty.
" v:val is used in {function} if {function} is string expression
function! s:max_by(list, f) abort
  if empty(a:list)
    return 0
  endif
  let list = s:map(copy(a:list), a:f)
  return a:list[index(list, max(list))]
endfunction

" Returns a minimum value in {list} through given {expr}.
" Returns 0 if {list} is empty.
" v:val is used in {expr}.
" FIXME: -0x80000000 == 0x80000000
function! s:min_by(list, f) abort
  if empty(a:list)
    return 0
  endif
  let list = s:map(copy(a:list), a:f)
  return a:list[index(list, min(list))]
endfunction

" Returns List of character sequence between [a:from, a:to] .
" e.g.: s:char_range('a', 'c') returns ['a', 'b', 'c']
function! s:char_range(from, to) abort
  return map(
  \   range(char2nr(a:from), char2nr(a:to)),
  \   'nr2char(v:val)'
  \)
endfunction

" Returns true if a:list has a:value.
" Returns false otherwise.
function! s:has(list, value) abort
  return index(a:list, a:value) isnot -1
endfunction

" Returns true if a:list[a:index] exists.
" Returns false otherwise.
" NOTE: Returns false when a:index is negative number.
function! s:has_index(list, index) abort
  " Return true when negative index?
  " let index = a:index >= 0 ? a:index : len(a:list) + a:index
  return 0 <= a:index && a:index < len(a:list)
endfunction

" Similar to Haskell's Data.List.span .
function! s:span(f, xs) abort
  let body = s:take_while(a:f, a:xs)
  let tail = a:xs[len(body) :]
  return [body, tail]
endfunction

" Similar to Haskell's Data.List.break .
function! s:break(f, xs) abort
  let l:Call = s:_get_caller(a:f)
  let first = []
  for x in a:xs
    if l:Call(a:f, [x])
      break
    endif
    call add(first, x)
  endfor
  return [first, a:xs[len(first) :]]
endfunction

" Similar to Haskell's Data.List.takeWhile .
function! s:take_while(f, xs) abort
  let l:Call = s:_get_caller(a:f)
  let result = []
  for x in a:xs
    if l:Call(a:f, [x])
      call add(result, x)
    else
      return result
    endif
  endfor
endfunction

" Similar to Haskell's Data.List.dropWhile .
function! s:drop_while(f, xs) abort
  let l:Call = s:_get_caller(a:f)
  let i = -1
  for x in a:xs
    if !l:Call(a:f, [x])
      break
    endif
    let i += 1
  endfor
  return a:xs[i + 1 :]
endfunction

" Similar to Haskell's Data.List.partition .
function! s:partition(f, xs) abort
  return [filter(copy(a:xs), a:f), filter(copy(a:xs), '!(' . a:f . ')')]
endfunction

" Similar to Haskell's Prelude.all .
function! s:all(f, xs) abort
  return empty(filter(s:map(a:xs, a:f), '!v:val'))
endfunction

" Similar to Haskell's Prelude.any .
function! s:any(f, xs) abort
  return !empty(filter(s:map(a:xs, a:f), 'v:val'))
endfunction

" Similar to Haskell's Prelude.and .
function! s:and(xs) abort
  return s:all('v:val', a:xs)
endfunction

" Similar to Haskell's Prelude.or .
function! s:or(xs) abort
  return s:any('v:val', a:xs)
endfunction

function! s:map_accum(expr, xs, init) abort
  let memo = []
  let init = a:init
  for x in a:xs
    let expr = substitute(a:expr, 'v:memo', init, 'g')
    let expr = substitute(expr, 'v:val', x, 'g')
    let [tmp, init] = eval(expr)
    call add(memo, tmp)
  endfor
  return memo
endfunction

" Similar to Haskell's Prelude.foldl .
function! s:foldl(f, init, xs) abort
  "NOTE: The 'Call' should be named with l: for the conflict problem
  let l:Call = type(a:f) is type(function('function'))
  \              ? function('call')
  \              : function('s:_call_two_argument_string_expr')
  let memo = a:init
  for x in a:xs
    let memo = l:Call(a:f, [memo, x])
  endfor
  return memo
endfunction

" Returns the result of that apply the two element list to the binary string expression.
" The binary expression has 'v:memo' and 'v:val'.
function! s:_call_two_argument_string_expr(expr, bi_arg) abort
    let expr = substitute(a:expr, 'v:memo', string(a:bi_arg[0]), 'g')
    let expr = substitute(expr, 'v:val', string(a:bi_arg[1]), 'g')
    return eval(expr)
endfunction

" Similar to Haskell's Prelude.foldl1 .
function! s:foldl1(f, xs) abort
  if len(a:xs) == 0
    throw 'vital: Data.List: foldl1'
  endif
  return s:foldl(a:f, a:xs[0], a:xs[1:])
endfunction

" Similar to Haskell's Prelude.foldr .
function! s:foldr(f, init, xs) abort
  "NOTE: The 'Call' should be named with l: for the conflict problem
  let l:Call = type(a:f) is type(function('function'))
  \              ? function('call')
  \              : function('s:_call_two_argument_string_expr')
  return s:_foldr_internal(l:Call, a:f, a:init, a:xs)
endfunction

" Avoids caller's overhead
function! s:_foldr_internal(call, f, state, xs) abort
  if empty(a:xs)
    return a:state
  endif

  let [y, ys] = s:uncons(a:xs)
  return a:call(a:f, [y, s:_foldr_internal(a:call, a:f, a:state, ys)])
endfunction

" Returns the result of that apply a:memo and a:val to the binary string expression.
" The binary expression has 'v:memo' and 'v:val'.
function! s:_call_expr_memo_val(expr, memo, val) abort
  let expr = substitute(a:expr, 'v:memo', string(a:memo), 'g')
  let expr = substitute(expr, 'v:val', string(a:val), 'g')
  return eval(expr)
endfunction

" Similar to Haskell's Prelude.fold11 .
function! s:foldr1(f, xs) abort
  if len(a:xs) == 0
    throw 'vital: Data.List: foldr1'
  endif
  return s:foldr(a:f, a:xs[-1], a:xs[0:-2])
endfunction

" Similar to python's zip() .
function! s:zip(...) abort
  return map(range(min(map(copy(a:000), 'len(v:val)'))), "map(copy(a:000), 'v:val['.v:val.']')")
endfunction

" Similar to zip(), but goes until the longer one.
function! s:zip_fill(xs, ys, filler) abort
  if empty(a:xs) && empty(a:ys)
    return []
  elseif empty(a:ys)
    return s:cons([a:xs[0], a:filler], s:zip_fill(a:xs[1 :], [], a:filler))
  elseif empty(a:xs)
    return s:cons([a:filler, a:ys[0]], s:zip_fill([], a:ys[1 :], a:filler))
  else
    return s:cons([a:xs[0], a:ys[0]], s:zip_fill(a:xs[1 :], a:ys[1: ], a:filler))
  endif
endfunction

" Inspired by Ruby's with_index method.
function! s:with_index(list, ...) abort
  let base = a:0 > 0 ? a:1 : 0
  return map(copy(a:list), '[v:val, v:key + base]')
endfunction

" Similar to Ruby's detect or Haskell's find.
function! s:find(list, default, f) abort
  let l:Call = s:_get_caller(a:f)
  for x in a:list
    if l:Call(a:f, [x])
      return x
    endif
  endfor
  return a:default
endfunction

" Returns the index of the first element which satisfies the given expr.
function! s:find_index(xs, f, ...) abort
  let len = len(a:xs)
  let start = a:0 > 0 ? (a:1 < 0 ? len + a:1 : a:1) : 0
  let default = a:0 > 1 ? a:2 : -1
  if start >=# len || start < 0
    return default
  endif
  for i in range(start, len - 1)
    if eval(substitute(a:f, 'v:val', string(a:xs[i]), 'g'))
      return i
    endif
  endfor
  return default
endfunction

" Returns the index of the last element which satisfies the given expr.
function! s:find_last_index(xs, f, ...) abort
  let len = len(a:xs)
  let start = a:0 > 0 ? (a:1 < 0 ? len + a:1 : a:1) : len - 1
  let default = a:0 > 1 ? a:2 : -1
  if start >=# len || start < 0
    return default
  endif
  for i in range(start, 0, -1)
    if eval(substitute(a:f, 'v:val', string(a:xs[i]), 'g'))
      return i
    endif
  endfor
  return default
endfunction

" Similar to find_index but returns the list of indices satisfying the given expr.
function! s:find_indices(xs, f, ...) abort
  let len = len(a:xs)
  let start = a:0 > 0 ? (a:1 < 0 ? len + a:1 : a:1) : 0
  let result = []
  if start >=# len || start < 0
    return result
  endif
  for i in range(start, len - 1)
    if eval(substitute(a:f, 'v:val', string(a:xs[i]), 'g'))
      call add(result, i)
    endif
  endfor
  return result
endfunction

" Return non-zero if a:list1 and a:list2 have any common item(s).
" Return zero otherwise.
function! s:has_common_items(list1, list2) abort
  return !empty(filter(copy(a:list1), 'index(a:list2, v:val) isnot -1'))
endfunction

function! s:intersect(list1, list2) abort
  let items = []
  " for funcref
  for X in a:list1
    if index(a:list2, X) != -1 && index(items, X) == -1
      let items += [X]
    endif
  endfor
  return items
endfunction

" Similar to Ruby's group_by.
function! s:group_by(xs, f) abort
  let result = {}
  let list = map(copy(a:xs), printf('[v:val, %s]', a:f))
  for x in list
    let Val = x[0]
    let key = type(x[1]) !=# type('') ? string(x[1]) : x[1]
    if has_key(result, key)
      call add(result[key], Val)
    else
      let result[key] = [Val]
    endif
    unlet Val
  endfor
  return result
endfunction

function! s:binary_search(list, value, ...) abort
  let Predicate = a:0 >= 1 ? a:1 : 's:_basic_comparator'
  let dic = a:0 >= 2 ? a:2 : {}
  let start = 0
  let end = len(a:list) - 1

  while 1
    if start > end
      return -1
    endif

    let middle = (start + end) / 2

    let compared = call(Predicate, [a:value, a:list[middle]], dic)

    if compared < 0
      let end = middle - 1
    elseif compared > 0
      let start = middle + 1
    else
      return middle
    endif
  endwhile
endfunction

function! s:product(lists) abort
  let result = [[]]
  for pool in a:lists
    let tmp = []
    for x in result
      let tmp += map(copy(pool), 'x + [v:val]')
    endfor
    let result = tmp
  endfor
  return result
endfunction

function! s:permutations(list, ...) abort
  if a:0 > 1
    throw 'vital: Data.List: too many arguments'
  endif
  let r = a:0 == 1 ? a:1 : len(a:list)
  if r > len(a:list)
    return []
  elseif r < 0
    throw 'vital: Data.List: {r} must be non-negative integer'
  endif
  let n = len(a:list)
  let result = []
  for indices in s:product(map(range(r), 'range(n)'))
    if len(s:uniq(indices)) == r
      call add(result, map(indices, 'a:list[v:val]'))
    endif
  endfor
  return result
endfunction

function! s:combinations(list, r) abort
  if a:r > len(a:list)
    return []
  elseif a:r < 0
    throw 'vital: Data.List: {r} must be non-negative integer'
  endif
  let n = len(a:list)
  let result = []
  for indices in s:permutations(range(n), a:r)
    if s:sort(copy(indices), 'a:a - a:b') == indices
      call add(result, map(indices, 'a:list[v:val]'))
    endif
  endfor
  return result
endfunction


" Takes the unary function of the funcref or the string expression.
" Returns the caller function that is like call() .
function! s:_get_caller(f) abort
  return type(a:f) is type(function('function'))
  \        ? function('call')
  \        : function('s:_call_string_expr')
endfunction

" Applies the string expression to the head element of a:args.
" Returns the result.
function! s:_call_string_expr(expr, args) abort
  return map([a:args[0]], a:expr)[0]
endfunction

" Composes two function
function! s:_compose(g, f) abort
  return s:Closure.compose([a:g, a:f])
endfunction

" The identity function
function! s:_id(x) abort
  return a:x
endfunction

" The function of the '!' operator
function! s:_not(x) abort
  return !a:x
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
