export interface Detection {
  id: string;
  name: string;
  confidence: number;
  bbox: [number, number, number, number]; // [x, y, width, height]
  timestamp: string;
  status: 'VERIFIED' | 'WARNING' | 'ALERT' | 'RESOLVED';
  color: string;
}

export const mockDetections: Detection[] = [
  {
    id: 'det_001',
    name: 'Person',
    confidence: 98.4,
    bbox: [120, 50, 200, 400],
    timestamp: '10:42:18',
    status: 'VERIFIED',
    color: '#06b6d4', // Cyan
  },
  {
    id: 'det_002',
    name: 'Bottle',
    confidence: 94.1,
    bbox: [400, 300, 50, 150],
    timestamp: '10:42:15',
    status: 'VERIFIED',
    color: '#06b6d4',
  },
  {
    id: 'det_003',
    name: 'Laptop',
    confidence: 91.7,
    bbox: [250, 250, 300, 200],
    timestamp: '10:42:11',
    status: 'VERIFIED',
    color: '#06b6d4',
  },
  {
    id: 'det_004',
    name: 'Knife',
    confidence: 94.8,
    bbox: [600, 400, 100, 50],
    timestamp: '10:42:18',
    status: 'ALERT',
    color: '#ef4444', // Red
  }
];

export const mockAnalytics = {
  totalDetections: 18392,
  avgConfidence: 94.2,
  avgFps: 31,
  processingLatency: 32, // ms
  detectionFrequency: [
    { time: '10:30', count: 45 },
    { time: '10:35', count: 52 },
    { time: '10:40', count: 61 },
    { time: '10:45', count: 38 },
    { time: '10:50', count: 74 },
    { time: '10:55', count: 81 },
  ],
  objectsDetected: [
    { name: 'Person', count: 124 },
    { name: 'Bottle', count: 78 },
    { name: 'Laptop', count: 54 },
    { name: 'Phone', count: 37 },
    { name: 'Chair', count: 29 },
  ]
};
