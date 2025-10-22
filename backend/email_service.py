import os
import smtplib
import logging
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from typing import Optional

logger = logging.getLogger(__name__)


class EmailService:
    def __init__(self):
        self.smtp_host = os.environ.get('SMTP_HOST', 'smtp.gmail.com')
        self.smtp_port = int(os.environ.get('SMTP_PORT', '587'))
        self.smtp_user = os.environ.get('SMTP_USER', '')
        self.smtp_password = os.environ.get('SMTP_PASSWORD', '')
        self.from_email = os.environ.get('FROM_EMAIL', 'noreply@sunnysiouxcare.com')
        self.from_name = "Sunny Sioux Care"
        self.admin_email = os.environ.get('ADMIN_EMAIL', 'info@sunnysiouxcare.com')
        self.email_enabled = os.environ.get('EMAIL_ENABLED', 'false').lower() == 'true'

    def send_email(
        self, 
        to_email: str, 
        subject: str, 
        body: str,
        html_body: Optional[str] = None
    ) -> bool:
        """Send email via SMTP"""
        if not self.email_enabled:
            logger.info(f"Email disabled. Would send to {to_email}: {subject}")
            return True
        
        if not self.smtp_user or not self.smtp_password:
            logger.warning("SMTP credentials not configured")
            return False

        try:
            msg = MIMEMultipart('alternative')
            msg['From'] = f"{self.from_name} <{self.from_email}>"
            msg['To'] = to_email
            msg['Subject'] = subject

            # Attach text version
            text_part = MIMEText(body, 'plain')
            msg.attach(text_part)

            # Attach HTML version if provided
            if html_body:
                html_part = MIMEText(html_body, 'html')
                msg.attach(html_part)

            # Connect to SMTP server
            with smtplib.SMTP(self.smtp_host, self.smtp_port) as server:
                server.starttls()
                server.login(self.smtp_user, self.smtp_password)
                server.send_message(msg)

            logger.info(f"Email sent successfully to {to_email}")
            return True

        except Exception as e:
            logger.error(f"Failed to send email: {str(e)}")
            return False

    def send_contact_notification(
        self, 
        name: str, 
        email: str, 
        phone: str, 
        message: str
    ) -> bool:
        """Send notification about new contact form submission"""
        subject = f"New Contact Form Submission from {name}"
        
        body = f"""
New contact form submission received:

Name: {name}
Email: {email}
Phone: {phone or 'Not provided'}

Message:
{message}

---
This is an automated notification from SunnySiouxCare.com
        """

        html_body = f"""
        <html>
        <body style="font-family: Arial, sans-serif; color: #333;">
            <h2 style="color: #f97316;">New Contact Form Submission</h2>
            <div style="background-color: #fff7ed; padding: 20px; border-radius: 8px; border-left: 4px solid #f97316;">
                <p><strong>Name:</strong> {name}</p>
                <p><strong>Email:</strong> <a href="mailto:{email}">{email}</a></p>
                <p><strong>Phone:</strong> {phone or 'Not provided'}</p>
                <hr style="border: none; border-top: 1px solid #fed7aa; margin: 20px 0;">
                <p><strong>Message:</strong></p>
                <p style="background-color: white; padding: 15px; border-radius: 4px;">{message}</p>
            </div>
            <p style="color: #94a3b8; font-size: 12px; margin-top: 30px;">
                This is an automated notification from SunnySiouxCare.com
            </p>
        </body>
        </html>
        """

        return self.send_email(self.admin_email, subject, body, html_body)

    def send_invoice_confirmation(
        self, 
        customer_email: str, 
        description: str, 
        amount: float,
        invoice_url: str
    ) -> bool:
        """Send invoice confirmation to customer"""
        subject = "Your Invoice from Sunny Sioux Care"
        
        body = f"""
Hello,

Your invoice has been created successfully!

Service: {description}
Amount: ${amount:.2f} USD

Please click the link below to view and pay your invoice:
{invoice_url}

If you have any questions, please contact us at {self.admin_email}

Thank you for choosing Sunny Sioux Care!

---
Sunny Sioux Care
2110 Summit St, Unit B1
Sioux City, IA 51104
{self.admin_email}
        """

        html_body = f"""<html><body style="font-family:Arial;padding:20px;max-width:600px;">
<div style="background:#f97316;color:#fff;padding:20px;text-align:center;border-radius:8px;margin-bottom:20px;">
<h1 style="margin:0;">☀️ Sunny Sioux Care</h1>
</div>
<h2 style="color:#f97316;">Invoice ${amount:.2f} USD</h2>
<p><strong>Service:</strong> {description}</p>
<div style="text-align:center;margin:30px 0;">
<a href="{invoice_url}" style="background:#f97316;color:#fff;padding:15px 40px;text-decoration:none;border-radius:5px;font-weight:bold;font-size:18px;display:inline-block;">PAY INVOICE NOW</a>
</div>
<p>Thank you for choosing Sunny Sioux Care!</p>
<hr style="border:1px solid #eee;margin:20px 0;">
<p style="font-size:12px;color:#666;">Sunny Sioux Care | 2110 Summit St, Sioux City, IA 51104</p>
<p style="font-size:12px;color:#666;">Questions? {self.admin_email}</p>
</body></html>"""

        return self.send_email(customer_email, subject, body, html_body)
