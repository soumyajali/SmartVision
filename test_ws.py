import asyncio
import websockets

async def test():
    try:
        async with websockets.connect("ws://localhost:8000/ws/detect") as websocket:
            print("Connected!")
            await websocket.send("test_data")
            print("Sent data")
    except Exception as e:
        print(f"Error: {e}")

asyncio.run(test())
