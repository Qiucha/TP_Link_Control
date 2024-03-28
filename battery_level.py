import re
import os

# get /path/of/script/
FILE_PATH = os.path.dirname(os.path.abspath(__file__))

if __name__ == "__main__":
    # read the state file
    f = open(f'{FILE_PATH}/charge_level', 'r')

    # use re to extract the digits
    x = re.search("\d+\.\d*", f.read())

    # using print to extract to echo in bash file.
    print(float(x.group(0)))
