import subprocess
import time
import os
from pynput import mouse

# Yapılandırma
THRESHOLD = 200  # Köşe hassasiyeti (piksel)
SEQUENCE_ACTIONS = {
    ('top_right', 'top_left', 'bottom_center'): 'stop',
    ('top_left', 'top_right', 'bottom_center'): 'start',
}
current_sequence = []

def get_screen_size():
    """Ekran çözünürlüğünü xrandr kullanarak alır."""
    try:
        output = subprocess.check_output("xrandr | grep '*' | awk '{print $1}'", shell=True).decode().strip().split('\n')[0]
        if 'x' in output:
            width, height = map(int, output.split('x'))
            return width, height
    except Exception as e:
        print(f"Ekran çözünürlüğü alınamadı: {e}")
    return 1920, 1080  # Varsayılan

WIDTH, HEIGHT = get_screen_size()

def get_region(x, y):
    """Tıklanan koordinatın hangi bölgede olduğunu belirler."""
    if x > (WIDTH - THRESHOLD) and y < THRESHOLD:
        return 'top_right'
    if x < THRESHOLD and y < THRESHOLD:
        return 'top_left'
    if abs(x - (WIDTH // 2)) < THRESHOLD and y > (HEIGHT - THRESHOLD):
        return 'bottom_center'
    return None

def trigger_action(action):
    """Komutu çalıştırır."""
    print(f"Sıralama tamamlandı! mcnd.service {action} ediliyor...")
    try:
        process = subprocess.run(["sudo", "/bin/systemctl", action, "mcnd.service"],
                                 capture_output=True, text=True)
        if process.returncode == 0:
            print(f"BAŞARILI: mcnd.service {action} edildi.")
        else:
            print(f"HATA: {process.stderr}")
    except Exception as e:
        print(f"Hata: {e}")

def on_click(x, y, button, pressed):
    global current_sequence
    if pressed and button == mouse.Button.left:
        region = get_region(x, y)
        if region:
            current_sequence.append(region)
            print(f"Bölge algılandı: {region}")
            
            if len(current_sequence) > 3:
                current_sequence.pop(0)
            
            if tuple(current_sequence) in SEQUENCE_ACTIONS:
                action = SEQUENCE_ACTIONS[tuple(current_sequence)]
                trigger_action(action)
                current_sequence = []

print(f"İzleme başladı... ({WIDTH}x{HEIGHT})")
with mouse.Listener(on_click=on_click) as listener:
    listener.join()
