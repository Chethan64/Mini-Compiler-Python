import re
import csv
import copy
import generateTAC

ICG = []
with open("ICG.txt") as csvFile:
    reader = csv.DictReader(csvFile)
    ICG = list(reader)

def findLeaders(ICG,leaderSet):
    leaderSet.add(0)
    
    for i in range(len(ICG)):
        if(ICG[i]['OP'] == 'if' or ICG[i]['OP'] == 'goto'):
            leaderSet.add(i+1)
        if(ICG[i]['OP'] == 'label'):
            leaderSet.add(i)

leaderSet = set()
findLeaders(ICG,leaderSet)
leaderSet.add(len(ICG))
leaderSet = sorted(leaderSet)
BBs = []

for i in range(len(leaderSet) - 1):
    BBs.append(ICG[leaderSet[i]:leaderSet[i+1]])

def is_number(num):
    return bool(re.match(r'^-?\d+(\.\d+)?$', num))

def constant_folding(BB):
    for i in BB:
        if(is_number(i["ARG1"]) and is_number(i["ARG2"])):
            op = i["OP"]
            if(i["OP"] == "&&"):
                op = "and"
            elif(i["OP"] == "||"):
                op = "or"

            if(op in ["and","or"]):
                expr = i["ARG1"] + " " + op + " " + i["ARG2"]
                i["OP"] = "="
                i["ARG1"] = str(eval(expr))
                if(int(i["ARG1"])):
                    i["ARG1"] = "True"
                else:
                    i["ARG1"] = "False"
                i["ARG2"] = "" 
            else:
                expr = i["ARG1"] + op + i["ARG2"]
                i["OP"] = "="
                i["ARG1"] = str(eval(expr))
                i["ARG2"] = "" 

def constant_copy_propagation(BB):
    prop = dict()
    for i in BB:
        if(i["OP"] == '=' and i["ARG2"] == ""):
            prop[i["RES"]] = i["ARG1"]

        if(i["ARG1"] in prop):
            i["ARG1"] = prop[i["ARG1"]]

        if(i["ARG2"] in prop):
            i["ARG2"] = prop[i["ARG2"]]

def constant_subexpression(BB):
    subexp = dict()
    used = set()
    for i in BB:
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

    for i in BB:
        exp = (i["OP"],i["ARG1"],i["ARG2"])
        if(exp in subexp and i["RES"] != subexp[exp]):
            i["OP"] = '='
            i["ARG1"] = subexp[exp]
            i["ARG2"] = ""
    
def dead_if(ICG):
    alive_label = set()
    dead_label = set()
    for i in range(len(ICG)-1):

        if(ICG[i]["OP"] == "if"):

            if(ICG[i]["ARG1"] == "True"):
                alive_label.add(ICG[i]["RES"])
                dead_label.add(ICG[i+1]["RES"])
                
            if(ICG[i]["ARG1"] == "False"):
                alive_label.add(ICG[i+1]["RES"])
                dead_label.add(ICG[i]["RES"])

    new_ICG = []
    print(alive_label)
    print(dead_label)
    is_alive = True
    for i in ICG:
        if(i["OP"] == "if" and i["ARG1"] in ['True','False']):
            if(i["RES"] in dead_label):
                is_alive = False
            else:
                is_alive = True
            continue

        elif(i["OP"] == "goto"):
            if(i["RES"] in dead_label):
                is_alive = False
            else:
                is_alive = True

        elif(i["OP"] == "label"):
            if(i["RES"] in dead_label):
                is_alive = False
            else:
                is_alive = True
        
        if(is_alive):
            new_ICG.append(i)
        
    return new_ICG

def print_tac(ICG):
    for i in ICG:
        if(i["OP"] in ['+','-','*','/','>','<','>=','<=','==','&&','||']):
            print(i["RES"],'=',i["ARG1"],i["OP"],i["ARG2"],sep = " ")
        
        elif(i["OP"] == '='):
            print(i["RES"],'=',i["ARG1"],sep = " ")

        elif(i["OP"] == 'if'):
            print(i["OP"],i["ARG1"],"goto",i["RES"],sep = " ")

        elif(i["OP"] == 'goto'):
            print("goto",i["RES"],sep=" ")

        elif(i["OP"] == 'label'):
            print(i

for i in BBs:
    old_i = copy.deepcopy(i)
    constant_folding(i)
    constant_copy_propagation(i)
    while(old_i != i):
        old_i = copy.deepcopy(i)
        constant_folding(i)
        constant_copy_propagation(i)
    constant_subexpression(i)

ICG = [i for BB in BBs for i in BB]
generateTAC.print_tac(ICG)
print("\n_________\n")
ICG = dead_if(ICG)
generateTAC.print_tac(ICG)