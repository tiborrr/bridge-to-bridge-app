import csv
import math

def load_data(filename):
    data = {}
    with open(filename, 'r') as f:
        reader = csv.reader(f)
        next(reader)
        for row in reader:
            if not row or len(row) < 4: continue
            t = int(row[0])
            x, y, z = float(row[1]), float(row[2]), float(row[3])
            data[t] = (x, y, z)
    return data

accel = load_data('/Users/tiborcasteleijn/Repositories/bridge-to-bridge-app/test/input/lsm6dso_LSM6DSO_Accelerometer_Non-wakeup.csv')

times = sorted(list(accel.keys()))

accel_mags = []
for t in times:
    ax, ay, az = accel[t]
    mag = math.sqrt(ax*ax + ay*ay + az*az)
    accel_mags.append(mag)

mean_mag = sum(accel_mags) / len(accel_mags)
centered = [m - mean_mag for m in accel_mags]

peaks = []
min_peak_distance = 1000 # 1 second minimum
threshold = 2.0 # threshold for impact peak

last_peak_time = -min_peak_distance
for i in range(1, len(centered) - 1):
    if centered[i] > threshold and centered[i] > centered[i-1] and centered[i] > centered[i+1]:
        if times[i] - last_peak_time >= min_peak_distance:
            is_max = True
            for j in range(max(0, i - 20), min(len(centered), i + 20)):
                if centered[j] > centered[i]:
                    is_max = False
                    break
            if is_max:
                peaks.append(i) # save index
                last_peak_time = times[i]

print("Catch Angles (in degrees):")
for p in peaks:
    ax, ay, az = accel[times[p]]
    # Calculate angles assuming static gravity. Since there's impact acceleration, 
    # taking the value slightly BEFORE the peak might be more accurate for gravity tilt.
    # Let's take the value 50ms before the peak (about 20 samples at 400Hz).
    pre_p = max(0, p - 20)
    ax, ay, az = accel[times[pre_p]]
    
    pitch = math.atan2(ax, math.sqrt(ay*ay + az*az)) * 180 / math.pi
    roll = math.atan2(ay, az) * 180 / math.pi
    
    print(f"Time: {times[p]}, Pitch (X): {pitch:.1f}°, Roll (Y/Z): {roll:.1f}°")

