import numpy as np
from PIL import Image

rgb2ycbcr_coeff = np.array([[0.299, 0.587, 0.114],
                          [-0.169, -0.331, 0.5],
                          [0.5, -0.419, -0.081]])

ycbcr2rgb_coeff = np.array([[1.000, 0.000, 1.400],
                          [1.000, -0.343, -0.711],
                          [1.000, 1.765, 0.000]])

def rgb2yuv(rgb):
    rgb = rgb.transpose()
    yuv = np.matmul(rgb2ycbcr_coeff, rgb)
    yuv = yuv + np.array([0, 128, 128]).transpose()
    yuv = yuv.astype(np.uint8)
    return yuv

def yuv2rgb(yuv):
    yuv = yuv - np.array([0, 128, 128])
    yuv = yuv.transpose()
    rgb = np.matmul(ycbcr2rgb_coeff, yuv)
    rgb = rgb.astype(np.uint8)
    return rgb

img_rgb = np.asarray(Image.open("testimg.jpg"))
img_rgb_conv = np.zeros(img_rgb.shape, dtype=np.uint8)
img_rgb_trunc = np.zeros(img_rgb.shape, dtype=np.uint8)
img_rgb_original = np.zeros(img_rgb.shape, dtype=np.uint8)

for i in range(img_rgb.shape[0]):
    for j in range(img_rgb.shape[1]):
        img_yuv = rgb2yuv(img_rgb[i][j])

        img_yuv = np.array([img_yuv[0]/16, img_yuv[1]/16, img_yuv[2]/16], dtype=np.uint8)
        img_yuv = np.array([img_yuv[0]*16, img_yuv[1]*16, img_yuv[2]*16], dtype=np.uint8)
        img_rgb_conv[i][j] = yuv2rgb(img_yuv)

        img_rgb_pixel = img_rgb[i][j]
        img_rgb_pixel = np.array([img_rgb_pixel[0]/32, img_rgb_pixel[1]/32, img_rgb_pixel[2]/64], dtype=np.uint8)
        img_rgb_pixel = np.array([img_rgb_pixel[0]*32, img_rgb_pixel[1]*32, img_rgb_pixel[2]*64], dtype=np.uint8)
        img_rgb_trunc[i][j] = img_rgb_pixel

Image.fromarray(img_rgb_conv, 'RGB').save("testimg_converted.png", "PNG")
Image.fromarray(img_rgb_trunc, 'RGB').save("testimg_truncated.png", "PNG")
