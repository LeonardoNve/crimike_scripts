#!/usr/bin/env python
import string
import pickle
import sys
import os
import xml.etree.ElementTree as ET
from collections import namedtuple

stats_by_ip = {}
stats_by_tcp_port = {}
stats_by_udp_port = {}

def initializeHost(host_element):
    ip = host_element.find('address').attrib['addr']
    if ip not in stats_by_ip.keys():
        stats_by_ip[ip] = {}
    try:
        stats_by_ip[ip]["os"] = host_element.find('os').find('osmatch').attrib['name']
    except AttributeError:
        stats_by_ip[ip]["os"] = "n/a"
    getHostname(ip, host_element)
    getPorts(ip, host_element.find('ports'))
    splitByPorts()

def splitByPorts():
    for ip in stats_by_ip:
        for port in stats_by_ip[ip]["tcpports"]:
            if port not in stats_by_tcp_port.keys():
                stats_by_tcp_port[port] = {}
            stats_by_tcp_port[port][ip] = stats_by_ip[ip]
        for port in stats_by_ip[ip]["udpports"]:
            if port not in stats_by_udp_port.keys():
                stats_by_udp_port[port] = {}
            stats_by_udp_port[port][ip] = stats_by_ip[ip]


def getHostname(ip, host_element):
    hostscript = host_element.find('hostscript')
    try:
        for script in hostscript:
            if script.attrib['id'] == 'smb-os-discovery':
                for elem in script.findall('elem'):
                    if elem.attrib['key'] == "os":
                        stats_by_ip[ip]["os"] = elem.text
                    if elem.attrib['key'] == "fqdn":
                        stats_by_ip[ip]["hostname"] = elem.text
    except TypeError:
        pass

def getPorts(ip, port_element):
    if "tcpports" not in stats_by_ip[ip]:
        stats_by_ip[ip]["tcpports"] = {}
    if "udpports" not in stats_by_ip[ip]:
        stats_by_ip[ip]["udpports"] = {}
    if "other_tcp" not in stats_by_ip[ip]:
        stats_by_ip[ip]["other_tcp"] = {}
    if "udp_openf" not in stats_by_ip[ip]:
        stats_by_ip[ip]["udp_openf"] = {}
    if "other_udp" not in stats_by_ip[ip]:
        stats_by_ip[ip]["other_udp"] = {}
    for port in port_element.findall('port'):
        nmap_port = {}
        nmap_port["port_number"] = int(port.attrib['portid'])
        nmap_port["protocol"] = port.attrib['protocol']
        nmap_port["state"] = port.find('state').attrib['state']
        nmap_port["service"] = "n/a"
        nmap_port["tunnel"] = "n/a"
        try:
            nmap_port["service"] = port.find('service').attrib['name']
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
        nmap_port["service_version"] = product + ' ' + version + ' ' + extra_info
        try:
            if 'tunnel' in service.attrib:
                nmap_port["tunnel"] = service.attrib['tunnel']
        except AttributeError:
            pass
        if nmap_port["protocol"] == "tcp":
            if "open" in nmap_port["state"]:
                stats_by_ip[ip]["tcpports"][nmap_port["port_number"]] = nmap_port
            else:
                stats_by_ip[ip]["other_tcp"][nmap_port["port_number"]] = nmap_port
        elif nmap_port["protocol"] == "udp":
            if nmap_port["state"] == "open":
                stats_by_ip[ip]["udpports"][nmap_port["port_number"]] = nmap_port
            elif "open" in nmap_port["state"]:
                stats_by_ip[ip]["udp_openf"][nmap_port["port_number"]] = nmap_port
            else:
                stats_by_ip[ip]["other_udp"][nmap_port["port_number"]] = nmap_port

def LoadFromXml():    
    for file in sys.argv[2:]:
        tree = ET.parse(file)
        root = tree.getroot()
        initializeHost(root.find('host'))

    print "List of TCP ports found: " + str(sorted(stats_by_tcp_port.keys()))
    print "List of UDP ports found: " + str(sorted(stats_by_udp_port.keys()))
    print "List of IPs checked: " + str(sorted(stats_by_ip.keys()))
    print

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
    print

