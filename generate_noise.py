import os
import random
try:
    from PIL import Image
except ImportError:
    os.system('pip install Pillow')
    from PIL import Image

width = 512
height = 512

img = Image.new('RGBA', (width, height))
pixels = img.load()

for y in range(height):
    for x in range(width):
        # Generate random grayscale noise with some transparency
        val = random.randint(0, 255)
        pixels[x, y] = (val, val, val, 25)  # low alpha for subtle grain

img.save('assets/images/noise.png')
print("Noise image generated at assets/images/noise.png")
