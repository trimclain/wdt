# WDT
WDT is a Website Deployment Tool using Express, Nginx and SSL with Let's Encrypt. </br>

It uses
- [n](https://github.com/tj/n) -- [Node.js](https://nodejs.org/en/) version manager
- [Express.js](https://expressjs.com/) -- Web framework for Node.js
- [Nginx](https://nginx.org/) --  HTTP and reverse proxy server
- [pm2](https://pm2.keymetrics.io/) -- Daemon Process Manager for Node.js
- [ufw](https://wiki.archlinux.org/title/Uncomplicated_Firewall) -- program for managing a netfilter firewall
- [certbot](https://github.com/certbot/certbot) -- client for the Let's Encrypt CA with a [plugin](https://packages.debian.org/buster/python3-certbot-nginx) for nginx
- [crontab](https://man7.org/linux/man-pages/man5/crontab.5.html) -- [cron job](https://en.wikipedia.org/wiki/Cron) creator and scheduler

## Getting Started

### Installing
1. Clone this repository
```
git clone https://github.com/trimclain/wdt
```
2. Run the installation
```
make install
```

### Setting up your domain
This part is required to setup the connection between your domain and your linux server.
0. Go to your domain name registrar's website (e.g. namecheap.com) and sign in.
1. Go to Dashboard and choose your domain to manage
2. Go to the Advanced DNS tab
3. Add a new "A Record", as host add "@" (stands for root), as value add the ip of the server you will be hosting on, TTL leave as "automatic" <br>
   NOTE: You can get the ip of your server with `curl ifconfig.me`
4. Do the same for host "www"

## Demo
NOTE: This demo is outdated!  
Here's a demo showing full deployment of one of my projects. This was done after the configuration [above](https://github.com/trimclain/wdt#setting-up-your-domain).

https://user-images.githubusercontent.com/84108846/172663249-efa38236-df35-48da-a9f9-a67652b3a0f5.mp4
