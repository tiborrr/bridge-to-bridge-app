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
gyro = load_data('/Users/tiborcasteleijn/Repositories/bridge-to-bridge-app/test/input/lsm6dso_LSM6DSO_Gyroscope_Non-wakeup.csv')

# Find common timestamps
common_t = sorted(list(set(accel.keys()).intersection(set(gyro.keys()))))

print(f"Total synchronized samples: {len(common_t)}")
if not common_t:
    print("No common timestamps found.")
    exit()

# We need to find the "catch".
# A catch is typically characterized by a sudden change in acceleration (impact with water)
# and a change in direction of rotation (blade entering and pulling).
# Let's find the peaks in accelerometer magnitude to mark strokes.
times = []
accel_mags = []
gyro_vals = []

for t in common_t:
    ax, ay, az = accel[t]
    gx, gy, gz = gyro[t]
    mag = math.sqrt(ax*ax + ay*ay + az*az)
    times.append(t)
    accel_mags.append(mag)
    gyro_vals.append((gx, gy, gz))

mean_mag = sum(accel_mags) / len(accel_mags)
centered = [m - mean_mag for m in accel_mags]

# Peak detection to find strokes
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

print(f"Detected {len(peaks)} stroke events (impacts).")

# Analyze gyroscope rotation around these peaks
print("Rotation at catch (in rad/s):")
for p in peaks:
    gx, gy, gz = gyro_vals[p]
    print(f"Time: {times[p]}, Gyro X: {gx:.2f}, Gyro Y: {gy:.2f}, Gyro Z: {gz:.2f}")

