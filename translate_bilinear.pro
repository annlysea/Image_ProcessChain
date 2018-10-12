; Translates a surface according to an offset
function translate_bilinear,offmap,offset,sclx=sclx,scly=scly,scale=scale

if (~exist(scale)) then scale = 1

sz = size(offmap)
npix = sz[1]
nrec = sz[2]

x = findgen(npix)#(fltarr(nrec)+1)
x = x + offset.vra / scale

x = x+x*sclx

y = (fltarr(npix)+1)#findgen(nrec)
y = y + offset.vaz / scale

y= y+y*scly
return, bilinear(offmap,x,y)

end
