pro c_ampcor_lsat_arn,id1,id2,nproc,xoff,yoff,rgspac,line_spac,rgstep,line_step,comp=comp

if keyword_set(comp) then adapt = boolean(1) else adapt = boolean(0)
if (~exist(nproc)) then nproc = 14
if (~exist(rgstep)) then rgstep = 32
if (~exist(line_step)) then line_step = rgstep

;print,'Inside c_ampcor_lsat, with adapt:',adapt
;print,'Id1 : ',id1
;print,'Id2 : ',id2

id=id1+'-'+id2

;xoff= long( read_keyword('DIFF_par.'+id1+'.'+id2,'initial_range_offset') )
;yoff= long( read_keyword('DIFF_par.'+id1+'.'+id2,'initial_azimuth_offset') )
;xoff=-160L
;yoff=-500L
if (~exist(xoff)) then xoff = 0L
if (~exist(yoff)) then yoff = 0L
print,'Offset :',xoff,yoff


p1 = load_geo_param(gc_par=id1+'.DEM_gc_par')
p2 = load_geo_param(gc_par=id2+'.DEM_gc_par')

nl=max([p1.nrec,p2.nrec])

y_start=0L+max([0,fix(-yoff/48L+1.5)*48L])
y_end=nl

;Oct correction ER
x_start=1L
x_end=p1.npix
;end correction

x_start=0L & y_start=0L & x_end=p1.npix & y_end=nl

print,'x_start:',x_start,',x_end:',x_end
print,'y_start:',y_start,',y_end:',y_end

nrec=0L+y_end-y_start

bat_id='bat_'+id1+'-'+id2

print,'Number of record of ref. SLC :',nrec
print,'Divide offsets into ',nproc,' chunks ..'

if (~exist(rgspac)) then rgspac = 25
if (~exist(line_spac)) then line_spac = 25

line = (lindgen(nrec)+y_start)[0:*:(nrec/nproc)+1]

numb=strcompress(lindgen(nproc)+1,/r)

y_curr=long(y_start)

print,'Bat file: ',bat_id
openw,2,bat_id

for i=1,nproc do begin
    openw,1,id+'.offmap_'+numb(i-1)+'.in'
    if adapt then begin
        printf,1,id1+"_sobel.slc"
        printf,1,id2+"_sobel.slc"
    endif else begin
        printf,1,id1+'.dat'
        printf,1,id2+'.dat'
    endelse
    printf,1,id+'.offmap'+'_'+numb(i-1)
    printf,2,'./ampcor '+id+'.offmap'+'_'+numb(i-1)+'.in old &'
    printf,1,p1.npix,p2.npix,format='(i5,1x,i5)'
    printf,1,(line[i-1]-line_spac) >0 > y_start ,(i eq nproc)? p1.nrec  : line[i],line_spac,format='(i6,1x,i8,1x,i3)'
    ;printf,1,y_curr-2*line_spac,y_curr+line_spac*(nn),line_spac,format='(i6,1x,i8,1x,i3)'
    print, i, (line[i-1]-line_spac)>0 > y_start ,(i eq nproc)? p1.nrec : line[i],line_spac
    printf,1,x_start,x_end,rgspac,format='(i4,1x,i5,1x,i5)'
    printf,1,'64 64'
    printf,1,string(rgstep) + " " + string(line_step)
    printf,1,'1 1'
    xoff0=xoff & yoff0=long(yoff)
    printf,1,xoff0,yoff0,format='(i4,1x,i6)'
    printf,1,'0. 1.e10'
    printf,1,'f f'
    close,1
    ;print,id+'.offmap_'+numb(i-1)+'.in',y_curr,y_curr+line_spac*(nn-1L)
    ;y_curr=y_curr+long(line_spac*nn)
endfor

; add 'wait' at the end of the file, to allow Ctrl+Z
printf,2,'wait'

close,2

spawn,'chmod 777 '+bat_id

fin:
end
