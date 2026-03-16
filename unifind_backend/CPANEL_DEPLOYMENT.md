# cPanel Deployment Guide (UniFind Milestone 1)

## 1) Create Database and User
1. In cPanel, open **MySQL Database Wizard**.
2. Create DB (example: `account_unifind`).
3. Create DB user (example: `account_unifind_user`) with strong password.
4. Assign **ALL PRIVILEGES**.

## 2) Upload App Files
1. In **File Manager**, go to `public_html/`.
2. Create folder `unifind` (or deploy into root if preferred).
3. Upload all files from local `unifind_backend/` into `public_html/unifind/`.

## 3) Install PHPMailer Dependency
Option A (recommended, local machine):
1. In local `unifind_backend/`, run `composer install --no-dev --optimize-autoloader`.
2. Upload generated `vendor/` folder to cPanel under `public_html/unifind/vendor/`.

Option B (manual):
1. Upload PHPMailer source files to `vendor/phpmailer/src/` with `PHPMailer.php`, `SMTP.php`, `Exception.php`.

## 4) Import Database Schema
1. Open **phpMyAdmin**.
2. Select your UniFind DB.
3. Import `schema.sql`.

## 5) Configure App
1. Copy `config/config.example.php` to `config/config.php`.
2. Fill DB credentials and SMTP settings.
3. Set `base_url` to your real URL, e.g. `https://yourdomain.com/unifind`.

## 6) Upload Directory and Permissions
1. Ensure folder exists: `uploads/listings/`.
2. Recommended permissions:
   - `uploads/` -> `755`
   - `uploads/listings/` -> `755`
3. Keep `.htaccess` in `uploads/` to block script execution.

## 7) Test End-to-End
1. Register with `@montclair.edu`.
2. Confirm verification email arrives.
3. Click verification link.
4. Login.
5. Browse listings at `/index.php`.
6. Create listing with image upload.

## 8) Troubleshooting
- **No verification emails**: Confirm SMTP host/port/encryption/user/pass; try TLS 587 then SSL 465.
- **Base URL issues**: Wrong redirects usually means `app.base_url` is incorrect.
- **Image upload fails**: Check folder permissions and PHP upload limits (`upload_max_filesize`, `post_max_size`).
- **500 errors**: Check cPanel **Errors** log and `error_log`.
- **Blocked SMTP**: Some hosts block external SMTP. Use cPanel/hosting mail server credentials.
