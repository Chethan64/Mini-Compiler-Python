import re
import csv
import copy

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    BLUE = '\033[34m'
    OKCYAN = '\033[96m'
    GREEN = '\033[1;32m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    RED = '\033[1;31m'   

quads = list()
with open("./optimization/quads.csv","r") as csvFile:
    quads = list(csv.DictReader(csvFile))

leaderSet = set()

def findLeaders(quads, leaderSet):
    leaderSet.add(0)
    for i in range(len(quads)):
        if(quads[i]['OP'] == "If False" or quads[i]['OP'] == "goto"):
            leaderSet.add(i+1)
        elif(quads[i]['OP'] == "Label"):
            leaderSet.add(i)

    leaderSet.add(len(quads))
   
def constantPropagation(basicBlock):
    value = dict()

    for quad in basicBlock:
        if quad['OP'] == '=' and quad['ARG2'] == '-':
            value[quad['RES']] = quad['ARG1']

        if quad['ARG1'] in value.keys():
            quad['ARG1'] = value[quad['ARG1']]
        if quad['ARG2'] in value.keys():
            quad['ARG2'] = value[quad['ARG2']]
               
def constantFolding(basicBlock):
    for i in basicBlock:
        if(i["ARG1"].isdigit() and i["ARG2"].isdigit()):
            op = i["OP"]
            if(op in ["and","or"]):
                expr = i["ARG1"] + " " + op + " " + i["ARG2"]
                i["OP"] = "="
                i["ARG1"] = str(eval(expr))
                if(int(i["ARG1"])):
                    i["ARG1"] = "True"
                else:
                    i["ARG1"] = "False"
                i["ARG2"] = "-" 
            else:
                expr = i["ARG1"] + op + i["ARG2"]
                i["OP"] = "="
                i["ARG1"] = str(eval(expr))
                i["ARG2"] = "-" 

def is_temp(temp):
    if(temp[0] == 'T' and temp[1::].isdigit()):
        return True
    return False

def tempRemoval(basicBlocks):
    lhs_temp = dict()
    bNum = 0
    qLine = 0
    for block in basicBlocks:
        qLine = 0
        for quad in block:
            if(quad['OP'] == '=' and quad['ARG2'] == '-' and is_temp(quad['RES'])):
                lhs_temp[quad['RES']] = [bNum, quad]
            
            if quad['ARG1'] in lhs_temp:
                lhs_temp.pop(quad['ARG1'])

            if quad['ARG2'] in lhs_temp:
                lhs_temp.pop(quad['ARG2'])

            qLine = qLine + 1
        
        bNum = bNum + 1
    
    for temp in lhs_temp:
        bNum = lhs_temp[temp][0]
        q = lhs_temp[temp][1]
        basicBlocks[bNum].remove(q)

def constantSubexpression(basicBlock):
    subexp = dict()
    used = set()
    for i in basicBlock:
        exp1 = (i["OP"],i["ARG1"],i["ARG2"])
        exp2 = (i["OP"],i["ARG2"],i["ARG1"])
        
        
        if(i["OP"] in ['+','*','==','&&','||']):
            if(exp1 not in subexp):
                subexp[exp1] = i["RES"]
            if(exp2 not in subexp):
                subexp[exp2] = i["RES"]

        elif(i["OP"] in ['-','/','>','<','>=','<=',]):
            if(exp1 not in subexp):
                subexp[exp1] = i["RES"]

        elif(i["OP"] == '='):
            used.add(i["RES"])
    
    subexp_unused = dict()
    for i in subexp:
        if(i[1] not in used and i[2] not in used):
            subexp_unused[i] = subexp[i]

    subexp = subexp_unused
    for i in basicBlock:
        exp = (i["OP"],i["ARG1"],i["ARG2"])
        if(exp in subexp and i["RES"] != subexp[exp]):

            i["OP"] = '='
            i["ARG1"] = subexp[exp]
            i["ARG2"] = ""

def printBasicBlock(basicBlock):
    print(f"{bcolors.BLUE}OP\tARG1\tARG2\tRES{bcolors.ENDC}")
    for quad in basicBlock:
        print(quad["OP"]+"\t"+quad["ARG1"]+"\t"+quad["ARG2"]+"\t"+quad["RES"])
    print()

findLeaders(quads, leaderSet)
leaderSet = sorted(leaderSet)

basicBlocks = list()

for i in range(len(leaderSet)-1):
    basicBlocks.append(quads[leaderSet[i]:leaderSet[i+1]])

print(f"{bcolors.GREEN}Total Number Of Basic Blocks: ",len(basicBlocks))
print()
for i in basicBlocks:
    print(f"{bcolors.GREEN}BASIC BLOCK:")
    printBasicBlock(i)
    
    old_i = copy.deepcopy(i)
    constantFolding(i)
    constantPropagation(i)
    while(old_i != i):
        old_i = copy.deepcopy(i)
        constantFolding(i)
        constantPropagation(i)

    print(f"{bcolors.RED}After Constant Folding, Copy and Constant Propogation{bcolors.ENDC}")
    printBasicBlock(i)
    constantSubexpression(i)
    print(f"{bcolors.RED}After Common Subexpression Elimination{bcolors.ENDC}")
    printBasicBlock(i)
    print(f"{bcolors.RED}Removing Unused Temporaries{bcolors.ENDC}")
    tempRemoval(basicBlocks)
    printBasicBlock(i)
    print(f"{bcolors.RED}End of Basic Block{bcolors.ENDC}")
    print()
    print()