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

        html_body = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Invoice from Sunny Sioux Care</title>
        </head>
        <body style="font-family: Arial, sans-serif; color: #333; max-width: 600px; margin: 0 auto; background-color: #f5f5f5; padding: 20px;">
            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                <tr>
                    <td>
                        <div style="background: linear-gradient(to right, #f97316, #fbbf24); padding: 30px; text-align: center; border-radius: 8px 8px 0 0;">
                            <h1 style="color: white; margin: 0; font-size: 28px;">☀️ Sunny Sioux Care</h1>
                        </div>
                        
                        <div style="background-color: #ffffff; padding: 30px; border-radius: 0 0 8px 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
                            <h2 style="color: #f97316; margin-top: 0;">Your Invoice is Ready!</h2>
                            
                            <p style="line-height: 1.6;">Hello,</p>
                            <p style="line-height: 1.6;">Your invoice has been created successfully.</p>
                            
                            <table width="100%" cellpadding="20" cellspacing="0" style="background-color: #fff7ed; border-radius: 8px; margin: 20px 0; border-left: 4px solid #f97316;">
                                <tr>
                                    <td>
                                        <p style="margin: 5px 0;"><strong>Service:</strong> {description}</p>
                                        <p style="margin: 5px 0;"><strong>Amount:</strong> <span style="color: #f97316; font-size: 24px; font-weight: bold;">${amount:.2f}</span> USD</p>
                                    </td>
                                </tr>
                            </table>
                            
                            <table width="100%" cellpadding="30" cellspacing="0">
                                <tr>
                                    <td align="center">
                                        <a href="{invoice_url}" 
                                           style="background: linear-gradient(to right, #f97316, #fbbf24); 
                                                  color: #ffffff; 
                                                  padding: 15px 40px; 
                                                  text-decoration: none; 
                                                  border-radius: 25px; 
                                                  font-weight: bold;
                                                  font-size: 18px;
                                                  display: inline-block;
                                                  mso-padding-alt: 0;
                                                  text-align: center;">
                                            <!--[if mso]>
                                            <i style="mso-font-width: -100%; mso-text-raise: 30pt;">&nbsp;</i>
                                            <![endif]-->
                                            <span style="mso-text-raise: 15pt;">View & Pay Invoice →</span>
                                            <!--[if mso]>
                                            <i style="mso-font-width: -100%;">&nbsp;</i>
                                            <![endif]-->
                                        </a>
                                    </td>
                                </tr>
                            </table>
                            
                            <p style="color: #64748b; line-height: 1.6;">If you have any questions, please contact us at 
                               <a href="mailto:{self.admin_email}" style="color: #f97316; text-decoration: none;">{self.admin_email}</a>
                            </p>
                            
                            <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 30px 0;">
                            
                            <div style="text-align: center; color: #94a3b8; font-size: 12px;">
                                <p><strong>Sunny Sioux Care</strong></p>
                                <p>2110 Summit St, Unit B1<br>
                                Sioux City, IA 51104</p>
                                <p>{self.admin_email}</p>
                            </div>
                        </div>
                    </td>
                </tr>
            </table>
        </body>
        </html>
        """
                <div style="text-align: center; color: #94a3b8; font-size: 12px;">
                    <p><strong>Sunny Sioux Care</strong></p>
                    <p>2110 Summit St, Unit B1<br>
                    Sioux City, IA 51104</p>
                    <p>{self.admin_email}</p>
                </div>
            </div>
        </body>
        </html>
        """

        return self.send_email(customer_email, subject, body, html_body)
