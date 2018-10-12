; Use winjer, but directly with an array

pro winarn,arr,ct=ct,title=title,readpix=readpix

if ~exist(arr) then begin
    print,"This procedure should be called with a 2-dimensional array"
    return
endif

if ~exist(ct) then ct = 70
if ~exist(title) then title = "WINARN"

dim = size(arr)

if dim[0] ne 2 then begin
    print,"Argument should be a 2-dimensional array"
    return
endif

width = dim[1]
length = dim[2]

winjer,width,length,title=title
loadct,ct
tvscl,arr
if keyword_set(readpix) then rdpix,arr

end
