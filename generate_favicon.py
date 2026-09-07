from PIL import Image
import os

# Input image path
input_path = "/Users/dragon/Downloads/640 (7).jpeg"
# Output favicon path
output_path = "/Users/dragon/Code/knowledge-base/wisdomsword.github.io/assets/favicon.ico"

# Sizes for favicon
favicon_sizes = [(16, 16), (32, 32), (48, 48), (64, 64)]

# Open the image
with Image.open(input_path) as img:
    # Create a list to hold resized images
    icon_sizes = []
    for size in favicon_sizes:
        # Resize the image with high quality
        resized = img.resize(size, Image.Resampling.LANCZOS)
        icon_sizes.append(resized)
    
    # Save as favicon.ico
    icon_sizes[0].save(
        output_path,
        format='ICO',
        append_images=icon_sizes[1:],
        sizes=[(s[0], s[1]) for s in favicon_sizes]
    )

print(f"Favicon saved to {output_path}")