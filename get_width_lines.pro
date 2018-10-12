; Procedure to fill width and lines as variables, from files already existing

pro get_width_lines,id1,id2,width,lines

width = read_keyword(id1 + "-" + id2 + ".offmap.par", "offset_estimation_range_samples")
if width eq "" then width = read_keyword(id1 + "-" + id2 + ".offmap_apriori.par", "offset_estimation_range_samples")
lines = read_keyword(id1 + "-" + id2 + ".offmap.par", "offset_estimation_azimuth_samples")
if lines eq "" then lines = read_keyword(id1 + "-" + id2 + ".offmap_apriori.par", "offset_estimation_azimuth_samples")

width = long(width)
lines = long(lines)

end