def getSslPorts():
    ip_splitter = sys.argv[2] if len(sys.argv) >= 3 else ":"
    port_splitter = sys.argv[3] if len(sys.argv) >= 4 else ","
    for key in stats_by_ip:
        sys.stdout.write(key + ip_splitter)
        #i = len(stats_by_ip[key]["tcpports"])
        i = 0
        for port_nr in sorted(stats_by_ip[key]["tcpports"]):
            #i-=1
            if "tunnel" in stats_by_ip[key]["tcpports"][port_nr].keys():
                if stats_by_ip[key]["tcpports"][port_nr]["tunnel"] == "ssl":
                    if i <> 0:
                        sys.stdout.write(port_splitter)
                    if i == 0:
                        i = 1
                    sys.stdout.write(str(port_nr))
                    #if i <> 0:
                        #sys.stdout.write(port_splitter)
        print

def getSslPorts2():
    for key in stats_by_ip:
        sys.stdout.write(key + ":")
        aux = dict((port_nr, port) for port_nr, port in stats_by_ip[key]["tcpports"].iteritems() if port["tunnel"] == "ssl")
        for port_nr in aux:
            sys.stdout.write(str(port_nr) + ",")
        print

def getAllTcp():
    ip_splitter = sys.argv[2] if len(sys.argv) >= 3 else ":"
    port_splitter = sys.argv[3] if len(sys.argv) >= 4 else ","
    for key in stats_by_ip:
        i = len(stats_by_ip[key]["tcpports"])
        if i == 0:
            continue
        sys.stdout.write(key + ip_splitter)
        for port_nr in sorted(stats_by_ip[key]["tcpports"]):
            i-=1
            sys.stdout.write(str(port_nr))
            if i <> 0:
                sys.stdout.write(port_splitter)
        print

def getAllUdp():
    ip_splitter = sys.argv[2] if len(sys.argv) >= 3 else ":"
    port_splitter = sys.argv[3] if len(sys.argv) >= 4 else ","
    for key in stats_by_ip:
        i = len(stats_by_ip[key]["udpports"])
        if i == 0:
                continue
        sys.stdout.write(key + ip_splitter)
        for port_nr in sorted(stats_by_ip[key]["udpports"]):
            i-=1
            sys.stdout.write(str(port_nr))
            if i <> 0:
                sys.stdout.write(port_splitter)
        print

def getIpsForAllTcp():
    ip_splitter = sys.argv[2] if len(sys.argv) >= 3 else ","
    port_splitter = sys.argv[3] if len(sys.argv) >= 4 else ":"
    for port in stats_by_tcp_port:
        sys.stdout.write(str(port) + port_splitter)
        i = len(stats_by_tcp_port[port])
        for ip in stats_by_tcp_port[port]:
            i-=1
            sys.stdout.write(ip)
            if i <> 0:
                sys.stdout.write(ip_splitter)
        print

def getIpsForAllUdp():
    ip_splitter = sys.argv[2] if len(sys.argv) >= 3 else ","
    port_splitter = sys.argv[3] if len(sys.argv) >= 4 else ":"
    for port in stats_by_udp_port:
        sys.stdout.write(str(port) + port_splitter)
        i = len(stats_by_udp_port[port])
        for ip in stats_by_udp_port[port]:
            i-=1
            sys.stdout.write(ip)
            if i <> 0:
                sys.stdout.write(ip_splitter)
        print

def getIpsForTcpPort(port):
    ip_splitter = sys.argv[3] if len(sys.argv) >= 4 else ","
    port_splitter = sys.argv[4] if len(sys.argv) >= 5 else ":"
    sys.stdout.write(str(port) + port_splitter)
    i = 0
    for key in stats_by_ip:
        if port in stats_by_ip[key]["tcpports"]: 
            if i == 0:
                i = 1
            else:
                sys.stdout.write(ip_splitter)
            sys.stdout.write(key)
    print

