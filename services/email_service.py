"""
Email Service Module for Smart Vision AI
Sends email alerts when dangerous objects are detected
"""

import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.image import MIMEImage
from typing import Optional, List
import os
from datetime import datetime
import cv2


class EmailService:
    """
    Handles email notifications for dangerous object detections.
    Supports SMTP email sending with image attachments.
    """
    
    def __init__(self, smtp_server: str = "smtp.gmail.com", smtp_port: int = 587):
        """
        Initialize the email service.
        
        Args:
            smtp_server: SMTP server address
            smtp_port: SMTP server port
        """
        self.smtp_server = smtp_server
        self.smtp_port = smtp_port
        self.sender_email = None
        self.sender_password = None
        self.recipient_emails = []
        self.enabled = False
    
    def configure(self, sender_email: str, sender_password: str, 
                  recipient_emails: List[str]):
        """
        Configure email credentials and recipients.
        
        Args:
            sender_email: Email address to send from
            sender_password: Email password or app password
            recipient_emails: List of recipient email addresses
        """
        self.sender_email = sender_email
        self.sender_password = sender_password
        self.recipient_emails = recipient_emails
        self.enabled = bool(sender_email and sender_password and recipient_emails)
    
    def send_alert(self, object_name: str, confidence: float, 
                  image_path: Optional[str] = None) -> bool:
        """
        Send email alert for dangerous object detection.
        
        Args:
            object_name: Name of the detected dangerous object
            confidence: Detection confidence score
            image_path: Optional path to screenshot image
            
        Returns:
            True if email sent successfully, False otherwise
        """
        if not self.enabled:
            print("Email service not configured or disabled")
            return False
        
        try:
            # Create message
            msg = MIMEMultipart()
            msg['From'] = self.sender_email
            msg['To'] = ', '.join(self.recipient_emails)
            msg['Subject'] = f"🚨 Smart Vision AI Alert - {object_name} Detected"
            
            # Current timestamp
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            
            # Email body
            body = f"""
            <html>
            <body>
                <h2>🚨 Smart Vision AI - Dangerous Object Alert</h2>
                <p><b>Object Detected:</b> {object_name}</p>
                <p><b>Confidence:</b> {confidence:.3f}</p>
                <p><b>Date:</b> {timestamp}</p>
                <p><i>This is an automated alert from Smart Vision AI.</i></p>
            </body>
            </html>
            """
            
            msg.attach(MIMEText(body, 'html'))
            
            # Attach image if provided
            if image_path and os.path.exists(image_path):
                with open(image_path, 'rb') as f:
                    img_data = f.read()
                image = MIMEImage(img_data, name=os.path.basename(image_path))
                msg.attach(image)
            
            # Send email
            with smtplib.SMTP(self.smtp_server, self.smtp_port) as server:
                server.starttls()
                server.login(self.sender_email, self.sender_password)
                server.sendmail(self.sender_email, self.recipient_emails, msg.as_string())
            
            print(f"Email alert sent successfully for {object_name}")
            return True
            
        except Exception as e:
            print(f"Failed to send email alert: {e}")
            return False
    
    def send_test_email(self) -> bool:
        """
        Send a test email to verify configuration.
        
        Returns:
            True if test email sent successfully
        """
        if not self.enabled:
            return False
        
        try:
            msg = MIMEMultipart()
            msg['From'] = self.sender_email
            msg['To'] = ', '.join(self.recipient_emails)
            msg['Subject'] = "🧪 Smart Vision AI - Test Email"
            
            body = """
            <html>
            <body>
                <h2>🧪 Smart Vision AI - Test Email</h2>
                <p>This is a test email to verify your email configuration.</p>
                <p><i>If you received this, your email service is working correctly!</i></p>
            </body>
            </html>
            """
            
            msg.attach(MIMEText(body, 'html'))
            
            with smtplib.SMTP(self.smtp_server, self.smtp_port) as server:
                server.starttls()
                server.login(self.sender_email, self.sender_password)
                server.sendmail(self.sender_email, self.recipient_emails, msg.as_string())
            
            print("Test email sent successfully")
            return True
            
        except Exception as e:
            print(f"Failed to send test email: {e}")
            return False
    
    def is_configured(self) -> bool:
        """
        Check if email service is properly configured.
        
        Returns:
            True if configured and enabled
        """
        return self.enabled


# Global email service instance
_email_service: Optional[EmailService] = None


def get_email_service() -> EmailService:
    """
    Get or create the global email service instance.
    
    Returns:
        The global EmailService instance
    """
    global _email_service
    if _email_service is None:
        _email_service = EmailService()
    return _email_service
