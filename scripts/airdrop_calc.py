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
        sum += float(row[6].replace(',', ''))
        data.append([row[4], float(row[6].replace(',', ''))])
    for row in data:
        print(row[0], row[1]/sum)
        out.update({row[0]: row[1]/sum})

with open('early-users-mobius.json', 'w+') as f:
    json.dump(out, f)
    # sum = 0
    # for num in out.values():
    #     sum += num

    # print(sum)