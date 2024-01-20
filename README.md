# DDoS Attacks

Try to implement protection on Defender container and launch Attacker to examine the protection

* attacker container with 6 attacks: 
  * UDP Flood
  * ICMP flood
  * HTTP flood
  * Slowloris
  * SYN flood
  * Ping of Death
* defender container - ubuntu & nginx with simple website


## Testing

### ICMP

```
hping3 --icmp --faster -c 1000 defender -p 80

--- defender hping statistic ---
1000 packets transmitted, 943 packets received, 6% packet loss
round-trip min/avg/max = 0.1/18.8/57.5 ms
```

#### Protection:
block ICMP messages in firewall by adding the following rule to /etc/ufw/before.rules on *Defender*:
```properties
-A ufw-before-input -p icmp --icmp-type echo-request -j DROP
```
and execute
```shell
ufw disable && ufw enable
```

#### Results
```
hping3 --icmp --faster -c 1000 defender -p 80

 HPING defender (eth0 172.22.0.4): icmp mode set, 28 headers + 0 data bytes
--- defender hping statistic ---
 1000 packets transmitted, 0 packets received, 100% packet loss
 round-trip min/avg/max = 0.0/0.0/0.0 ms
```


### UDP

```shell
hping3 --udp defender -c 100 -d 40
--- defender hping statistic ---
100 packets transmitted, 100 packets received, 0% packet loss
round-trip min/avg/max = 0.3/1.4/3.4 ms
```
#### Protection:
Block udp on *Defender* by adding an iptables rule

```shell
iptables -I INPUT -p udp -j DROP
```
#### Results
```
hping3 --icmp --faster -c 1000 defender -p 80

HPING defender (eth0 172.22.0.4): udp mode set, 28 headers + 40 data bytes
--- defender hping statistic ---
100 packets transmitted, 0 packets received, 100% packet loss
round-trip min/avg/max = 0.0/0.0/0.0 ms
```

On *Defender*:
```shell
iptables -L -n -v

Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         
  121  8228 DROP       udp  --  *      *       0.0.0.0/0            0.0.0.0/0    
```
### Slowloris

* Attack failed after 60 seconds

```shell
 php /opt/slowloris.php post 1 defender
```
![before_protection.png](screenshots%2Fbefore_protection.png)

### Protection
```
client_body_timeout 5s; 
client_header_timeout 5s;
```
Add to [Nginx conf](nginx%2Fdefault.conf)

* Attack failed after 5 seconds
![after_protection.png](screenshots%2Fafter_protection.png)

### SYN flood
```
hping3 --syn --faster -c 1000 defender -p 80

HPING defender (eth0 172.22.0.4): S set, 40 headers + 40 data bytes
--- defender hping statistic ---
1000 packets transmitted, 1000 packets received, 0% packet loss
round-trip min/avg/max = 0.1/3.7/192.8 ms
```

#### Protection

run on *Defender* container
```shell
iptables -A INPUT -s 172.22.0.0/16 -j DROP
```

#### Result
```
hping3 --syn --faster -c 1000 -d 40 defender -p 80

HPING defender (eth0 172.22.0.4): S set, 40 headers + 40 data bytes
--- defender hping statistic ---
1000 packets transmitted, 0 packets received, 100% packet loss
round-trip min/avg/max = 0.0/0.0/0.0 ms
```
on *Defender* container
```
iptables -L -n -v

Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         
 1000 80000 DROP       all  --  *      *       172.22.0.0/16        0.0.0.0/0    
```

### Http Flood
```shell
hping3 --faster -c 1000 defender

HPING defender (eth0 172.22.0.4): NO FLAGS are set, 40 headers + 0 data bytes
--- defender hping statistic ---
1000 packets transmitted, 1000 packets received, 0% packet loss
round-trip min/avg/max = 0.2/1.9/4.8 ms
```

#### Protection

```
iptables -A INPUT -p tcp -m hashlimit --hashlimit 15/s --hashlimit-burst 30 --hashlimit-mode srcip --hashlimit-srcmask 32 --hashlimit-name synattack -j ACCEPT
iptables -A INPUT -p tcp -j DROP
```

```
hping3 --faster -c 1000 defender

HPING defender (eth0 172.22.0.4): NO FLAGS are set, 40 headers + 0 data bytes
--- defender hping statistic ---
1000 packets transmitted, 31 packets received, 97% packet loss
round-trip min/avg/max = 0.2/1.3/4.5 ms
```

#### Http flood by Siege:

```shell
siege -b -c 1000 -t1m -f url.txt
```
```
Transactions:                  22758 hits
Availability:                  98.41 %
Elapsed time:                  60.29 secs
Data transferred:             382.24 MB
Response time:                  2.34 secs
Transaction rate:             377.48 trans/sec
Throughput:                     6.34 MB/sec
Concurrency:                  881.67
Successful transactions:       22758
Failed transactions:             368
Longest transaction:           33.25
Shortest transaction:           0.02
```

#### Protection in [Nginx conf](nginx%2Fdefault.conf)
* Limiting the Number of Connections
* Using Caching
* Denylisting IP Addresses

```shell
siege -b -c 1000 -t1m -f url.txt
```
```
siege aborted due to excessive socket failure; you
can change the failure threshold in $HOME/.siegerc

Transactions:                      3 hits
Availability:                   0.15 %
Elapsed time:                   2.81 secs
Data transferred:               0.45 MB
Response time:                741.00 secs
Transaction rate:               1.07 trans/sec
Throughput:                     0.16 MB/sec
Concurrency:                  791.11
Successful transactions:           3
Failed transactions:            2023
Longest transaction:            2.76
Shortest transaction:           0.14
```

### Ping of Death
```
ping -l 65610 defender
ping: invalid argument: '65610': out of range: 1 <= value <= 65536
```

```
ping -l 65536 defender

PING defender (172.22.0.4) 56(84) bytes of data.
64 bytes from ddos-attacks-defender-1.ddos-attacks_default (172.22.0.4): icmp_seq=1 ttl=64 time=0.908 ms

--- defender ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.908/0.908/0.908/0.000 ms
```