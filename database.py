"""
Database Module for Smart Vision AI
Manages SQLite database for detection history storage and retrieval
"""

import sqlite3
import os
from datetime import datetime
from typing import List, Dict, Optional
import json


class DetectionDatabase:
    """
    Manages SQLite database operations for detection history.
    Stores object detections with confidence, timestamp, and optional image path.
    """
    
    def __init__(self, db_path: str = "detections.db"):
        """
        Initialize the database connection and create tables if they don't exist.
        
        Args:
            db_path: Path to the SQLite database file
        """
        self.db_path = db_path
        self._initialize_database()
    
    def _initialize_database(self):
        """Create the detections table if it doesn't exist."""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS detections (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    object_name TEXT NOT NULL,
                    confidence REAL NOT NULL,
                    date TEXT NOT NULL,
                    time TEXT NOT NULL,
                    image_path TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            conn.commit()
    
    def add_detection(self, object_name: str, confidence: float, 
                     image_path: Optional[str] = None) -> int:
        """
        Add a detection record to the database.
        
        Args:
            object_name: Name of the detected object
            confidence: Detection confidence score (0.0 to 1.0)
            image_path: Optional path to the detection image
            
        Returns:
            The ID of the inserted record
        """
        now = datetime.now()
        date_str = now.strftime("%Y-%m-%d")
        time_str = now.strftime("%H:%M:%S")
        
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("""
                INSERT INTO detections (object_name, confidence, date, time, image_path)
                VALUES (?, ?, ?, ?, ?)
            """, (object_name, confidence, date_str, time_str, image_path))
            conn.commit()
            return cursor.lastrowid
    
    def get_all_detections(self) -> List[Dict]:
        """
        Retrieve all detection records from the database.
        
        Returns:
            List of detection dictionaries
        """
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM detections ORDER BY created_at DESC")
            rows = cursor.fetchall()
            return [dict(row) for row in rows]
    
    def get_detection_by_id(self, detection_id: int) -> Optional[Dict]:
        """
        Retrieve a specific detection record by ID.
        
        Args:
            detection_id: The ID of the detection record
            
        Returns:
            Detection dictionary or None if not found
        """
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM detections WHERE id = ?", (detection_id,))
            row = cursor.fetchone()
            return dict(row) if row else None
    
    def delete_detection(self, detection_id: int) -> bool:
        """
        Delete a detection record by ID.
        
        Args:
            detection_id: The ID of the detection record to delete
            
        Returns:
            True if deleted, False if not found
        """
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("DELETE FROM detections WHERE id = ?", (detection_id,))
            conn.commit()
            return cursor.rowcount > 0
    
    def clear_all_detections(self) -> int:
        """
        Delete all detection records from the database.
        
        Returns:
            Number of records deleted
        """
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT COUNT(*) FROM detections")
            count = cursor.fetchone()[0]
            cursor.execute("DELETE FROM detections")
            conn.commit()
            return count
    
    def search_detections(self, query: str) -> List[Dict]:
        """
        Search detection records by object name.
        
        Args:
            query: Search query string
            
        Returns:
            List of matching detection dictionaries
        """
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            cursor.execute("""
                SELECT * FROM detections 
                WHERE object_name LIKE ? 
                ORDER BY created_at DESC
            """, (f"%{query}%",))
            rows = cursor.fetchall()
            return [dict(row) for row in rows]
    
    def get_detections_by_date(self, date: str) -> List[Dict]:
        """
        Retrieve all detection records for a specific date.
        
        Args:
            date: Date string in format "YYYY-MM-DD"
            
        Returns:
            List of detection dictionaries for the specified date
        """
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            cursor.execute("""
                SELECT * FROM detections 
                WHERE date = ? 
                ORDER BY created_at DESC
            """, (date,))
            rows = cursor.fetchall()
            return [dict(row) for row in rows]
    
    def get_detection_stats(self) -> Dict:
        """
        Get statistics about detection records.
        
        Returns:
            Dictionary containing detection statistics
        """
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            
            # Total detections
            cursor.execute("SELECT COUNT(*) FROM detections")
            total_detections = cursor.fetchone()[0]
            
            # Today's detections
            today = datetime.now().strftime("%Y-%m-%d")
            cursor.execute("SELECT COUNT(*) FROM detections WHERE date = ?", (today,))
            today_detections = cursor.fetchone()[0]
            
            # Most detected object
            cursor.execute("""
                SELECT object_name, COUNT(*) as count 
                FROM detections 
                GROUP BY object_name 
                ORDER BY count DESC 
                LIMIT 1
            """)
            most_detected = cursor.fetchone()
            most_detected_object = most_detected[0] if most_detected else None
            most_detected_count = most_detected[1] if most_detected else 0
            
            # Average confidence
            cursor.execute("SELECT AVG(confidence) FROM detections")
            avg_confidence = cursor.fetchone()[0] or 0.0
            
            return {
                "total_detections": total_detections,
                "today_detections": today_detections,
                "most_detected_object": most_detected_object,
                "most_detected_count": most_detected_count,
                "average_confidence": round(avg_confidence, 3)
            }
    
    def get_object_counts(self) -> Dict[str, int]:
        """
        Get count of detections grouped by object name.
        
        Returns:
            Dictionary mapping object names to their detection counts
        """
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("""
                SELECT object_name, COUNT(*) as count 
                FROM detections 
                GROUP BY object_name 
                ORDER BY count DESC
            """)
            return {row[0]: row[1] for row in cursor.fetchall()}
    
    def get_detection_timeline(self, days: int = 7) -> List[Dict]:
        """
        Get detection count timeline for the last N days.
        
        Args:
            days: Number of days to include in the timeline
            
        Returns:
            List of dictionaries with date and count
        """
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("""
                SELECT date, COUNT(*) as count 
                FROM detections 
                WHERE date >= date('now', '-' || ? || ' days')
                GROUP BY date 
                ORDER BY date ASC
            """, (str(days),))
            return [{"date": row[0], "count": row[1]} for row in cursor.fetchall()]


# Global database instance
_database: Optional[DetectionDatabase] = None


def get_database() -> DetectionDatabase:
    """
    Get or create the global database instance.
    
    Returns:
        The global DetectionDatabase instance
    """
    global _database
    if _database is None:
        _database = DetectionDatabase()
    return _database
