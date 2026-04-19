import PIL.Image as Image
import PIL.ImageChops as ImageChops
import os

def trim(im):
    # Use alpha channel if it exists, otherwise use the corner pixel as background color
    if im.mode == 'RGBA':
        bbox = im.getbbox()
    else:
        # Assuming the background is the color of the top-left pixel
        bg = Image.new(im.mode, im.size, im.getpixel((0,0)))
        diff = ImageChops.difference(im, bg)
        diff = ImageChops.add(diff, diff, 2.0, -100)
        bbox = diff.getbbox()
    
    if bbox:
        return im.crop(bbox)
    return im

def make_transparent(im, background_color=None):
    im = im.convert("RGBA")
    if background_color is None:
        background_color = im.getpixel((0,0))
    
    datas = im.getdata()
    newData = []
    for item in datas:
        # If the pixel is very close to the background color, make it transparent
        if abs(item[0] - background_color[0]) < 10 and \
           abs(item[1] - background_color[1]) < 10 and \
           abs(item[2] - background_color[2]) < 10:
            newData.append((255, 255, 255, 0))
        else:
            newData.append(item)
    
    im.putdata(newData)
    return im

assets_path = r"e:\Non_Office\Dev_Space\vibe_skool\kloudShop\frontend\assets"
logos = ["logo.png", "logo_dark.png"]

for logo_name in logos:
    path = os.path.join(assets_path, logo_name)
    if os.path.exists(path):
        print(f"Processing {logo_name}...")
        img = Image.open(path)
        
        # 1. Make transparent (if it's not already)
        img = make_transparent(img)
        
        # 2. Trim whitespace
        img = trim(img)
        
        # 3. Save as PNG
        img.save(path, "PNG")
        print(f"Saved {logo_name} (Size: {img.size})")
