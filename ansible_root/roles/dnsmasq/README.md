DNS Server Setup
================

We use `dnsmasq` running on the main lab server as the DNS server for DNS zones
local to the lab.  We update all lab servers to put this DNS server 1st in their
`resolv.conf` files before using other DNS resolvers for non-lab-local DNS
lookups.

We actually run PowerDNS "behind" dnsmasq though, and PowerDNS is what actually
is the authoriative name server for the lab-local DNS zones.  We could have just
run PowerDNS directly on the server and left out dnsmasq altogether, but we
wanted dnsmasq to be the common "DNS resolver/server interface" that DNS clients
always interact with.  This is because way we can always switch out PowerDNS and
just use the `address` settings of dnsmasq to set IP addresses manually for
wildcard domains as a way to manage DNS records for example.  And in fact, the
reverse of this, is what we did to switch in PowerDNS behind dnsmasq.  Using
dnsmasq as the common DNS server interface on the lab server allows us to do
things like this.

And another layer deeper, I think we can even use `bind` to back PowerDNS in a
similar fashion.  However, we are actually just backing PowerDNS with a SQL
datastore (initiallly just a `sqlite3` db).
