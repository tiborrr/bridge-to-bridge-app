import csv
import math

def process_file_autocorr(filename):
    times = []
    mags = []
    with open(filename, 'r') as f:
        reader = csv.reader(f)
        next(reader)
        for row in reader:
            if not row or len(row) < 4: continue
            t = int(row[0])
            x, y, z = float(row[1]), float(row[2]), float(row[3])
            mag = math.sqrt(x*x + y*y + z*z)
            times.append(t)
            mags.append(mag)
            
    # Assuming sample rate is roughly constant, let's resample or just assume constant
    # Average delta t
    dt = (times[-1] - times[0]) / (len(times) - 1) / 1000.0 # in seconds
    fs = 1.0 / dt
    
    # Subtract mean
    mean_mag = sum(mags) / len(mags)
    centered = [m - mean_mag for m in mags]
    
    # Low pass filter (simple moving average, window = 0.2s)
    window_size = int(0.2 * fs)
    smoothed = []
    for i in range(len(centered)):
        start = max(0, i - window_size // 2)
        end = min(len(centered), i + window_size // 2)
        smoothed.append(sum(centered[start:end]) / (end - start))
    
    # Autocorrelation
    n = len(smoothed)
    autocorr = []
    max_lag = int(3.0 * fs) # max 3 seconds (20 SPM)
    min_lag = int(0.5 * fs) # min 0.5 seconds (120 SPM)
    
    for lag in range(min_lag, max_lag):
        if lag >= n: break
        sum_prod = 0
        for i in range(n - lag):
            sum_prod += smoothed[i] * smoothed[i+lag]
        autocorr.append((lag, sum_prod))
        
    # Find peak in autocorrelation
    if not autocorr:
        print("No valid autocorrelation")
        return
        
    best_lag = max(autocorr, key=lambda x: x[1])[0]
    
    period = best_lag / fs # in seconds
    spm = 60.0 / period
    
    print(f"File: {filename}")
    print(f"Sample Rate: {fs:.1f} Hz")
    print(f"Total time: {(times[-1] - times[0])/1000:.1f}s")
    print(f"Calculated SPM (Autocorrelation): {spm:.1f}")
    print("-" * 40)

process_file_autocorr('/Users/tiborcasteleijn/Repositories/bridge-to-bridge-app/test/input/lsm6dso_LSM6DSO_Accelerometer_Non-wakeup.csv')
process_file_autocorr('/Users/tiborcasteleijn/Repositories/bridge-to-bridge-app/test/input/lsm6dso_LSM6DSO_Gyroscope_Non-wakeup.csv')
