# XONADOSH — SECURITY, COMPLIANCE & RISK MITIGATION PLAN
**Classification:** Confidential / System Architecture  
**Standards:** OWASP Top 10, Republic of Uzbekistan Law O'RQ-1125 (Personal Data Protection)  
**Lead Security Engineer:** DevSecOps & Security Specialist  

---

## 1. Threat Modeling & OWASP Top 10 Defenses

### 1.1 Injection Attacks (SQLi & Command Injection)
- **Defense-in-Depth:** 100% of all database queries use PDO prepared statements with strict parameter binding. Raw string concatenation in SQL queries is categorically prohibited.
- **Input Sanitization:** String inputs are validated against strict whitelists and regex patterns (`uz_phone.dart`, `htmlspecialchars` on HTML output, and `intval` casting on IDs).

### 1.2 Broken Authentication & Session Hijacking
- **Cryptographic Hashing:** Passwords are encrypted using standard `PASSWORD_BCRYPT` (cost factor 12) or Argon2id. Plaintext passwords never touch database logs.
- **Session Tokens:** 64-character cryptographically secure pseudo-random tokens (`bin2hex(random_bytes(32))`).
- **Token Rotation & Expiry:** Short-lived access tokens with refresh token rotation. Logging out revokes active session records immediately.

### 1.3 Broken Object Level Authorization (BOLA / IDOR)
- **Ownership Verification:** Every mutation (editing a listing, deleting a listing, toggling a chore, adding an expense) verifies that the authenticated user (`$_SESSION['user_id']` or Bearer token subject) is either the creator of the resource or an authorized member of the specific household squad.

### 1.4 Unrestricted File Upload & Remote Code Execution (RCE)
- **MIME Validation:** Uploaded media is validated using server-side `finfo` (Magic Bytes check), completely rejecting executable `.php`, `.phtml`, `.cgi`, or `.sh` files masquerading as images.
- **Transcoding Pipeline:** All images are actively transcoded into WebP via PHP GD (`imagewebp`), destroying embedded malicious polyglot payloads.
- **Web Server Hardening:** The `uploads/` directory contains an aggressive `.htaccess` rule denying script execution:
  ```apache
  <FilesMatch "\.(php|phtml|php3|php4|php5|php7|php8|phps|cgi|pl|py|sh)$">
      Order Allow,Deny
      Deny from all
  </FilesMatch>
  ```

### 1.5 Cross-Site Scripting (XSS) & Cross-Site Request Forgery (CSRF)
- **Output Encoding:** All server-rendered landing and admin templates escape output via `htmlspecialchars($val, ENT_QUOTES, 'UTF-8')`.
- **CSRF Tokens:** All state-changing forms in the Super Admin dashboard enforce one-time anti-CSRF token verification (`$_SESSION['csrf_token']`).

---

## 2. Personal Data Protection & Legal Compliance (Uzbekistan Law O'RQ-1125)

The Republic of Uzbekistan's Law "On Personal Data" (including 2026 amendments under O'RQ-1125) enforces rigorous criteria regarding the handling of citizens' personal information:

### 2.1 Principle of Data Minimization
- XonaDosh **strictly prohibits** requesting, storing, or uploading raw internal passport pages, JShShIR (PINFL), or biometric facial scans into the application database.
- Identity and student verification rely solely on cryptographic validation of student ID numbers via the Ministry's official HEMIS system (`verify_hemis.php`) and mobile phone verification.

### 2.2 Account Deletion & Right to be Forgotten (Apple Guideline 5.1.1 compliant)
- Users retain absolute authority to delete their account at any time via `POST /api/account_delete.php` or through the in-app Settings screen.
- Triggering account deletion cascades through sessions, personal profiles, active listings, and anonymizes historical financial audit records.

### 2.3 Lease Agreement Tax Registration Notice
- Under Uzbekistan tax regulations, long-term residential leases must be registered with the State Tax Committee.
- XonaDosh features explicit external guidance directing landlords and tenants to the official government portal:  
  **`https://ijara.soliq.uz/`**
- XonaDosh clearly discloses that it provides software tools and does not act as an automated government registrar unless an official E-Government API partnership is formally established.

---

## 3. Financial Non-Custodial Safeguards

1. **Zero Custody of Funds:**  
   XonaDosh does not operate an escrow wallet, accept funds onto private balances, or function as a payment organisation.
2. **Double-Entry Shared Ledger:**  
   The platform acts exclusively as a transparent computational bookkeeping ledger for roommates (Splitwise model). All transactions represent mutual agreements recorded for social accountability.
3. **Audit Trail:**  
   Expense records retain timestamps, creator IDs, and receipt references, preventing arbitrary balance modifications.
