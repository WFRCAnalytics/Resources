# Removes misc characters from string
def replace(string):
    string = string.replace("&", "")
    string = string.replace("-", " ")
    string = string.replace("(", "")
    string = string.replace(")", "")
    string = string.replace("/", " ")
    string = string.replace(",", "")
    string = string.replace(".", "")
    string = string.replace(" ", "_")
    string = string.replace("'", "")
    return string
