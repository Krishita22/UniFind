# UniFind Milestone 1 (cPanel PHP/MySQL)

Milestone 1 scope implemented:
- Register/Login
- Montclair-only email verification
- Browse approved listings
- Create listing with secure image upload

## Tech Stack
- PHP 8+
- MySQL/MariaDB
- PHPMailer (SMTP)
- PHP Sessions

## Folder Structure
```text
unifind_backend/
├── .htaccess
├── CPANEL_DEPLOYMENT.md
├── README.md
├── composer.json
├── schema.sql
├── assets/
│   └── css/
│       └── style.css
├── auth/
│   ├── login.php
│   ├── logout.php
│   ├── register.php
│   ├── resend_verification.php
│   └── verify.php
├── config/
│   ├── config.example.php
│   └── config.php
├── includes/
│   ├── auth_guard.php
│   ├── bootstrap.php
│   ├── csrf.php
│   ├── db.php
│   ├── flash.php
│   ├── footer.php
│   ├── functions.php
│   ├── header.php
│   └── mailer.php
├── listings/
│   ├── create.php
│   └── view.php
├── uploads/
│   ├── .htaccess
│   └── listings/
│       └── index.html
└── index.php
```

## Install / Setup
1. Create DB and user with cPanel MySQL Database Wizard.
2. Import `schema.sql` in phpMyAdmin.
3. Configure `config/config.php`.
4. Install PHPMailer locally (`composer install --no-dev --optimize-autoloader`) and upload `vendor/`.
5. Upload app to `public_html/unifind/`.
6. Ensure `uploads/listings` exists and is writable (755 usually works).
7. Visit `https://yourdomain.com/unifind/auth/register.php`.

## Config Notes
Edit `config/config.php`:
- `app.base_url`
- DB credentials
- SMTP credentials
- Security values (token TTL, upload size)
- Listing categories

## Security Controls Included
- Prepared statements (`mysqli`)
- Password hashing with `password_hash(PASSWORD_DEFAULT)` and `password_verify`
- CSRF tokens on POST forms
- Session hardening (`httponly`, `samesite`, secure cookie on HTTPS, `session_regenerate_id` on login)
- Email verification tokens hashed with SHA-256 + expiration + one-time use
- Upload restrictions:
  - MIME check via `finfo`
  - `getimagesize()` validation
  - extension allowlist
  - max size 5MB
  - random file names
  - `.htaccess` script execution block in `uploads/`
- Output escaping via `htmlspecialchars`

## Requirement Mapping / Test Checklist
- [ ] Registration accepts only `@montclair.edu`.
- [ ] Non-montclair email is rejected.
- [ ] Duplicate email registration is rejected.
- [ ] Verification email is sent after registration.
- [ ] Verification link activates account.
- [ ] Expired/invalid link shows resend option.
- [ ] Resend is rate-limited (2 minutes).
- [ ] Unverified users cannot log in.
- [ ] Verified users can log in.
- [ ] Unauthenticated access to `/index.php` redirects to login.
- [ ] Unauthenticated access to `/listings/create.php` redirects to login.
- [ ] Create listing requires all fields.
- [ ] Invalid file type is rejected.
- [ ] Valid listing appears on landing page.
- [ ] Only approved listings are visible.

## Common Issues
- Verification emails not sending: check SMTP and host restrictions.
- Redirect loops: fix `app.base_url`.
- Upload failing: confirm PHP limits and folder permissions.

## Milestone 1 Scope Limits
Not implemented by design:
- Checkout/cart/payments
- Lost & Found workflows
- Messaging
- Advanced search/filtering
- Admin panel (kept future-ready with `is_approved` column)
