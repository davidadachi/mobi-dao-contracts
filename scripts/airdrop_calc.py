import csv
import json

filename = 'data.csv'
sum = 0

data = []
out = {}

with open(filename, 'r') as csvfile:
    csvreader = csv.reader(csvfile)
    fields = next(csvreader)
    for row in csvreader:
        amount = float(row[6].replace(',', ''))
        if amount > 9.5: 
            sum += amount
            data.append([row[4], float(row[6].replace(',', ''))])

for d in data:
    # print(d[0], d[1]/sum)
    out.update({d[0]: d[1]/sum})

with open('early-users-mobius.json', 'w+') as f:
    json.dump(out, f)
    # sum = 0
    # for num in out.values():
    #     sum += num

    # print(sum)