" Copyright (c) 2008 Niels Aan de Brugh
" 
" Permission is hereby granted, free of charge, to any person
" obtaining a copy of this software and associated documentation
" files (the "Software"), to deal in the Software without
" restriction, including without limitation the rights to use,
" copy, modify, merge, publish, distribute, sublicense, and/or sell
" copies of the Software, and to permit persons to whom the
" Software is furnished to do so, subject to the following
" conditions:
" 
" The above copyright notice and this permission notice shall be
" included in all copies or substantial portions of the Software.
" 
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
" EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
" OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
" NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
" HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
" WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
" FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
" OTHER DEALINGS IN THE SOFTWARE.


" ------------------------------------------------------------------
" ------- Configuration Variables ----------------------------------
" ------------------------------------------------------------------

let g:doxy_tag_begin   = escape( '/**', '/*' )
let g:doxy_tag_end     = escape( '*/',  '/*' )
let g:doxy_tmp_dir     = expand( "$HOME/tmp" )
let g:doxy_to_tag_xslt = expand( "$HOME/.vim/plugins/make_doxygen.xslt" )
let g:doxy_old_tag_reg = "_"
let g:doxy_placeholder = "<++>"

" ------------------------------------------------------------------
" ------- Configuration Functions ----------------------------------
" ------------------------------------------------------------------

function! RunXSLTProc( line_nr, xml_file, tag_file )
    call system( "xsltproc --param line_nr " . a:line_nr . " " . expand( g:doxy_to_tag_xslt ) . " " . a:xml_file . "> " . a:tag_file )
endfunction

function! IsEmptyFile( file_name )
    return system( "wc -l " . a:file_name . " | cut -f1 -d\\ ") == 0
endfunction

" ------------------------------------------------------------------
" ------- Implementation -------------------------------------------
" ------------------------------------------------------------------
if ! exists( "g:make_doxygen_tag_loaded" )
    let g:make_doxygen_tag_loaded = 1

function! ToNextPlaceHolder()
    if search( g:doxy_placeholder, "c" ) != 0
        exe "normal c" . strlen( g:doxy_placeholder ) . "l\ "
    endif
endfunction

function! RunDoxygen()
    let l:tempname = tempname()
    exe "redir > " . l:tempname
    silent echo "INPUT = " . expand( "%:p" )
    silent echo "GENERATE_HTML = NO"
    silent echo "GENERATE_LATEX = NO"
    silent echo "GENERATE_XML = YES"
    silent echo "EXTRACT_ALL = YES"
    silent echo "XML_PROGRAMLISTING = NO"
    silent echo "OUTPUT_DIRECTORY = " . g:doxy_tmp_dir
    silent echo "\n"
    redir END
    call system( "doxygen " . l:tempname . " > /dev/null 2>&1" )
    call delete( l:tempname )
endfunction

function! MakeTag()
    let l:begin_pos = getpos(".")

    call RunDoxygen()

    if VisualizeTag() " side-effect: move to top of definition
        normal V
    endif
    if search( "{" , "", "" ) == 0
        call FancyEcho( "Open bracket @1{ @2not found." )
        return 0
    endif

    let l:tag_file = tempname()
    let l:xml_file = g:doxy_tmp_dir . "/xml/" . substitute( expand("%:t"), "\\.", "_8", "g" ) . ".xml"
    call RunXSLTProc( line("."), l:xml_file, l:tag_file )
    if IsEmptyFile( l:tag_file )
        call FancyEcho( "Resulting tag is @2empty@0. Did you forget to @1safe@0 the file first?" )
        call setpos( ".", l:begin_pos )
    else
        if VisualizeTag()
            exe "normal \"" . g:doxy_old_tag_reg . "dk"
        elseif match(getline("."), "^\s*$") == -1
            call search( "^\s*$", "bW" )
            if match( getline("."), "^\s*$" ) == -1
                normal "O<Esc>"
            endif
        endif
        exe "read " . l:tag_file
    endif
    call delete( l:tag_file )
endfunction

function! VisualizeTag()
    let l:begin_pos = getpos( "." )
    let l:above_definition = search( "}", "bnW" )
    if l:above_definition == 0
        let l:above_definition = search( "{", "bnW" )
    endif
    let l:begin_tag = search( g:doxy_tag_begin, "bWc", l:above_definition )
    if l:begin_tag != 0
        let l:end_tag = search( g:doxy_tag_end, "W" )
    endif
    if l:begin_tag == 0 || l:end_tag == 0
        call setpos( ".", l:begin_pos )
        return 0
    else
        call cursor( l:begin_tag, 1 )
        normal V
        call cursor( l:end_tag, 1 )
        return 1
    endif
endfunction

endif
