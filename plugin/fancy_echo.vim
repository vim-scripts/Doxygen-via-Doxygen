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


if ! exists("g:fancy_echo_loaded")
    let g:fancy_echo_loaded = 1

    function! FancyEcho( text )
        let l:i = 0
        while l:i < len( a:text )
            if a:text[ l:i ] == "@"
                let l:i = l:i + 1
                if a:text[ l:i ] == "0"
                    echohl None
                elseif a:text[ l:i ] == "1"
                    echohl Directory
                elseif a:text[ l:i ] == "2"
                    echohl WarningMsg
                elseif a:text[ l:i ] == "@"
                    echon "@"
                endif
            else
                echon a:text[ l:i ]
            endif
            let l:i = l:i + 1
        endwhile
        echohl None
    endfunction

    function! BlinkColumn( times )
        let l:cc = &cursorcolumn
        for l:i in range( 1, a:times )
            set invcursorcolumn
            redraw
            sleep 100m
            set invcursorcolumn
            redraw
            sleep 100m
        endfor
        let &cursorcolumn = l:cc
    endfunction

    function! BlinkColumnAndLine( times )
        let l:cl = &cursorline
        let l:cc = &cursorcolumn
        for l:i in range( 1, a:times )
            set invcursorcolumn
            set invcursorline
            redraw
            sleep 100m
            set invcursorcolumn
            set invcursorline
            redraw
            sleep 100m
        endfor
        let &cursorline = l:cl
        let &cursorcolumn = l:cc
    endfunction
endif
