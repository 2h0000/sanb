#!/usr/bin/env python3
"""
Simple icon generator for Encrypted Notebook app
Requires: pip install pillow
"""

try:
    from PIL import Image, ImageDraw
    import os
except ImportError:
    print("Error: Pillow library not found.")
    print("Install it with: pip install pillow")
    exit(1)

# Colors
BG_COLOR = (26, 26, 46)  # #1A1A2E
WHITE = (255, 255, 255)
GREEN = (76, 175, 80)  # #4CAF50

def draw_notebook(draw, x, y, size, color):
    """Draw a simple notebook icon"""
    # Book body
    left = x - size // 2
    top = y - size // 2
    right = x + size // 2
    bottom = y + size // 2
    
    draw.rectangle([left, top, right, bottom], fill=color, outline=color)
    
    # Spine shadow
    spine_width = size // 10
    draw.rectangle([left, top, left + spine_width, bottom], 
                   fill=(200, 200, 200), outline=(200, 200, 200))
    
    # Page lines
    line_spacing = size // 6
    line_width = int(size * 0.6)
    line_height = size // 25
    
    for i in range(3):
        line_y = y + (i - 1) * line_spacing
        line_left = left + size // 5
        draw.rectangle([line_left, line_y - line_height // 2, 
                       line_left + line_width, line_y + line_height // 2],
                      fill=(230, 230, 230))

def draw_lock_badge(draw, x, y, size):
    """Draw a lock badge"""
    # Badge circle
    draw.ellipse([x - size, y - size, x + size, y + size], 
                 fill=GREEN, outline=GREEN)
    
    # Lock body
    lock_width = size // 2
    lock_height = int(size * 0.6)
    lock_left = x - lock_width // 2
    lock_top = y - lock_height // 4
    
    draw.rectangle([lock_left, lock_top, 
                   lock_left + lock_width, lock_top + lock_height // 2],
                  fill=WHITE)
    
    # Lock shackle (simplified as arc)
    shackle_size = lock_width // 3
    shackle_thickness = size // 7
    draw.arc([x - shackle_size, y - lock_height // 2 - shackle_size,
              x + shackle_size, y - lock_height // 4],
             180, 0, fill=WHITE, width=shackle_thickness)
    
    # Keyhole
    keyhole_size = size // 8
    draw.ellipse([x - keyhole_size, y - keyhole_size,
                  x + keyhole_size, y + keyhole_size],
                 fill=GREEN)

def generate_app_icon(size=1024):
    """Generate main app icon with background"""
    img = Image.new('RGB', (size, size), BG_COLOR)
    draw = ImageDraw.Draw(img)
    
    # Draw notebook
    notebook_size = int(size * 0.4)
    draw_notebook(draw, size // 2, size // 2, notebook_size, WHITE)
    
    # Draw lock badge
    badge_x = int(size * 0.7)
    badge_y = int(size * 0.7)
    badge_size = int(size * 0.075)
    draw_lock_badge(draw, badge_x, badge_y, badge_size)
    
    return img

def generate_foreground_icon(size=1024):
    """Generate foreground icon with transparency"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Draw notebook
    notebook_size = int(size * 0.4)
    draw_notebook(draw, size // 2, size // 2, notebook_size, WHITE)
    
    # Draw lock badge
    badge_x = int(size * 0.7)
    badge_y = int(size * 0.7)
    badge_size = int(size * 0.075)
    draw_lock_badge(draw, badge_x, badge_y, badge_size)
    
    return img

def generate_splash_icon(size=512):
    """Generate splash screen icon"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Draw notebook (slightly larger for splash)
    notebook_size = int(size * 0.35)
    draw_notebook(draw, size // 2, size // 2, notebook_size, WHITE)
    
    # Draw lock badge
    badge_x = int(size * 0.68)
    badge_y = int(size * 0.68)
    badge_size = int(size * 0.09)
    draw_lock_badge(draw, badge_x, badge_y, badge_size)
    
    return img

def main():
    """Generate all icon files"""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    print("🎨 Generating Encrypted Notebook icons...")
    
    # Generate app icon
    print("  📱 Generating app_icon.png (1024x1024)...")
    app_icon = generate_app_icon(1024)
    app_icon.save(os.path.join(script_dir, 'app_icon.png'))
    
    # Generate foreground icon
    print("  🎭 Generating app_icon_foreground.png (1024x1024)...")
    foreground_icon = generate_foreground_icon(1024)
    foreground_icon.save(os.path.join(script_dir, 'app_icon_foreground.png'))
    
    # Generate splash icon
    print("  💫 Generating splash_icon.png (512x512)...")
    splash_icon = generate_splash_icon(512)
    splash_dir = os.path.join(os.path.dirname(script_dir), 'splash')
    os.makedirs(splash_dir, exist_ok=True)
    splash_icon.save(os.path.join(splash_dir, 'splash_icon.png'))
    
    print("✅ All icons generated successfully!")
    print("\nNext steps:")
    print("  1. Run: flutter pub get")
    print("  2. Run: flutter pub run flutter_launcher_icons")
    print("  3. Run: flutter pub run flutter_native_splash:create")
    print("  4. Run: flutter run")

if __name__ == '__main__':
    main()
