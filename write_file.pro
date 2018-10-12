; Writes a variable in a file

pro write_file,variable,filename,verbose=verbose,content=content

; default parameter file: filename + ".par"
; get width and nlines

openw,lun,filename,/get_lun,/swap_endian
writeu,lun,variable
;printf,lun,variable
free_lun,lun
if keyword_set(verbose) then begin
    print,"File written: " + filename
    if keyword_set(content) then print,variable
endif

sz = size(variable)

if sz[0] eq 2 then begin
    openw,lun,filename + ".par",/get_lun
    printf,lun,"width: " + string(sz[1])
    printf,lun,"nlines: " + string(sz[2])
    free_lun,lun
    if keyword_set(verbose) then print,"Parameters written: " + filename + ".par"
endif

end
