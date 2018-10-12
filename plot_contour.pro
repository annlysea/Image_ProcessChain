; Procedure for plotting the images, with a colorbar as caption

pro plot_contour,datafile, $
    paramfile=paramfile, $
    min_stretch=min_stretch, $
    max_stretch=max_stretch, $
    ct_num=ct_num, $
    symmetric=symmetric, $
    force_symmetric=force_symmetric, $
    force_scale=force_scale, $
    white=white, $
    title=title, $
    xtitle=xtitle, $
    ytitle=ytitle, $
    cbtitle=cbtitle, $
    n_levels=n_levels, $
    min_trunc=min_trunc, $
    max_trunc=max_trunc, $
    save_img=save_img, $
    offset=offset, $
    inverse=inverse, $
    coyote=coyote, $
    geotiff=geotiff, $
    id1=id1, $
    post_north=post_north, $
    post_east=post_east

; Load image
if keyword_set(offset) then begin
    offset = read_offset(datafile) 
    dat = abs(complex(offset.vra, offset.vaz))
endif else begin 
    if (~exist(paramfile)) then begin 
        dat = load_image(datafile)
        paramfile = datafile + ".par"
    endif else dat = load_image(datafile, parfile=paramfile,/binary)
endelse
dat = reverse(dat, 2)

if (exist(min_trunc)) then dat = dat > min_trunc
if (exist(max_trunc)) then dat = dat < max_trunc

; Set dimensions
width = read_keyword(paramfile, 'width')
lines = read_keyword(paramfile, 'nlines')

if width eq "" then width = read_keyword(paramfile, 'offset_estimation_range_samples')
if lines eq "" then lines = read_keyword(paramfile, 'offset_estimation_azimuth_samples')

ratio = float(lines) / float(width)

x = findgen(width)
y = findgen(lines)

position_c = [0.40,0.10,0.95,0.9]
position_cb = [0.13,0.05,0.20,0.9]

dim_x = float(width) / (position_c[2] - position_c[0])
dim_y = float(lines) / (position_c[3] - position_c[1])

; Color parameters
if (~exist(min_stretch)) then min_stretch = 0
if (~exist(max_stretch)) then max_stretch = 255
if (~exist(ct_num)) then ct_num = 15
if (~exist(n_levels)) then n_levels = 8
ct = colortable(ct_num, ncolors=n_levels+1)

if keyword_set(inverse) then ctable = colortable(ct_num, /reverse) else ctable = colortable(ct_num)
;loadct,ct_num
;stretch,min_stretch,max_stretch
;if keyword_set(inverse) then reverse_ct
;tvlct,r,g,b,/get

if keyword_set(white) then val = 255 else val = 0

if keyword_set(symmetric) then begin
    for i=127,128 do begin
        ;r[i] = val
        ;g[i] = val
        ;b[i] = val
        for j=0,2 do ctable[i,j] = val
    endfor
endif

if keyword_set(force_symmetric) then begin
    lim = min([abs(max(dat)), abs(min(dat))])
    dat = dat < lim
    dat = dat > (-lim)
endif
if keyword_set(geotiff) then data2geotiff_arn,datafile,id1,width,lines,post_north,post_east

if keyword_set(force_scale) then begin
    mindat = min_trunc
    maxdat = max_trunc
endif else begin
    mindat = min(dat)
    maxdat = max(dat)
endelse
step = (maxdat - mindat) / n_levels
userLevels = indgen(n_levels) * step + mindat
range = [mindat, maxdat]

; Other parameters
if (~exist(title)) then title = ""
if (~exist(xtitle)) then xtitle = ""
if (~exist(ytitle)) then ytitle = ""
if (~exist(cbtitle)) then cbtitle = ""

; Save img directly in a file instead of displaying it
if (~exist(save_img)) then buffer = boolean(0) else buffer = boolean(1)

if keyword_set(coyote) then begin
    ; This keyword does something weird, stick with the other option

    window,/free,xsize=dim_x,ysize=dim_y,title=title
    
    cgSetColorState,0,CurrentState=state
    contour, dat, x*50, y*50, $
         /fill, c_colors=indgen(n_levels)+3, $
         levels=userLevels, position=position_c, $
         background=cgColor('white'), color=cgColor('black')
    contour, dat, x*50, y*50, /overplot, /follow, color=cgColor('black'), levels=userLevels, background=cgColor('white'), $
        c_colors=indgen(n_levels)
    
    cgColorBar,divisions=6,$
         position=position_cb, range=range,/vertical
    cgSetColorState, state

endif else begin

    if buffer then begin
        w = window(window_title=title, dimensions=[dim_x,dim_y], /buffer)
    endif else begin
        w = window(window_title=title, dimensions=[dim_x,dim_y])
    endelse 

    c = contour(dat, x*50, y*50, $ 
        rgb_table=ctable, $
        title=title,$
        xtitle=xtitle, $
        ytitle=ytitle, $
        position=position_c, $
        fill=ct_num, $
        background_color=[ctable[0,0], ctable[0,1], ctable[0,2]], $
        xrange=[0,(width-1) * 50.], $
        yrange=[0,(lines-1) * 50.], $
        max_value=maxdat, $
        min_value=mindat, $
        axis_style=1, $
        c_value=userLevels, $
        /current)   

;    cgColorBar,title=cbtitle, $
;        position=position_cb, $
;        /vertical, $
;        range=range, $
;        /window, $
;        format='(F0.2)'

    cb = colorbar(title=cbtitle, $
        position=position_cb, $
        orientation=1, $
        range=range, $
        target=c, $
        taper=1)
endelse

if buffer then begin
    w.save, save_img + ".png"
    print,"Image saved as: " + save_img + ".png"
    w.close
endif

fin:
clear_lun
end
