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

### TODO:
- [ ] Add --clean option or similar to undo all installations of this script
- [ ] Add -d, --delete option or similar to delete a give domain, which was isntalled with this script
- [ ] Finish the crontab part

# What does WDT automate and what is left to do

Here is the instruction of what WDT does and what you should do if you'd do it yourself.

## What to do on namecheap.com
This part should be done by a user. WDT can't do it for you.
1. Go to manage domains, your domain
2. Go to Advanced DNS tab
3. Add a new "A Record", host "@" (stands for root), value: "ip of the server from `curl ifconfig.me`", ttl "automatic"
4. Do the same with host "www"

## How to setup
1. Initialize a node project and install Express and pm2
2. Setup the firewall
3. Install nginx
6. Do the nginx stuff (wip)
7. Check if config is correct
```
sudo nginx -t
```
8. Restart nginx
```
sudo service nginx restart
```
9. To add an SSL certificate from Lets-Encrypt install certbot and it's nginx plugin
```
sudo apt install certbot python3-certbot-nginx -y
```
10. Obtain the certificate
```
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```
11. For auto-renewal create a crontab entry:
      - Open crontab config with
        ```
        crontab -e
        ```
      - Add a cron job that runs the certbot command, which renews the
        certificate if it detects the certificate will expire within 30 days.
        Schedule it to run daily at a specified time (in this example, it does so at 05:00 a.m.):
        ```
        0 5 * * * /usr/bin/certbot renew --quiet
        ```
    Cron line explanation: </br>
    \* \* \* \* \* "command to be executed" </br>
    \- \- \- \- \- </br>
    | | | | | </br>
    | | | | ----- Day of week (0 - 7) (Sunday=0 or 7) </br>
    | | | ------- Month (1 - 12) </br>
    | | --------- Day of month (1 - 31) </br>
    | ----------- Hour (0 - 23) </br>
    ------------- Minute (0 - 59)
