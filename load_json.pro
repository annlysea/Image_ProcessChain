; Test for json file

function load_json,json_file

json_content = strarr(file_lines(json_file))
openr,lun,json_file,/get_lun
readf,lun,json_content
free_lun,lun
clear_lun

res = json_parse(strjoin(json_content))

return,res

end
