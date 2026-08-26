import asyncio
import websockets
import base64

async def test():
    try:
        async with websockets.connect("ws://localhost:8000/ws/detect") as websocket:
            print("Connected!")
            # Send a fake base64 image (1x1 pixel)
            fake_img = "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////wgALCAABAAEBAREA/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPxA="
            await websocket.send(fake_img)
            print("Sent fake image")
            response = await websocket.recv()
            print("Received response:", response)
    except Exception as e:
        print(f"Error: {e}")

asyncio.run(test())
