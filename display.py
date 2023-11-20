from PIL import Image, ImageDraw
import numpy as np

def pic():
    pixels = np.loadtxt("log.txt", dtype=int)

    # img = Image.new("RGB", (641, 10))
    img = Image.new("RGB", (201, 201))

    img1 = ImageDraw.Draw(img)

    for i in range(0,200):
        # 30 bit color
        # img1.rectangle([(i, 0), (i+1, 10)], fill = (int(pixels[i][0]/2), int(pixels[i][1]/2), int(pixels[i][2]/2)))

        # 10 bit color
        # img1.rectangle([(i, 0), (i+1, 10)], fill = (int(pixels[i][0]*64), int(pixels[i][1]*32), int(pixels[i][2]*64)))
        for j in range(0,200):
            img1.rectangle([(j, i), (j+1, i+1)], fill = (int(pixels[i*200+j][0]/4), int(pixels[i*200+j][1]/4), int(pixels[i*200+j][2]/4)))
    img.save("new.png", "PNG")

a = 0.299
b = 0.587
c = 0.114
d = 1.772
e = 1.402
def rgb2yuv(R, G, B):
    Y  = a * R + b * G + c * B
    Cb = (B - Y) / d
    Cr = (R - Y) / e
    print(Y, Cb, Cr)