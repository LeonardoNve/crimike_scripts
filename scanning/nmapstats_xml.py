import string
import pickle
import sys
import xml.etree.ElementTree as ET
from collections import namedtuple

stats_by_ip = {}
stats_by_tcp_port = {}
stats_by_udp_port = {}

NmapPort = namedtuple("NmapPort", "port_number protocol state service service_version tunnel")

class NmapPortC:
    port_number = 0
    protocol = None
    state = 'n/a'
    service = 'n/a'
    service_version = 'n/a'
    tunnel = 'n/a'

class NmapHost:
    ip = '0.0.0.0'
    ports = {}
    os = 'n/a'
    hostname = 'n/a'

    def __init__(self, host_element):
        self.ip = host_element.find('address').attrib['addr']
        try:
            self.os = host_element.find('os').find('osmatch').attrib['name']
        except AttributeError:
            self.os = "n/a"
        self.getPorts(host_element.find('ports'))
        self.getHostname(host_element)

    def getHostname(self, host_element):
        hostscript = host_element.find('hostscript')
        for script in hostscript:
            if script.attrib['id'] == 'smb-os-discovery':
                for elem in script.findall('elem'):
                    if elem.attrib['key'] == "os":
                        self.os = elem.text
                    if elem.attrib['key'] == "fqdn":
                        self.hostname = elem.text

    def getPorts(self, port_element):
        for port in port_element.findall('port'):
            nmap_port = NmapPortC()
            nmap_port.port_number = int(port.attrib['portid'])
            nmap_port.protocol = port.attrib['protocol']
            nmap_port.state = port.find('state').attrib['state']
            try:
                nmap_port.service = port.find('service').attrib['name']
            except AttributeError:
                pass
            product = ""
            version = ""
            extra_info = ""
            service = port.find('service')
            try:
                if 'product' in service.attrib:
                    product = service.attrib['product']
            except AttributeError:
                pass
            try:
                if 'version' in service.attrib:
                    version = service.attrib['version']
            except AttributeError:
                pass
            try:
                if 'extrainfo' in service.attrib:
                    extra_info = service.attrib['extrainfo']
            except AttributeError:
                pass
            nmap_port.service_version = product + ' ' + version + ' ' + extra_info
            try:
                if 'tunnel' in service.attrib:
                    nmap_port.tunnel = service.attrib['tunnel']
            except AttributeError:
                pass
            self.ports[nmap_port.port_number] = nmap_port


def LoadFromXml():    
    for file in sys.argv[2:]:
        tree = ET.parse(file)
        root = tree.getroot()
        host = root.find('host')
        nmap_host = NmapHost(host)
        stats_by_ip[nmap_host.ip] = nmap_host
        for port in nmap_host.ports.keys():
            if nmap_host.ports[port].protocol == 'tcp':
                if port not in stats_by_tcp_port:
                    stats_by_tcp_port[port] = []
                existing_host = [host for host in stats_by_tcp_port[port] if host.ip == nmap_host.ip]  # if host with same IP is already in the list remove it
                for host in existing_host:
                    stats_by_tcp_port[port].remove(host)
                stats_by_tcp_port[port].append(nmap_host)
            elif nmap_host.ports[port].protocol == 'udp':
                if port not in stats_by_udp_port:
                    stats_by_udp_port[port] = []
                existing_host = [host for host in stats_by_udp_port[port] if host.ip == nmap_host.ip]   # if host with same IP is already in the list remove it
                for host in existing_host:
                    stats_by_udp_port[port].remove(host)
                stats_by_udp_port[port].append(nmap_host)
            else:
                print '[ERROR] Protocol is neither TCP, nor UDP: ' + port.port_number + "/" + port.protocol

    print "List of TCP ports found: " + str(sorted(stats_by_tcp_port.keys()))
    print "List of UDP ports found: " + str(sorted(stats_by_udp_port.keys()))
    print "List of IPs checked: " + str(sorted(stats_by_ip.keys()))


def DumpToPickle():
    pickle.dump(stats_by_tcp_port, open('tcp_stats.pickle', 'wb'))
    pickle.dump(stats_by_udp_port, open('udp_stats.pickle', 'wb'))
    pickle.dump(stats_by_ip, open('ip_stats.pickle', 'wb'))

def LoadFromPickle():
    global stats_by_tcp_port
    global stats_by_udp_port
    global stats_by_ip
    stats_by_tcp_port = pickle.load(open('tcp_stats.pickle', 'rb'))
    stats_by_udp_port = pickle.load(open('udp_stats.pickle', 'rb'))
    stats_by_ip = pickle.load(open('ip_stats.pickle', 'rb'))
    print "List of TCP ports found: " + str(sorted(stats_by_tcp_port.keys()))
    print "List of UDP ports found: " + str(sorted(stats_by_udp_port.keys()))
    print "List of IPs checked: " + str(sorted(stats_by_ip.keys()))

def getSslPorts():
    print "SSL"
    for key in stats_by_ip:
        host = stats_by_ip[key]
        for port_number in host.ports:
            port = host.ports[port_number]
            print port
            if port.tunnel == "ssl":
                print host.ip + ":" + str(port_number)


if sys.argv[1] == "loadxml":
    LoadFromXml()
    DumpToPickle()
    for key in stats_by_ip:
        print stats_by_ip[key].ports
    stats_by_ip = {}
    stats_by_tcp_port = {}
    stats_by_udp_port = {}
    LoadFromPickle()
    for key in stats_by_ip:
        print stats_by_ip[key].ports
elif sys.argv[1] == "load":
    LoadFromPickle()
    for key in stats_by_ip:
        print stats_by_ip[key].ports
elif sys.argv[1] == "addxml":
    LoadFromPickle()
    LoadFromXml()
    DumpToPickle()
elif sys.argv[1] == "op":
    LoadFromPickle()
    getSslPorts()
else:
    print "Wrong command, idiot..."


