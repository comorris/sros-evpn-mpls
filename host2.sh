ip link add link eth1 name eth1.10 type vlan id 10
ip addr add 10.10.10.12/24 dev eth1.10
ip link set eth1.10 up
route add default gw 10.10.10.1
