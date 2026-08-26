"""
Telegram Service Module for Smart Vision AI
Sends Telegram alerts when dangerous objects are detected
"""

import os
from typing import Optional, List
from datetime import datetime
import requests


class TelegramService:
    """
    Handles Telegram notifications for dangerous object detections.
    Supports sending text messages and images via Telegram Bot API.
    """
    
    def __init__(self):
        """Initialize the Telegram service."""
        self.bot_token = None
        self.chat_id = None
        self.enabled = False
        self.api_base_url = "https://api.telegram.org"
    
    def configure(self, bot_token: str, chat_id: str):
        """
        Configure Telegram bot credentials.
        
        Args:
            bot_token: Telegram bot token from BotFather
            chat_id: Telegram chat ID to send messages to
        """
        self.bot_token = bot_token
        self.chat_id = chat_id
        self.enabled = bool(bot_token and chat_id)
    
    def send_message(self, message: str) -> bool:
        """
        Send a text message via Telegram.
        
        Args:
            message: Text message to send
            
        Returns:
            True if message sent successfully, False otherwise
        """
        if not self.enabled:
            print("Telegram service not configured or disabled")
            return False
        
        try:
            url = f"{self.api_base_url}/bot{self.bot_token}/sendMessage"
            data = {
                "chat_id": self.chat_id,
                "text": message,
                "parse_mode": "HTML"
            }
            
            response = requests.post(url, data=data, timeout=10)
            response.raise_for_status()
            
            print("Telegram message sent successfully")
            return True
            
        except Exception as e:
            print(f"Failed to send Telegram message: {e}")
            return False
    
    def send_alert(self, object_name: str, confidence: float, 
                  image_path: Optional[str] = None) -> bool:
        """
        Send alert message for dangerous object detection.
        
        Args:
            object_name: Name of the detected dangerous object
            confidence: Detection confidence score
            image_path: Optional path to screenshot image
            
        Returns:
            True if alert sent successfully, False otherwise
        """
        if not self.enabled:
            print("Telegram service not configured or disabled")
            return False
        
        try:
            # Current timestamp
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            
            # Create alert message
            message = f"""
🚨 <b>Smart Vision AI Alert</b>

<b>Object:</b> {object_name}
<b>Confidence:</b> {confidence:.3f}
<b>Time:</b> {timestamp}

<i>Dangerous object detected!</i>
"""
            
            # Send text message
            if not self.send_message(message):
                return False
            
            # Send image if provided
            if image_path and os.path.exists(image_path):
                return self.send_photo(image_path)
            
            return True
            
        except Exception as e:
            print(f"Failed to send Telegram alert: {e}")
            return False
    
    def send_photo(self, photo_path: str, caption: Optional[str] = None) -> bool:
        """
        Send a photo via Telegram.
        
        Args:
            photo_path: Path to the image file
            caption: Optional caption for the photo
            
        Returns:
            True if photo sent successfully, False otherwise
        """
        if not self.enabled:
            return False
        
        try:
            url = f"{self.api_base_url}/bot{self.bot_token}/sendPhoto"
            
            with open(photo_path, 'rb') as photo:
                files = {'photo': photo}
                data = {'chat_id': self.chat_id}
                if caption:
                    data['caption'] = caption
                    data['parse_mode'] = 'HTML'
                
                response = requests.post(url, files=files, data=data, timeout=30)
                response.raise_for_status()
            
            print(f"Telegram photo sent successfully: {photo_path}")
            return True
            
        except Exception as e:
            print(f"Failed to send Telegram photo: {e}")
            return False
    
    def send_test_message(self) -> bool:
        """
        Send a test message to verify configuration.
        
        Returns:
            True if test message sent successfully
        """
        if not self.enabled:
            return False
        
        message = """
🧪 <b>Smart Vision AI - Test Message</b>

This is a test message to verify your Telegram configuration.

<i>If you received this, your Telegram service is working correctly!</i>
"""
        return self.send_message(message)
    
    def is_configured(self) -> bool:
        """
        Check if Telegram service is properly configured.
        
        Returns:
            True if configured and enabled
        """
        return self.enabled
    
    def get_bot_info(self) -> Optional[dict]:
        """
        Get bot information from Telegram API.
        
        Returns:
            Dictionary with bot information or None if failed
        """
        if not self.enabled:
            return None
        
        try:
            url = f"{self.api_base_url}/bot{self.bot_token}/getMe"
            response = requests.get(url, timeout=10)
            response.raise_for_status()
            return response.json().get('result')
        except Exception as e:
            print(f"Failed to get bot info: {e}")
            return None


# Global telegram service instance
_telegram_service: Optional[TelegramService] = None


def get_telegram_service() -> TelegramService:
    """
    Get or create the global telegram service instance.
    
    Returns:
        The global TelegramService instance
    """
    global _telegram_service
    if _telegram_service is None:
        _telegram_service = TelegramService()
    return _telegram_service
