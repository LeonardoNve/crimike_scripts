import string
import sys

stats = {}

for file in sys.argv[1:]:
    with open(file) as f:
        lines = f.readlines()
        for line in lines:
            if not line.startswith("Host"):
                continue
            if "Ports" not in line:
                continue
            host = line[5:line.find("()")]
            stats[host] = []
            data = line[line.find("Ports:")+6:]
            ports = data.split(",")
            for port in ports:
                port_number = int(port.split('/')[0])
                stats[host].append(port_number)


inverse_stats = {}

for key in stats:
    for port in sorted(stats[key]):
        if port not in inverse_stats:
            inverse_stats[port] = []
        inverse_stats[port].append(key)

print "Ports: ",
for key in sorted(inverse_stats):
    print key,

print

for key in sorted(stats):
    print key,"(",len(stats[key]),") : ", sorted(stats[key])
for key in sorted(inverse_stats):
    print key,"(",len(inverse_stats[key]),") : ", sorted(inverse_stats[key])

