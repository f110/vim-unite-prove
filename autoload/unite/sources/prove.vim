"required:
    "vimproc

call unite#util#set_default('g:unite_source_prove_command', 'prove')

let s:source = {
            \ 'name': 'prove',
            \ 'hooks': {},
            \ 'variables': {
            \       'command': g:unite_source_prove_command,
            \   },
            \ }

function! s:source.hooks.on_init(args, context)
    if !unite#util#has_vimproc()
        call unite#print_source_error(
            \ 'vimproc is required', s:source.name)
        return
    endif
endfunction

function! s:source.gather_candidates(args, context)
    let vars = unite#get_source_variables(a:context)
    let cmdline = printf('%s t', vars.command)
    let a:context.cmdline = cmdline

    let a:context.source__proc = vimproc#popen2(cmdline)

    return []
endfunction

function! s:source.async_gather_candidates(args, context)
    let stdout = a:context.source__proc.stdout

    if stdout.eof
        let done_message = printf('done: %s', a:context.cmdline)

        call unite#print_source_message(done_message, s:source.name)
        let a:context.is_async = 0
    endif

    let prove_result = filter(stdout.read_lines(-1, 100), "v:val =~ '(Wstat:'")

    let _ = []
    for line in prove_result
        let idx = stridx(line, ' ')
        let file = line[:idx-1]

        call add(_, file)
    endfor

    let path = expand('#:p')
    return map(_, '{
    \   "word": v:val,
    \   "source": "prove",
    \   "kind": "jump_list",
    \   "action__path": v:val,
    \ }')
endfunction

function! unite#sources#prove#define()
    return s:source
endfunction
