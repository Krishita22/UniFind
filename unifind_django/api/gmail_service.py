"""
api/gmail_service.py

Gmail API integration for sending verification emails.

Setup (do this ONCE before running the server for the first time):
  1. Go to console.cloud.google.com
  2. Create a project (call it "UniFind" or whatever)
  3. Go to APIs & Services → Library → search "Gmail API" → Enable it
  4. Go to APIs & Services → Credentials → Create Credentials → OAuth 2.0 Client ID
  5. Configure OAuth consent screen: External, fill in app name "UniFind",
     add your personal email as a test user
  6. Application type: Desktop App
  7. Download the JSON file → rename it credentials.json → put it in
     the root of unifind_django/ (same folder as manage.py)
  8. Add credentials.json and token.json to your .gitignore RIGHT NOW.
     If these end up on GitHub, your Google account is toast.

First time you call get_gmail_service(), it'll open a browser window
asking you to authorize the Gmail account that will SEND the emails.
After you authorize it, a token.json is saved. Future calls are silent.

The account that sends the emails can be any Gmail / Google Workspace
account — ideally a dedicated "unifind.noreply@gmail.com" or similar
so you're not sending auth emails from your personal account like a
suspicious person.
"""

import os
import base64
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

# We only need the ability to SEND emails. Not read them, not manage them,
# just send. Using the most limited scope possible. Principle of least privilege.
# Look it up.
GMAIL_SCOPES = ['https://www.googleapis.com/auth/gmail.send']

# These files live in the project root (same directory as manage.py).
# Change the paths here if you put them somewhere else, but don't do that.
CREDENTIALS_FILE = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'credentials.json')
TOKEN_FILE = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'token.json')


def get_gmail_service():
    """
    Authenticates with the Gmail API and returns a service object.

    On first run: opens a browser for OAuth consent. You click "Allow."
    A token.json is saved to disk. Done.

    On subsequent runs: loads token.json silently. If the token is expired
    it refreshes it automatically using the refresh token. You don't have to
    do anything. It just works. Like magic, except it's OAuth2, which is
    the opposite of magic — it's an RFC document the size of a phonebook.
    """

    creds = None

    # Check if we already have a saved token from a previous auth
    if os.path.exists(TOKEN_FILE):
        creds = Credentials.from_authorized_user_file(TOKEN_FILE, GMAIL_SCOPES)

    # If no token, or the token is invalid/expired...
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            # Token expired but we have a refresh token. Auto-refresh. Silent.
            creds.refresh(Request())
        else:
            # First time ever — need to open the browser and do OAuth.
            # This will NOT work in a headless environment. But we're on
            # a local machine with a browser, so we're fine.
            if not os.path.exists(CREDENTIALS_FILE):
                raise FileNotFoundError(
                    f"credentials.json not found at {CREDENTIALS_FILE}\n"
                    "Did you download it from Google Cloud Console? "
                    "Did you put it in the right folder? "
                    "Did you rename it to credentials.json? "
                    "All three of those things need to be true."
                )

            flow = InstalledAppFlow.from_client_secrets_file(
                CREDENTIALS_FILE, GMAIL_SCOPES
            )
            # Opens browser. User clicks Allow. Callback happens on a local port.
            # port=0 means "pick any available port automatically."
            creds = flow.run_local_server(port=0)

        # Save the credentials for next time so we don't have to do this again
        with open(TOKEN_FILE, 'w') as token_file:
            token_file.write(creds.to_json())

    return build('gmail', 'v1', credentials=creds)


