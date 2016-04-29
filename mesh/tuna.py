# -*- coding: utf-8 -*-
"""
Created on Thu Apr 28 00:52:42 2016

@author: Gonçalo
"""

import numpy as np

class TunaDataFrame:
    _IdMask_ = 0x0FFF
    _SyncFlag_ = 0x8000
    _ButtonFlag_ = 0x4000
    _AlignedFlag_ = 0x2000
    _ErrorFlag_ = 0x1000
    _MessageLength_ = 80
    _NumSamples_ = 4
    _NumChannels_ = 9
    
    def __init__(self, message):
        messageId = message[1] | message[2] << 8
        self.id = messageId & self._IdMask_
        self.sync = (messageId & self._SyncFlag_) != 0;
        self.button = (messageId & self._ButtonFlag_) != 0;
        self.aligned = (messageId & self._AlignedFlag_) != 0;
        self.error = (messageId & self._ErrorFlag_) != 0;
        self.second = message[3] | message[4] << 8 |\
                      message[5] << 16 | message[6] << 24;
        self.counter = message[7]
        self.data = message[8:self._MessageLength_].view(dtype=np.int16)\
                    .reshape((self._NumSamples_,self._NumChannels_))
                    
def fromfile(name):
    data = np.fromfile(name,dtype=np.uint8)
    return frombuffer(data)
        
def frombuffer(data):
    frames = []
    for i in range(0,len(data),TunaDataFrame._MessageLength_):
        message = data[i:]
        if len(message) < TunaDataFrame._MessageLength_:
            break
        frames.append(TunaDataFrame(message))
    return frames
    
def timeline(frames,freq=200):
    mintime = min(frames,key=lambda x:x.second).second
    maxtime = max(frames,key=lambda x:x.second).second
    ids = np.unique((f.id for f in frames))
    channelmap = dict(((x,i) for i,x in enumerate(ids)))
    nsamples = (maxtime - mintime + 1) * freq
    result = np.full((nsamples,len(ids),TunaDataFrame._NumChannels_),np.NaN)
    for frame in frames:
        i = channelmap[frame.id]
        t = (frame.second - mintime) * freq + frame.counter
        result[t:t+TunaDataFrame._NumSamples_,i,:] = frame.data
    return result, channelmap
