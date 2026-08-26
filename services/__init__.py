"""
Services module for Smart Vision AI
Contains email, telegram, voice, and backup services
"""

from .email_service import EmailService, get_email_service
from .telegram_service import TelegramService, get_telegram_service

__all__ = ['EmailService', 'get_email_service', 'TelegramService', 'get_telegram_service']