def getIpsForUdpPort(port):
    ip_splitter = sys.argv[3] if len(sys.argv) >= 4 else ","
    port_splitter = sys.argv[4] if len(sys.argv) >= 5 else ":"
    sys.stdout.write(str(port) + port_splitter)
    i = 0
    for key in stats_by_ip:
        if port in stats_by_ip[key]["udpports"]: 
            if i == 0:
                i = 1
            else:
                sys.stdout.write(ip_splitter)
            sys.stdout.write(key)
    print

def countPorts():
    ip_splitter = sys.argv[2] if len(sys.argv) >= 3 else ":"
    port_splitter = sys.argv[3] if len(sys.argv) >= 4 else ","
    for ip in stats_by_ip:
        print ip + ip_splitter + str(len(stats_by_ip[ip]["tcpports"])) + "t" + port_splitter + str(len(stats_by_ip[ip]["udpports"])) + "u" + port_splitter + str(len(stats_by_ip[ip]["other_udp"])) + "u/other" + port_splitter + str(len(stats_by_ip[ip]["other_tcp"])) + "t/other" + port_splitter + str(len(stats_by_ip[ip]["udp_openf"])) + "u/of"


def countIps():
    port_splitter = sys.argv[2] if len(sys.argv) >= 3 else ":"
    print "TCP ports"
    for port in sorted(stats_by_tcp_port):
        print str(port) + port_splitter + str(len(stats_by_tcp_port[port]))
    print "UDP ports"
    for port in sorted(stats_by_udp_port):
        print str(port) + port_splitter + str(len(stats_by_udp_port[port]))

def printHost():
    ip = sys.argv[2]
    print ip
    if "os" in stats_by_ip[ip]:
        print "OS: " + stats_by_ip[ip]["os"]
    if "hostname" in stats_by_ip[ip]:
        print "Hostname: " + stats_by_ip[ip]["hostname"]

def printPort():
    port = int(sys.argv[2])
    print "Port: " + str(port)
    for key in stats_by_ip:
        if port in sorted(stats_by_ip[key]["tcpports"]):
            print "IP: " + key
            print "  TCP"
            print "    Service: " + stats_by_ip[key]["tcpports"][port]["service"]
            print "    Service version: " + stats_by_ip[key]["tcpports"][port]["service_version"]
            print "    Tunnel: " + stats_by_ip[key]["tcpports"][port]["tunnel"]
        if port in stats_by_ip[key]["udpports"]:
            print "IP: " + key
            print "  UDP"
            print "    Service: " + stats_by_ip[key]["udpports"][port]["service"]
            print "    Service version: " + stats_by_ip[key]["udpports"][port]["service_version"]

def closedTcp():
    ip_splitter = sys.argv[2] if len(sys.argv) >= 3 else ":"
    port_splitter = sys.argv[3] if len(sys.argv) >= 4 else ","
    for key in stats_by_ip:
        i = len(stats_by_ip[key]["other_tcp"])
        if i == 0:
                continue
        sys.stdout.write(key + ip_splitter)
        for port_nr in stats_by_ip[key]["other_tcp"]:
            i-=1
            sys.stdout.write(str(port_nr))
            if i <> 0:
                sys.stdout.write(port_splitter)
        print

def ofUdpPorts():
    ip_splitter = sys.argv[2] if len(sys.argv) >= 3 else ":"
    port_splitter = sys.argv[3] if len(sys.argv) >= 4 else ","
    for key in stats_by_ip:
        i = len(stats_by_ip[key]["udp_openf"])
        if i == 0:
                continue
        sys.stdout.write(key + ip_splitter)
        for port_nr in stats_by_ip[key]["udp_openf"]:
            i-=1
            sys.stdout.write(str(port_nr))
            if i <> 0:
                sys.stdout.write(port_splitter)
        print

def otherUdp():
    ip_splitter = sys.argv[2] if len(sys.argv) >= 3 else ":"
    port_splitter = sys.argv[3] if len(sys.argv) >= 4 else ","
    for key in stats_by_ip:
        i = len(stats_by_ip[key]["other_udp"])
        if i == 0:
                continue
        sys.stdout.write(key + ip_splitter)
        for port_nr in stats_by_ip[key]["other_udp"]:
            i-=1
            sys.stdout.write(str(port_nr))
            if i <> 0:
                sys.stdout.write(port_splitter)
        print

