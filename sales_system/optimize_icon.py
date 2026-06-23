from PIL import Image
import os

def analyze_ico_file(filepath):
    """Analyze the ICO file and print information about it"""
    try:
        # Open the ICO file
        img = Image.open(filepath)
        print(f"File: {filepath}")
        print(f"Format: {img.format}")
        print(f"Mode: {img.mode}")
        print(f"Size: {img.size}")
        
        # Get info about all frames in the ICO
        print(f"Number of frames: {img.n_frames}")
        
        # Print info for each frame
        for i in range(img.n_frames):
            img.seek(i)
            print(f"  Frame {i}: {img.size} - {img.mode}")
            
        img.seek(0)  # Reset to first frame
        return img
    except Exception as e:
        print(f"Error analyzing {filepath}: {e}")
        return None

def create_optimized_ico(input_path, output_path, sizes=[(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)]):
    """Create an optimized ICO file with reduced sizes"""
    try:
        # Open the original image
        img = Image.open(input_path)
        
        # Convert to RGBA if not already
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
        
        # Create a list to hold resized images
        resized_images = []
        
        # Resize to each target size
        for size in sizes:
            resized_img = img.resize(size, Image.Resampling.LANCZOS)
            resized_images.append(resized_img)
        
        # Save as ICO with multiple sizes
        resized_images[0].save(
            output_path,
            format='ICO',
            sizes=sizes
        )
        
        # Print file sizes
        original_size = os.path.getsize(input_path)
        new_size = os.path.getsize(output_path)
        reduction = ((original_size - new_size) / original_size) * 100
        
        print(f"Original size: {original_size:,} bytes")
        print(f"New size: {new_size:,} bytes")
        print(f"Size reduction: {reduction:.1f}%")
        
        return True
    except Exception as e:
        print(f"Error creating optimized ICO: {e}")
        return False

if __name__ == "__main__":
    input_file = "windows/runner/resources/app_icon.ico"
    output_file = "windows/runner/resources/app_icon_optimized.ico"
    
    print("Analyzing current ICO file...")
    img = analyze_ico_file(input_file)
    
    if img:
        print("\nCreating optimized ICO file...")
        success = create_optimized_ico(input_file, output_file)
        
        if success:
            print(f"\nOptimized ICO saved as {output_file}")
        else:
            print("Failed to create optimized ICO")
    else:
        print("Could not analyze the ICO file")