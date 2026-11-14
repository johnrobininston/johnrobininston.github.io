# Packages
import numpy as np

# Set random seed
rng = np.random.default_rng(seed=342)


# Single experiment iteration
def roll_until_4():
    test = False
    x = []
    s = []
    while test is False:
        roll = rng.integers(low=1, high=7)
        x.append(roll)
        s.append(np.max(np.array(x)))
        if roll == 4:
            test = True
    return np.array(x), np.array(s)


# Empirical mean
s_vals = []
for _ in range(10000):
    x, s = roll_until_4()
    s_vals.append(s[-1])

# Print the average
np.mean(s_vals, axis=0)