def RunSsl():
    ip = sys.argv[2] if len(sys.argv) >= 3 else "*"
    port = sys.argv[3] if len(sys.argv) >=4 else "*"
    for key in stats_by_ip:
        if ip == "*" or ip == key:
            for ssl_port in sorted(stats_by_ip[key]["tcpports"]):
                if stats_by_ip[key]["tcpports"][ssl_port]["tunnel"] == "ssl" and (port == "*" or ssl_port == port):
                    print "Running for " + key + ":" + str(ssl_port)
                    os.system("ssl-cipher-suite-enum.pl " + key + ":" + str(ssl_port) + " > " + key + "/" + key + "_" + str(ssl_port) + "_ssl.enum")


def printHelp():
    print "Usage:"
    print "<script> loadxml [xml_files] - start fresh"
    print "<script> addxml [xml_files] - add to already existing pickle"
    print "<script> load - load and print stats" 
    print "<script> getssl - get ports that are tunneled" 
    print "<script> all - print <host>:<port1>,<port2>..." 
    print "<script> tcp - print <port>:<host1>,<host2>..." 
    print "<script> tcp 80 - print hosts for port 80" 
    print "<script> udp - print <port>:<host1>,<host2>..."  
    print "<script> udp 53 - print hosts for port 53" 
    print "<script> countips - print <port>:#ips"
    print "<script> countports - print <host>: $ports"
    print "<script> othertcp - print not open tcp ports"
    print "<script> otherudp - print not open udp ports"
    print "<script> host <ip> - print info about host given"
    print "<script> port <port> - print info about port on each host"
    print "<script> runssl - run ssl-cipher-suite-enum on all ssl ports"
    print "<script> runssl <ip> - run ssl-cipher-suite-enum on all ssl ports on <ip>"
    print "<script> runssl <ip> <port> - run ssl-cipher-suite-enum on <ip> on port <port>"
    print "<script> runssl * <port> - run ssl-cipher-suite-enum on all ips on port <port>"
    print "All printing commands support ip splitter and port splitter as last two params"


def main():
    if len(sys.argv) == 1:
        printHelp()
        return
    if sys.argv[1] == "loadxml":
        LoadFromXml()
        DumpToPickle()
    elif sys.argv[1] == "load":
        LoadFromPickle()
    elif sys.argv[1] == "addxml":
        LoadFromPickle()
        LoadFromXml()
        DumpToPickle()
    elif sys.argv[1] == "getssl":
        LoadFromPickle()
        getSslPorts()
    elif sys.argv[1] == "all":
        LoadFromPickle()
        print "TCP Ports"
        getAllTcp()
        print "UDP Ports"
        getAllUdp()
    elif sys.argv[1] == "tcp":
        LoadFromPickle()
        port = int(sys.argv[2]) if len(sys.argv) >= 3 else 0
        if port == 0:
            getIpsForAllTcp()
        else:
            getIpsForTcpPort(port)
    elif sys.argv[1] == "udp":
        LoadFromPickle()
        port = int(sys.argv[2]) if len(sys.argv) >= 3 else 0
        if port == 0:
            getIpsForAllUdp()
        else:
            getIpsForUdpPort(port)
    elif sys.argv[1] == "countips":
        LoadFromPickle()
        countIps()
    elif sys.argv[1] == "countports":
        LoadFromPickle()
        countPorts()
    elif sys.argv[1] == "othertcp":
        LoadFromPickle()
        closedTcp()
    elif sys.argv[1] == "otherudp":
        LoadFromPickle()
        otherUdp()
        print "Open/Filtered"
        ofUdpPorts()
    elif sys.argv[1] == "host":
        LoadFromPickle()
        printHost()
    elif sys.argv[1] == "port":
        LoadFromPickle()
        printPort()
    elif sys.argv[1] == "runssl":
        LoadFromPickle()
        RunSsl()
        print "Done, output files are in the ip folders"
    else:
        print "Wrong command, idiot..."
        print
        printHelp()


main()
