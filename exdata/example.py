#
# example data plotting
#
# Author: Eric DeWitt

#
# run exdata/example.py


from pymesh import tuna
from matplotlib import pyplot as plt
tuna_frames = tuna.fromfile('exdata/tuna.bin')
tuna_timeline = tuna.timeline(tuna_frames, 200)

plt.plot(tuna_timeline[0][1600:2800,0,0:3])
plt.show()