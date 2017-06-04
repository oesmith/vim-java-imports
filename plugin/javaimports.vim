" javaimports.vim -- Manage java imports and packages
" Author: Johan Venant <jvenant@invicem.pro>
" Last Modified: 13-Jun-2016 15:36
" Requires: Vim-6.0 or higher
" Version: 1.0
" Licence: This program is free software; you can redistribute it and/or
"          modify it under the terms of the GNU General Public License.
"          See http://www.gnu.org/copyleft/gpl.txt
" Download From:
"     https://github.com/jvenant/javaimports
" Summary Of Features:
"   Insert import
"   Sort imports
"   Insert package declaration
" Usage:
"   Copy this file in your vim plugin folder
"   No classpath or configuration needed. This plugin use the regular vim search.
"   So you only need a good search index (through ctags or cscope for example)
" Commands:
"   <Leader>is Sort imports
"   <Leader>ia Search class from <cword>, add it to the imports and sort imports
"   <Leader>ip add or replace package declaration
"   You can define the package sort order using g:sortedPackage
"   You can define the package deth blank line separator using g:packageSepDepth
" Notes:
"   This plugin is an improvement of the anonymous function found here :
"   http://vim.wikia.com/wiki/Add_Java_import_statements_automatically
if exists("g:loaded_sortimport") || &cp
    finish
endif
let g:loaded_sortimport= 1

if !hasmapto('<Plug>JavaSortImport')
    map <unique> <Leader>is <Plug>JavaSortImport
endif
if !hasmapto('<Plug>JavaInsertImport')
    map <unique> <Leader>ia <Plug>JavaInsertImport
endif
if !hasmapto('<Plug>JavaInsertPackage')
    map <unique> <Leader>ip <Plug>JavaInsertPackage
endif

map <silent> <script> <Plug>JavaSortImport :set lz<CR>:call <SID>JavaSortImport()<CR>:set nolz<CR>
map <silent> <script> <Plug>JavaInsertImport :call <SID>JavaInsertSortImport()<CR>
map <silent> <script> <Plug>JavaInsertPackage :set lz<CR>:call <SID>JavaInsertPackage()<CR>:set nolz<CR>

let s:allImportsPattern = '^\s*import\s'
let s:importPattern = '^\s*import\s\+\w\+\(\.\w\+\)*\s*;.*$'
let s:importStaticPattern = '^\s*import\s\+static\s\+\w\+\(\.\w\+\)*\s*;.*$'

if !exists('g:javaStaticImportsFirst')
  let g:javaStaticImportsFirst = 1
endif

fun! s:JavaSortImport()
  " Collect imports at the top of the file.
  1
  let l:cur = search(s:allImportsPattern)
  if cur == 0
    " Give up if there are no imports to sort.
    return
  endif
  while search(s:allImportsPattern, 'W') > 0
    normal! dd
    exe l:cur
    normal! p
    let l:cur = line(".")
  endwhile

  " Separate normal imports from statics.
  if g:javaStaticImportsFirst == 1
    let l:pattern = s:importStaticPattern
  else
    let l:pattern = s:importPattern
  endif
  1
  let l:cur = search(s:allImportsPattern)
  if l:cur > 0
    let l:orig = l:cur
    while search(l:pattern, 'W') > 0
      normal! dd
      exe l:cur
      normal! Pj
      let l:cur = line(".")
    endwhile
    if l:cur > l:orig
      normal! o
    endif
  endif

  " Sort groups
  1
  if search(s:importPattern) > 0
    exe line('.') . ',' . search(s:importPattern, 'bw') . 'sort /[^;]\+/ ur'
  endif
  if search(s:importStaticPattern) > 0
    exe line('.') . ',' . search(s:importStaticPattern, 'bw') . 'sort /[^;]\+/ ur'
  endif

  " Remove any additional whitespace beneath imports.
  1
  if search(s:allImportsPattern, 'bw') > 0
    normal! j
    let l:cur = line(".")
    while getline(cur + 1) =~ '^\s*$'
      normal! dd
    endwhile
  endif
endfun

fun! s:JavaInsertSortImport()
    call s:JavaInsertImport()
    split
    call s:JavaSortImport()
    quit
endfun

fun! s:JavaInsertImport()
    exe "normal mz"
    let cur_class = expand("<cword>")
    let semicolon = s:GetSemicolon()
    try
        if search('^\s*import\s.*\.' . cur_class . '\s*;\?$') > 0
            throw getline('.') . ": import already exist!"
        endif
        wincmd }
        wincmd P
        1
        if search('^\%(\s*public.*\s\|open\s\|abstract\s\|enum\s\)\?\%(class\|interface\|object\)\s\+' . cur_class) > 0
            1
            if search('^\s*package\s') > 0
                yank y
            else
                throw "Package definition not found!"
            endif
        else
            if search('^\s*import\s.*\.' . cur_class . '\s*;\?$') > 0
                yank y
            else
                throw cur_class . ": class not found!"
            endif
        endif
        wincmd p
        normal! G
        " insert after last import or in first line
        if search('^\s*import\s', 'b') > 0
            put y
        else
            if search('^\s*package\s', 'b') > 0
                exe "normal o"
                put y
            else
                1
                put! y
            endif
        endif
        if match(getline("."), '^\s*package\s\+.*') >= 0
            substitute/^\s*package/import/g
            substitute/;\?$//g
            substitute/\s\+/ /ig
            exe "normal! 2Ea \<Esc>R." . cur_class . s:GetSemicolon() . "\<Esc>lD"
        endif
    catch /.*/
        echoerr v:exception
    finally
        " wipe preview window (from buffer list)
        silent! wincmd P
        if &previewwindow
            bwipeout
        endif
        exe "normal! `z"
    endtry
endfun

fun! s:JavaInsertPackage()
    let dir = getcwd() . "/" . expand("%")
    let dir = substitute(dir, '^.*\/\%(java\|javatests\|src\|tst\)\/', '', '')
    let dir = substitute(dir, '\/[^\/]*$', '', '')
    let dir = substitute(dir, '\/', '.', 'g')
    1
    if search('^\s*package\s.*', '') == 0
        normal! O
    endif
    exe "normal ^Cpackage " . dir . s:GetSemicolon()
endfun

fun! s:GetSemicolon()
    return &filetype == "kotlin" ? "" : ";"
endfun
