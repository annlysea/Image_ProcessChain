; Get the absolute offset of an offmap

pro get_adjustment,diff,offname,result,limoff=limoff,limstd=limstd,verbose=verbose,diffname=diffname,wherediff=wherediff

; diff: 2-dimensional array of the diff
; offname: file name to load the offmap
; adj: variable containing the result
; limoff: absolute limit, to use with the where function
; limstd: limit of the standard deviation to stop the while loop (the higher the shorter)
; verbose: print several variables and displays variables in different windows
; diffname: file name to load the diff
; wherediff (kw): conditions on the diff variable, instead of the offmap variable

if ~exist(limoff) then limoff = 100
if limoff le 0 then begin
    print,"Argument 'limoff' must be greater than zero."
    return
endif
if ~exist(limstd) then limstd = 1
if ~exist(verbose) then verbose = 0

limdiff = 3

if exist(diffname) then diff = load_image(diffname)
diffcp = diff
median_filter,diff,/nan
;median_filter,diffcp,/nan
if keyword_set(verbose) then begin
    winarn,diff,title="diff before",ct=15
    winarn,diffcp,title="diffcp before",ct=15
    print,"Percentiles before: diff:",cgPercentiles(diff[where(finite(diff))])
    print,"Percentiles before: diffcp:",cgPercentiles(diffcp[where(finite(diffcp))])
endif
w = where(abs(diff) ge limdiff)
diffcp[w] = !values.f_nan
diff[w] = !values.f_nan

if keyword_set(verbose) then print,"Beginning: mean:",mean(diffcp), " percentiles:",cgPercentiles(diffcp), " min:",min(diffcp)," max:",max(diffcp)

offmap = read_offset(offname)
aoffmap = abs(complex(offmap.vra, offmap.vaz))
w = where((aoffmap ge limoff) or (aoffmap eq 0))

aoffmap[w] = !values.f_nan
diffcp[w] = !values.f_nan
diff[w] = !values.f_nan

std = limstd
i = 1
while (std ge limstd) do begin
    if keyword_set(wherediff) then begin
        up = mean(diffcp, /nan) + stddev(diffcp, /nan)
        down = mean(diffcp, /nan) - stddev(diffcp, /nan)
    endif else begin
        up = mean(aoffmap, /nan) + stddev(aoffmap, /nan)
        down = mean(aoffmap, /nan) - stddev(aoffmap, /nan)
    endelse
    if keyword_set(verbose) then print,"For i=" + string(i, format="(I0)") + " Mean:",mean(aoffmap, /nan), " Stddev:",stddev(aoffmap, /nan)," Min:",min(aoffmap)," Down:",down," Max:",max(aoffmap), " Up:",up
    if keyword_set(wherediff) then w = where((diffcp lt down) or (diffcp gt up)) else w = where((aoffmap lt down) or (aoffmap gt up))
    aoffmap[w] = !values.f_nan
    diffcp[w] = !values.f_nan
    ;diff[w] = !values.f_nan
    if keyword_set(wherediff) then std = stddev(diffcp, /nan) else std = stddev(aoffmap, /nan)

    if keyword_set(verbose) then begin
         print,"STDDEV for diffcp is:",stddev(diffcp, /nan), " MEAN for diffcp is:",mean(diffcp, /nan)
         winarn,aoffmap,title="aoffmap " + string(i, format="(I0)"),ct=15
         winarn,diffcp,title="diffcp " + string(i, format="(I0)"),ct=15
         winarn,diff,title="diff " + string(i, format="(I0)"),ct=15
    endif

    if (i gt 50) then break
    i += 1
endwhile

if keyword_set(verbose) then print,"For end Mean:",mean(aoffmap, /nan), " Stddev:",stddev(aoffmap, /nan)," Min:",min(aoffmap)," Down:",down," Max:",max(aoffmap), " Up:",up


if keyword_set(verbose) then print,"Percentiles aoffmap:",string(cgPercentiles(aoffmap[where(finite(aoffmap))]))

ww = where((aoffmap lt down) and (aoffmap gt up)) ; TODO: c'est l'inverse non?
;if keyword_set(verbose) then winarn,aoffmap,title="aoffmap at the end",ct=15

diff[ww] = !values.f_nan

result = mean(diff, /nan)

if keyword_set(verbose) then begin
    print,"Percentiles diff:",cgPercentiles(diff[where(finite(diff))])
    print,"Percentiles diffcp:",cgPercentiles(diffcp[where(finite(diffcp))])
    print,"stddev(diff):",stddev(diff, /nan)
    print,"stddev(diffcp):",stddev(diffcp, /nan)
    print,"mean(diff):",mean(diff, /nan)
    print,"mean(diffcp):",mean(diffcp, /nan)
endif

end
