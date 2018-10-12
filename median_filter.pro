; Tries to suppress noise

pro median_filter,img,sz,lim,offset=offset,verbose=verbose,nan=nan

if (~exist(sz)) then sz = 9
if (~exist(lim)) then lim = 2

if keyword_set(verbose) then begin
    print,"sz:",sz
    print,"lim:",lim
    help,img
endif

if keyword_set(offset) then begin
    img2vra = median(img.vra, sz)
    img2vaz = median(img.vaz, sz)
    
    w = where(abs(img.vra - img2vra) ge lim) or where(abs(img.vaz - img2vaz) ge lim)
    
    if keyword_set(nan) then begin
        img.vaz[w] = !values.f_nan
        img.vra[w] = !values.f_nan
    endif else begin
        img.vaz[w] = 0
        img.vra[w] = 0
    endelse
    
endif else begin
    img2 = median(img, sz)

    w = where(abs(img - img2) ge lim)

    if keyword_set(nan) then img[w] = !values.f_nan else img[w] = 0
endelse

end
