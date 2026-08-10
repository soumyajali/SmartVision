export interface Detection {
  id: string;
  label: string;
  confidence: number;
  x: number; // 0-1
  y: number; // 0-1
  width: number;
  height: number;
}

export interface Analytics {
  fps: number;
  latency: number;
  avgConfidence: number;
  totalFrames: number;
  counts: Record<string, number>;
}

export interface Alert {
  id: string;
  target: string;
  confidence: number;
  timestamp: Date;
}

class VisionApiService {
  private socket: WebSocket | null = null;
  private isRunning: boolean = false;

  private onDetectionCallback: ((detections: Detection[]) => void) | null = null;
  private onAnalyticsCallback: ((analytics: Analytics) => void) | null = null;

  startDetection() {
    this.isRunning = true;
    
    // Use the current hostname to support network access
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const host = window.location.hostname;
    this.socket = new WebSocket(`${protocol}//${host}:8000/ws/detect`);

    this.socket.onopen = () => {
      console.log('Connected to FastAPI Vision backend');
    };

    this.socket.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        if (data.detections && this.onDetectionCallback) {
          this.onDetectionCallback(data.detections);
        }
        if (data.analytics && this.onAnalyticsCallback) {
          this.onAnalyticsCallback(data.analytics);
        }
      } catch (err) {
        console.error('Error parsing detection data:', err);
      }
    };

    this.socket.onerror = (error) => {
      console.error('WebSocket Error:', error);
    };

    this.socket.onclose = () => {
      console.log('Disconnected from FastAPI Vision backend');
      if (this.isRunning) {
        console.log('Attempting to reconnect in 2 seconds...');
        setTimeout(() => this.startDetection(), 2000);
      }
    };
  }

  stopDetection() {
    this.isRunning = false;
    if (this.socket) {
      this.socket.close();
      this.socket = null;
    }
  }

  isSocketOpen() {
    return this.socket?.readyState === WebSocket.OPEN;
  }

  sendFrame(base64Frame: string) {
    if (this.isSocketOpen()) {
      this.socket?.send(base64Frame);
    }
  }

  onDetection(callback: (detections: Detection[]) => void) {
    this.onDetectionCallback = callback;
  }

  onAnalytics(callback: (analytics: Analytics) => void) {
    this.onAnalyticsCallback = callback;
  }
}

export const visionApi = new VisionApiService();