def send_verification_email(to_email: str, full_name: str, raw_token: str) -> bool:
    """
    Sends the verification email to a newly registered user.
    
    Returns True on success, False on failure. Does NOT raise exceptions
    by default — the caller (register view) handles the failure case.

    The verification link points to our Django endpoint, which then
    marks the user as verified in the database. The user just clicks it.

    Args:
        to_email:   The recipient's montclair.edu address
        full_name:  Their name, for the greeting. "Hello, [name]!" is friendlier
                    than "Hello, user_id_4829!" 
        raw_token:  The raw (unhashed) verification token from generate_raw_token().
                    This is what goes in the URL. We never stored this.
                    It only exists in this email and in memory. Briefly.
    """

    try:
        service = get_gmail_service()

        # Build the verification URL that the user clicks.
        # Points to our Django verify-email endpoint.
        # Django is running on localhost:8000.
        verify_url = (
            f"http://localhost:8000/api/verify-email/"
            f"?token={raw_token}&email={to_email}"
        )

        # Build the email. We send both HTML and plain text versions.
        # Email clients that can render HTML get the pretty version.
        # Email clients from 1998 get the plain text version.
        # Both versions do the same thing: tell the user to click a link.
        message = MIMEMultipart('alternative')
        message['to'] = to_email
        message['subject'] = 'Verify your UniFind account'

        # Plain text version (the sensible fallback)
        text_body = f"""Hey {full_name},

Welcome to UniFind! You're almost in.

Click this link to verify your Montclair State University email address:

{verify_url}

This link expires in 24 hours. If you didn't sign up for UniFind,
you can safely ignore this email. Nothing will happen.

— The UniFind Team
(a.k.a. five CSIT415 students who really just want to finish this project)
"""

        # HTML version (the one people actually see)
        html_body = f"""
<html>
<body style="font-family: Arial, sans-serif; max-width: 500px; margin: 0 auto; padding: 20px;">
    <div style="background-color: #A12727; padding: 20px; border-radius: 8px 8px 0 0;">
        <h1 style="color: white; margin: 0; font-size: 24px;">UniFind</h1>
        <p style="color: #EBD1D1; margin: 4px 0 0 0; font-size: 14px;">
            Montclair State University Marketplace
        </p>
    </div>
    
    <div style="background: #fff; border: 1px solid #EBD1D1; border-top: none;
                padding: 24px; border-radius: 0 0 8px 8px;">
        <h2 style="color: #333; margin-top: 0;">Hey {full_name}, verify your email</h2>
        
        <p style="color: #555;">
            You're one click away from accessing the UniFind campus marketplace.
            Click the button below to verify your Montclair State University email address.
        </p>
        
        <div style="text-align: center; margin: 28px 0;">
            <a href="{verify_url}"
               style="background-color: #A12727; color: white; padding: 12px 28px;
                      text-decoration: none; border-radius: 6px; font-weight: bold;
                      font-size: 16px;">
                Verify My Email
            </a>
        </div>
        
        <p style="color: #888; font-size: 13px;">
            This link expires in <strong>24 hours</strong>. If you didn't create a UniFind 
            account, you can safely ignore this email.
        </p>
        
        <p style="color: #AAA; font-size: 12px; margin-top: 16px; word-break: break-all;">
            Can't click the button? Copy and paste this URL:<br>
            {verify_url}
        </p>
    </div>
</body>
</html>
"""

        message.attach(MIMEText(text_body, 'plain'))
        message.attach(MIMEText(html_body, 'html'))

        # Base64-encode the entire message for the Gmail API.
        # Why base64? Because the Gmail API expects it. Why does the Gmail API
        # expect it? Because MIME encoding and email standards are a labyrinth
        # of historical decisions made by people in the 1980s who could not
        # have imagined any of this. We just encode it and move on.
        raw_message = base64.urlsafe_b64encode(message.as_bytes()).decode('utf-8')

        service.users().messages().send(
            userId='me',
            body={'raw': raw_message}
        ).execute()

        return True

    except HttpError as e:
        # Gmail API returned an error. Log it for debugging, return False
        # so the view can handle it gracefully.
        import logging
        logger = logging.getLogger(__name__)
        logger.error(f"Gmail API HttpError sending to {to_email}: {e}")
        return False

    except Exception as e:
        # Something else exploded. Log it. Return False. Don't crash the server.
        import logging
        logger = logging.getLogger(__name__)
        logger.error(f"Unexpected error sending verification email to {to_email}: {e}")
        return False
