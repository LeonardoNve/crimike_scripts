from netaddr import IPNetwork
import sys

range = sys.argv[1]


network = IPNetwork(range)


print("First: ", network[0])
print("Last: ", network[len(network) - 1])
print("Bits of the IP: ", network.ip.bits())
print("Mask: ", network.hostmask)
print("Bits of the mask: ", network.hostmask.bits())

