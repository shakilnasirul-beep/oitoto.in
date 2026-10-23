# 🚀 Oi Toto! — Production Deployment & Server Maintenance Guide

---

## 1. Production Server Architecture

Recommended Production Setup:
- **OS:** Ubuntu 22.04 / 24.04 LTS Linux
- **Web Server:** Nginx 1.24+
- **PHP Process Manager:** PHP 8.2-FPM
- **Database Server:** MySQL 8.0+ or MariaDB 10.11+
- **Security:** UFW Firewall, Let's Encrypt SSL (Certbot), Fail2ban

---

## 2. Nginx Server Configuration

Create `/etc/nginx/sites-available/api.oitoto.in`:
```nginx
server {
    listen 80;
    server_name api.oitoto.in admin.oitoto.in;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.oitoto.in;

    ssl_certificate /etc/letsencrypt/live/api.oitoto.in/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.oitoto.in/privkey.pem;

    root /var/www/oitoto/backend/public;
    index index.php;

    client_max_body_size 20M;

    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options "nosniff";

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }

    # Restrict hidden files and environment secrets
    location ~ /\. {
        deny all;
    }
}

# Admin Panel Virtual Host
server {
    listen 443 ssl http2;
    server_name admin.oitoto.in;

    ssl_certificate /etc/letsencrypt/live/api.oitoto.in/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.oitoto.in/privkey.pem;

    root /var/www/oitoto/admin;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

---

## 3. Production `.env` Hardening

Ensure the following flags are set in production:
```ini
APP_ENV=production
APP_DEBUG=false
APP_URL=https://api.oitoto.in

# Strong 64-character JWT cryptographic key
JWT_SECRET=b63c7885b54a29a43a75877c3dc09d948332159048a9463b8d60c2394582f349
JWT_EXPIRY_DAYS=30

# Production Indian SMS Gateway (e.g. Fast2SMS or MSG91)
SMS_PROVIDER=fast2sms
SMS_API_KEY=your_production_sms_secret_key
SMS_SENDER_ID=OITOTO

# Production Razorpay Keys
PAYMENT_GATEWAY=razorpay_upi
RAZORPAY_KEY_ID=rzp_live_your_actual_key_id
RAZORPAY_KEY_SECRET=your_actual_razorpay_secret
PAYMENT_MODE=production
```

---

## 4. Automated Database Backup Script

Create `/usr/local/bin/oitoto-db-backup.sh`:
```bash
#!/bin/bash
BACKUP_DIR="/var/backups/oitoto_db"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
mkdir -p "$BACKUP_DIR"

# Dump database with transactions
mysqldump -u root -p'YourDbPassword' --single-transaction --routines --triggers oitoto_db | gzip > "$BACKUP_DIR/oitoto_db_$TIMESTAMP.sql.gz"

# Retain only last 14 days of backups
find "$BACKUP_DIR" -type f -name "oitoto_db_*.sql.gz" -mtime +14 -exec rm {} \;

echo "[$(date)] Backup created: $BACKUP_DIR/oitoto_db_$TIMESTAMP.sql.gz"
```

Add cron job to run backup every midnight at 02:00 AM:
```bash
0 2 * * * /usr/local/bin/oitoto-db-backup.sh >> /var/log/oitoto_backup.log 2>&1
```

---

## 5. System Health Monitoring

To monitor backend API health:
```bash
curl -i https://api.oitoto.in/
```
Expected response:
```json
{
  "success": true,
  "message": "Oi Toto API Server is running.",
  "data": {
    "brand": "Oi Toto! — Pan-India E-Rickshaw Booking Platform",
    "tagline": "Tap. Book. Cholo!",
    "vehicle_type": "Electric Rickshaw (E-Rickshaw)",
    "version": "1.0.0",
    "status": "operational"
  }
}
```
