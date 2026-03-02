"""
api/utils.py

Utility functions for UniFind's auth system.
This is where the spooky cryptography stuff lives.

DISCLAIMER: We are using salted SHA-256 as per project requirements.
SHA-256 was designed for speed, which generally makes it worse for
passwords than bcrypt/argon2 (which are intentionally slow). However:
  1. This is a class project demo, not Fort Knox
  2. The project spec said SHA-256
  3. We ARE using a proper random salt, which prevents rainbow table attacks
  4. If a hacker is targeting Montclair State University's textbook marketplace
     I think we have bigger problems

We also have a separate token hashing function for email verification.
That one stores a SHA-256 hash of the token, not the token itself.
"""

import hashlib
import secrets


# ============================================================
# PASSWORD HASHING
# ============================================================

def hash_password(plaintext_password: str) -> str:
    """
    Takes a plaintext password and returns a salted SHA-256 hash.

    Output format: "<64-char-hex-salt>$<64-char-hex-hash>"
    Total length: 129 characters. Fits in VARCHAR(255). 

    The salt is 32 random bytes encoded as a 64-char hex string.
    It's different every single call, so two users with the same
    password get completely different hashes. This is the whole point
    of salting. Without it, you could precompute a lookup table of
    common passwords and crack everything instantly. Bad times.

    Example:
        hash_password("hunter2")
        → "a3f2b8...c1d9$e7f0a1...8b3c"  (not a real example, don't try it)
    """

    # Summon 32 bytes of cryptographically secure randomness from the void.
    # This is NOT random.random(). That would be embarrassing.
    # secrets.token_hex(32) pulls from the OS's entropy pool (/dev/urandom
    # on Linux, CryptGenRandom on Windows). Actual randomness. Proper randomness.
    salt = secrets.token_hex(32)  # 32 bytes → 64 hex chars

    # Concatenate salt + password, then hash the whole thing.
    # The salt goes FIRST so an attacker can't just hash common passwords
    # and check if any stored hash ends with that value.
    salted_input = (salt + plaintext_password).encode('utf-8')
    password_hash = hashlib.sha256(salted_input).hexdigest()

    # Store as "salt$hash" so we can split it back out during verification.
    # The $ is the separator. It won't appear in either the salt or hash
    # because both are hex strings (only 0-9 and a-f).
    return f"{salt}${password_hash}"


def verify_password(plaintext_password: str, stored_hash: str) -> bool:
    """
    Verifies a plaintext password against a stored "salt$hash" string.
    Returns True if they match, False if they don't or if something
    is malformed.

    Uses secrets.compare_digest() instead of == for comparison.
    This prevents timing attacks — an attacker measuring how many
    microseconds your comparison takes can sometimes deduce partial
    matches with ==. compare_digest always takes the same time.
    We probably don't need this level of paranoia for a class project
    but it's good practice and it makes us look smart.
    """

    try:
        # Peel apart the "salt$hash" format
        salt, original_hash = stored_hash.split('$', 1)
    except ValueError:
        # If the stored hash doesn't have a $ in it, something went
        # catastrophically wrong during registration. Reject everything.
        # Do NOT leak any info about what specifically is wrong.
        return False

    # Recompute the hash using the extracted salt and the provided password
    salted_input = (salt + plaintext_password).encode('utf-8')
    computed_hash = hashlib.sha256(salted_input).hexdigest()

    # Constant-time comparison. Paranoia: activated.
    return secrets.compare_digest(computed_hash, original_hash)


# ============================================================
# EMAIL VERIFICATION TOKEN GENERATION
# ============================================================

def generate_raw_token() -> str:
    """
    Generates a raw verification token to send in the email.
    This is a 64-character hex string (32 random bytes).
    
    This is what goes in the URL. We never store this directly.
    We store hash_token(this) in the database.
    """
    return secrets.token_hex(32)


def hash_token(raw_token: str) -> str:
    """
    Hashes a raw token for safe database storage.

    We store the hash, not the raw token. If someone reads the database
    (SQL injection, compromised host, nosy database admin), they can't use
    a stored hash to construct a valid verification URL. 
    
    This is what goes into email_verification_tokens.token_hash.
    SHA-256 of a high-entropy random token is totally fine here —
    we're not protecting against brute force (the token space is 2^256),
    we're protecting against database leakage.
    """
    return hashlib.sha256(raw_token.encode('utf-8')).hexdigest()


def is_valid_montclair_email(email: str) -> bool:
    """
    Returns True if the email ends with @montclair.edu.
    
    This is the bouncer at the door. No montclair.edu? You're not
    getting in. Doesn't matter if you're a professor, a student,
    or the university president. No domain, no app.
    
    We lowercase the email first because some people think
    TYPING@MONTCLAIR.EDU makes them look important.
    """
    return email.lower().strip().endswith('@montclair.edu')
