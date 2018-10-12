; Calculates divergence

function div_arn, vx, vy, nn = nn, rg_sp = rg_sp

if (~exist(vx) or ~exist(vy)) then begin
    print,"Calling sequence:"
    print," result = div_arn (vx, vy[, nn = nn, rg_sp = rg_sp])"
    return, ""
endif

if ~exist(nn) then nn = 1
if ~exist(rg_sp) then rg_sp = 1

dvx = convol(vx, [ -1, intarr(nn), 1], /edge_truncate) / ( (nn+1) * rg_sp)
dvy = convol(vy, transpose([ -1, intarr(nn), 1]), /edge_truncate) / ( (nn+1) * rg_sp)

result = dvx + dvy
return, result

end
