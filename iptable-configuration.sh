#!/bin/bash
echo " _____   _       _           _ _   _______      "            
echo "(____ \ (_)     (_)_        | | | (_______)        "         
echo " _   \ \ _  ____ _| |_  ____| | |    __    ___  ____   ____ "
echo "| |   | | |/ _  | |  _)/ _  | | |   / /   / _ \|  _ \ / _  )"
echo "| |__/ /| ( ( | | | |_( ( | | | |_ / /___| |_| | | | ( (/ / "
echo "|_____/ |_|\_|| |_|\___)_||_|_|_(_|_______)___/|_| |_|\____)"
echo "          (_____|                                           "
echo "
echo "@Author : JC H"
echo "@Project: https://github.com/Ghost-devlopper/DDOSProtection
echo ""
echo "Script post install ubuntu desktop or server"
echo ""
echo "Copyright (C) 2020"
echo "This program is free software; you can redistribute it and/or modify"
echo "it under the terms of the GNU General Public License as published by"
echo "the Free Software Foundation; either version 3 of the License, or"
echo "(at your option) any later version."
echo ""
echo "This program is distributed in the hope that it will be useful,"
echo "but WITHOUT ANY WARRANTY; without even the implied warranty of"
echo "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the"
echo "GNU General Public License for more details."

###################################
#  Installation des dépendances pour ddos-deflate
###################################

###################################
#  Installation des dépendances pour ddos-deflate
###################################
apt install iptables-persistent -y

echo "##################"
echo "Installation es dépendances pour ddos-deflate"
echo "##################"
apt install dnsutils -y
apt install net-tools -y
apt install tcpdump -y
apt install dsniff -y
apt install grepcidr -y

echo "##################"
echo "Installation de ddos-deflate depuis https://github.com/jgmdev/"
echo "##################"
wget https://github.com/jgmdev/ddos-deflate/archive/master.zip -O ddos.zip
unzip ddos.zip
cd ddos-deflate-master
./install.sh
systemctl restart ddos

# Script béta test pour faire des réglages dans iptable.
###################################
#     Ajout des filtres           #
###################################
echo "##################"
echo "Ajout des filtres"
echo "##################"

iptables -P INPUT DROP
iptables -t filter -N LOG_N_ACCEPT
iptables -t filter -A LOG_N_ACCEPT -j LOG --log-level warning --log-prefix "ACTION=INPUT-ACCEPT "
iptables -t filter -A LOG_N_ACCEPT -j ACCEPT

###################################
#     première configuration      #
###################################
echo "##################"
echo "Configuration 1/3 - la base"
echo "##################"
iptables -A INPUT -i eno1 -j LOG_N_ACCEPT                                      # Autoriser les flux en localhost
iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j LOG_N_ACCEPT  # Autoriser les connexions déjà établies,
iptables -A INPUT -p tcp -m tcp --dport 22 -j LOG_N_ACCEPT                    # Autoriser SSH,
iptables -A INPUT -p tcp -m tcp --dport http -j LOG_N_ACCEPT                  # Autoriser HTTP,
iptables -A INPUT -p tcp -m tcp --dport https -j LOG_N_ACCEPT                 # Autoriser HTTPS,
iptables -P INPUT DROP                                                 # Politique par défaut de la table INPUT : DROP. (i.e bloquer tout le reste).
iptables -P FORWARD DROP                                               # On est pas un routeur ou un NAT pour un réseau privé, on ne forward pas de paquet.


###################################
#     Seconde configuration       #
###################################
echo "##################"
echo "Configuration 2/3 - protection classique"
echo "##################"
# We can simply use following command to enable logging in iptables.
iptables -A INPUT -j LOG

# We can also define the source ip or range for which log will be created.
iptables -A INPUT -s 192.168.10.0/24 -j LOG

#To define level of LOG generated by iptables us –log-level followed by level number.
iptables -A INPUT -s 192.168.10.0/24 -j LOG --log-level 4

#We can also add some prefix in generated Logs, So it will be easy to search for logs in a huge file.
iptables -A INPUT -s 192.168.10.0/24 -j LOG --log-prefix "** SUSPECT **"

### 1: Drop invalid packets ### 
iptables -t mangle -A PREROUTING -m conntrack --ctstate INVALID -j DROP  

### 2: Drop TCP packets that are new and are not SYN ### 
iptables -t mangle -A PREROUTING -p tcp ! --syn -m conntrack --ctstate NEW -j DROP 
 
### 3: Drop SYN packets with suspicious MSS value ### 
iptables -t mangle -A PREROUTING -p tcp -m conntrack --ctstate NEW -m tcpmss ! --mss 536:65535 -j DROP  

### 4: Block packets with bogus TCP flags ### 
iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP 
iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN FIN,SYN -j DROP 
iptables -t mangle -A PREROUTING -p tcp --tcp-flags SYN,RST SYN,RST -j DROP 
iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,RST FIN,RST -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,ACK FIN -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,URG URG -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,FIN FIN -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,PSH PSH -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL ALL -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL NONE -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,FIN,PSH,URG -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP

