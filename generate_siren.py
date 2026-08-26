import math
import wave
import struct

def generate_siren(filename="siren.wav", duration=2.0, sample_rate=44100):
    # Ambulance Hi-Lo siren (960Hz and 700Hz alternating every 0.5s)
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        
        for i in range(int(sample_rate * duration)):
            # Determine current frequency
            t = i / sample_rate
            freq = 960 if (t % 1.0) < 0.5 else 700
            
            # Generate square wave
            value = 1.0 if math.sin(2.0 * math.pi * freq * t) > 0 else -1.0
            
            # Volume envelope (fade out at the end)
            vol = 0.5
            if t > duration - 0.1:
                vol *= (duration - t) / 0.1
                
            sample = int(value * vol * 32767.0)
            wav_file.writeframes(struct.pack('h', sample))

generate_siren()
print("Generated siren.wav")
