import time
from typing import Dict, List, Optional, Any
from datetime import datetime

class AlertManager:
    """
    Centralized manager for all alerts (Security, Restricted Zone, Missing Object, etc.)
    Handles debounce/cooldown to prevent UI and notification spam.
    """
    def __init__(self, cooldown_seconds: float = 10.0):
        self.cooldown_seconds = cooldown_seconds
        self.last_alert_times: Dict[str, float] = {}
        self.alert_history: List[Dict[str, Any]] = []
        
    def _can_trigger(self, alert_key: str) -> bool:
        current_time = time.time()
        last_time = self.last_alert_times.get(alert_key, 0.0)
        if current_time - last_time >= self.cooldown_seconds:
            self.last_alert_times[alert_key] = current_time
            return True
        return False
        
    def trigger_alert(self, event_type: str, object_name: str, message: str, severity: str = 'warning') -> Optional[Dict[str, Any]]:
        """
        Attempts to trigger an alert. If it's on cooldown, returns None.
        Otherwise, returns the alert payload and logs it to history.
        """
        # Create a unique key for the cooldown based on event type and object
        alert_key = f"{event_type}_{object_name}"
        
        if self._can_trigger(alert_key):
            alert = {
                'timestamp': datetime.now().strftime("%Y-%m-%d %I:%M:%S %p"),
                'event_type': event_type,
                'object_class': object_name,
                'severity': severity,
                'message': message
            }
            self.alert_history.insert(0, alert)
            # Keep history bounded
            if len(self.alert_history) > 100:
                self.alert_history.pop()
            return alert
            
        return None
        
    def get_recent_alerts(self, limit: int = 5) -> List[Dict[str, Any]]:
        return self.alert_history[:limit]