### 5: Block spoofed packets ### 
iptables -t mangle -A PREROUTING -s 224.0.0.0/3 -j DROP
iptables -t mangle -A PREROUTING -s 169.254.0.0/16 -j DROP
iptables -t mangle -A PREROUTING -s 172.16.0.0/12 -j DROP
iptables -t mangle -A PREROUTING -s 192.0.2.0/24 -j DROP
iptables -t mangle -A PREROUTING -s 192.168.0.0/16 -j DROP
iptables -t mangle -A PREROUTING -s 10.0.0.0/8 -j DROP
iptables -t mangle -A PREROUTING -s 0.0.0.0/8 -j DROP
iptables -t mangle -A PREROUTING -s 240.0.0.0/5 -j DROP
iptables -t mangle -A PREROUTING -s 127.0.0.0/8 ! -i lo -j DROP

### 6: Drop ICMP (you usually don't need this protocol) ### 
iptables -t mangle -A PREROUTING -p icmp -j DROP  

### 7: Drop fragments in all chains ### 
iptables -t mangle -A PREROUTING -f -j DROP  

### 8: Limit connections per source IP ### 
iptables -A INPUT -p tcp -m connlimit --connlimit-above 111 -j REJECT --reject-with tcp-reset  

### 9: Limit RST packets ### 
iptables -A INPUT -p tcp --tcp-flags RST RST -m limit --limit 2/s --limit-burst 2 -j LOG_N_ACCEPT  
iptables -A INPUT -p tcp --tcp-flags RST RST -j DROP  

### 10: Limit new TCP connections per second per source IP ### 
iptables -A INPUT -p tcp -m conntrack --ctstate NEW -m limit --limit 60/s --limit-burst 20 -j LOG_N_ACCEPT  
iptables -A INPUT -p tcp -m conntrack --ctstate NEW -j DROP  

### 11: Use SYNPROXY on all ports (disables connection limiting rule) ### 
# Hidden - unlock content above in "Mitigating SYN Floods With SYNPROXY" section

### SSH brute-force protection ### 
iptables -A INPUT -p tcp --dport ssh -m conntrack --ctstate NEW -m recent --set 
iptables -A INPUT -p tcp --dport ssh -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 10 -j DROP  

### Protection against port scanning ### 
iptables -N port-scanning 
iptables -A port-scanning -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s --limit-burst 2 -j RETURN 
iptables -A port-scanning -j DROP

###################################
#     Troisième configuration     #
###################################
echo "##################"
echo "Configuration 3/3 - protection avancé"
echo "##################"
### PROTECTION SYNFLOOD 
iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s -j LOG_N_ACCEPT

### PROTECTION PINGFLOOD
iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s -j ACCEPT

### PROTECTION SCAN PORT
iptables -A INPUT -p tcp --tcp-flags ALL NONE -m limit --limit 1/h -j LOG_N_ACCEPT
iptables -A INPUT -p tcp --tcp-flags ALL ALL -m limit --limit 1/h -j LOG_N_ACCEPT

###################################
#     Connexion en sorties        #
###################################
echo "##################"
echo "Log des connexions en sorties"
echo "##################"
iptables -I OUTPUT -m state -p tcp --state NEW ! -s 127.0.0.1 ! -d 127.0.0.1 -j LOG --log-prefix "ACTION=OUTPUT-TCP "
iptables -I OUTPUT -m state -p udp -s 127.0.0.1 ! -d 127.0.0.1 -j LOG --log-prefix "ACTION=OUTPUT-UDP "

#echo "##################"
#echo "Installation de haproxy depuis https://github.com/jgmdev/"
#echo "##################"
#wget http://www.haproxy.org/download/2.1/src/haproxy-2.1.7.tar.gz -O haproxy.tar.gz
#tar xvzf haproxy.tar.gz
#cd haproxy-2.1.7/
#make -j $(nproc) TARGET=linux-glibc && USE_OPENSSL=1 USE_ZLIB=1 USE_LUA=1 USE_PCRE=1 USE_SYSTEMD=1 USE_GZIP=1 USE_THREAD=1 USE_LIBCRYPT=1

#sudo apt-get update
#sudo apt-get install build-essential
#make install
# haproxy -f /etc/haproxy.cfg && -D -p /var/run/haproxy.pid -sf $(cat /var/run/haproxy.pid)

echo "##################"
echo "Fin des installations"
echo "##################"

###################################
#         Fin du script           #
###################################
echo "##################"
echo "La configuration est terminé, si vous avez un soucis ouvrez un ticket sur le git du projet https://github.com/Ghost-devlopper/DDOSProtection/issues"
echo "##################"
apt-get install iptables-persistent
iptables-save > /etc/iptables/rules.v4
systemctl restart rsyslog
echo ""
echo "Affichage en temps réel des log de iptable"
echo ""
tail -f /var/log/kern.log
