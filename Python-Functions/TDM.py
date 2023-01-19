def tdmHelloWorld():
    print('Hello TDM World')

# function to return control center value base on variable name
def getControlCenterValue(ccFile,ccVariable):
    
    import re   
    
    # Using readlines()
    file1 = open(ccFile, 'r')
    Lines = file1.readlines()
    
    count = 0
    # Strips the newline character
    for line in Lines:
        count += 1
        _line = "{}".format(line.strip()).replace("'","")
        _line_removecomment = re.sub(r';.*',"",_line)
        _splitline = _line_removecomment.split('=')
        _splitline = [j.strip() for j in _splitline]
        #_splitlinenew = list(filter(lambda x: x[0].lower() != x[0].upper(), _splitline))
        if len(_splitline)>1:
            if _splitline[0]==ccVariable:
                #print(_splitline[1])
                return _splitline[1]
    return ""