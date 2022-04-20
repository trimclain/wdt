# WDT
WDT is a Web Deployment Tool using Express, Nginx and SSL with Let's Encrypt. </br>

It uses
- [n](https://github.com/tj/n) -- [Node.js](https://nodejs.org/en/) version manager
- [Express.js](https://expressjs.com/) -- Web framework for Node.js
- [Nginx](https://nginx.org/) --  HTTP and reverse proxy server
- [pm2](https://pm2.keymetrics.io/) -- Daemon Process Manager for Node.js
- [certbot](https://github.com/certbot/certbot) -- client for the Let's Encrypt CA with a [plugin](https://packages.debian.org/buster/python3-certbot-nginx) for nginx
- [crontab](https://man7.org/linux/man-pages/man5/crontab.5.html) -- [cron job](https://en.wikipedia.org/wiki/Cron) creator and scheduler
- [ufw](https://wiki.archlinux.org/title/Uncomplicated_Firewall) -- program for managing a netfilter firewall

### TODO:
- [ ] Add --clean option or similar to undo all installations of this script
- [ ] Add -d, --delete option or similar to delete a give domain, which was isntalled with this script
- [ ] Finish the crontab part
