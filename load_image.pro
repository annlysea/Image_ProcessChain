; Returns an array representing the image
function load_image,filename,parfile=parfile,width=width,nlines=nlines,binary=binary,verbose=verbose

; default parameter file: filename + ".par"

if (exist(parfile)) then begin
    width = read_keyword(parfile,'width')
    nlines = read_keyword(parfile,'nlines')
    
    if width eq "" then width = read_keyword(parfile,'offset_estimation_range_samples')
    if nlines eq "" then nlines = read_keyword(parfile,'offset_estimation_azimuth_samples')
    
    if width eq "" then width = read_keyword(parfile,'range_samples')
    if nlines eq "" then nlines = read_keyword(parfile,'azimuth_lines')
endif else if (~exist(width) and ~exist(nlines) and file_test(filename + ".par")) then begin
    ; Then we try to load the filename.par file, if it exists
    width = read_keyword(filename + ".par", 'width')
    nlines = read_keyword(filename + ".par", 'nlines')
endif

if (~exist(width) or ~exist(nlines)) then begin
    print,"Please enter a parameter file, or directly enter width and nlines, for file: " + filename
    return,""
endif

if keyword_set(verbose) then begin
    print,"width:",width
    print,"lines:",nlines
endif

img = fltarr(width, nlines)

if keyword_set(binary) then begin
    openr,lun,filename,/swap_if_little_endian,/get_lun
    readu,lun,img
    close,lun
endif else begin 
    openr,lun,filename,/get_lun
    readf,lun,img
    close,lun
endelse

return,img

end
