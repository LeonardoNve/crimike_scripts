# andrew <andrewjkerr>
# basic sql injection prevention
$sth = $db->prepare("SELECT * FROM table WHERE username=? and password=?");
$sth->execute([$pUsername $pPassword]);
$results = $stmt->fetchAll(PDO:FETCH_ASSOC);

# basic xss prevention
strip_tags(string); # http://www.php.net/manual/en/function.strip-tags.php

## can also allow certain tags:
	strip_tags(string, allowed_tags);

# strip out HTML and special characters
# source: http://stackoverflow.com/questions/7128856/strip-out-html-and-special-characters
$clear = trim(preg_replace('/ +/', ' ', preg_replace('/[^A-Za-z0-9 ]/', ' ', urldecode(html_entity_decode(strip_tags($des)))))); 
# To view the php version:
php -v

# To view the installed php modules:
php -m

# To view phpinfo() information:
php -i

# To lint a php file:
php -l file.php

# To lint all php files within the cwd:
find . -name "*.php" -print0 | xargs -0 -n1 -P8 php -l

# To enter an interactive shell:
php -a

# To locate the system's php.ini files:
php -i | grep "php.ini"

# To start a local webserver for the cwd on port 3000 (requires php >= 5.4):
php -S localhost:3000
