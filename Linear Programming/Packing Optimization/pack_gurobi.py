import sys
import csv
from pulp import *
from copy import deepcopy
import gurobipy

# Reading the Cost File
inputFile = open(str('cost_data.csv'), 'r')
data = csv.reader(inputFile)

# List of boxes and FSN
box = next(data)
box = box[1:]
FSN = []
cost = {}
for row in data:
	FSN.append(row[0])
	# Creation of Cost Matrix
	cost[row[0]] = {}
	for b in box:
		cost[row[0]][b] = row[box.index(b) + 1]

		
# Optimization
# ----------------------------------------------------------------------------------------------------------------------
prob = LpProblem('PackOptimization', LpMinimize)
# Decision Variable
X = LpVariable.dicts("X",[(i,j) for i in FSN for j in box], 0, 1, LpBinary)
w = LpVariable.dicts("w",[j for j in box], 0, 1, LpBinary)

# Objective Function
prob += lpSum(float(cost[i][j]) * X[i,j] for i in FSN for j in box) + lpSum(w[j] for j in box)

# Constraints

# One FSN should be allocated to one Box
for i in FSN:
	prob += lpSum(X[i,j] for j in box) == 1

# Total Number of allocated box should be less than 30
for j in box:
	for i in FSN:
		prob += w[j] >= X[i,j]

prob += lpSum(w[i] for i in box) <= int(sys.argv[1])

# Constraint to keep fixed number of existing packing boxes in solution

inputFile = open(str('existing_box_constraint.csv'), 'r')
data = csv.reader(inputFile)
existing_box_constraint = []
for row in data:
	existing_box_constraint = row
	prob += lpSum(w[i] for i in existing_box_constraint) == int(sys.argv[2])


# Reading the constraints File
# Difference between length and width of successive boxes should be at least one inch

inputFile = open(str('packing_dim_constraints.csv'), 'r')
data = csv.reader(inputFile)
constraints = []
for row in data:
	constraints = row
	prob += lpSum(w[i] for i in constraints) <= 1
	
	
# Solution
try:
	status = prob.solve(solver = GUROBI_CMD())
	print("Status:", LpStatus[status])
except Exception as e:
	print(e)
	prob.remove(model.getVars())
	prob.remove(model.getConstrs())
	del prob
	prob.disposeDefaultEnv()
	
# Post Processing
box.insert(0,'')
result = [box]
for i in FSN:
	result.append([i])
	for j in box[1:]:
		result[FSN.index(i) + 1].append(X[i,j].value())

csv.register_dialect('customDialect', delimiter=',', quotechar='"', doublequote=True, skipinitialspace=True,
							 lineterminator='\n', quoting=csv.QUOTE_MINIMAL)

with open('packing_or_output.csv', 'w') as packCSV:
	dataWriter = csv.writer(packCSV, dialect='customDialect')
	for row in result:
		dataWriter.writerow(row)
		
# prob.remove(model.getVars())
# prob.remove(model.getConstrs())
del prob
gurobipy.disposeDefaultEnv()		
