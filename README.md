# mesh-analysis
Python and MATLAB scripts for analysing MESh data.

Both the Python and MATLAB code reads a binary stream (normally a file) and
produces a 'data frame' like object. For the Python code, this is a list of objects
and for MATLAB this is a struct array. These are called 'Frames' in the Python code
and 'Packets' in the MATLAB code [for now]. The basic fields are the same for both.
Both the Python and the MATLAB code also provide a mechanisms to convert between
the 'data frame' like object and an ND-array. This is useful for plotting and
quickly working with the data. The ND-arrays are dense arrays, with NaN/NAs where
there are is no data. Below

is the abstract structure:

```
Frame/Packet:
    id      := Tuna message ID
    sync    := Tuna in sync?
    button  := Button activated
    aligned := Tuna aligned?
    error   := Tuna error
    second  := Sample time (in milliseconds)?
    counter := Sample count (in counts / sample rate)?
    data    := The data (int16)
```    
In Python, this is TunaDataFrame object. In MATLAB this is a struct-array.

```
The dense ND-array functions return the following three objects:
    An ND-array with indexes [SyncronizedSampleTime, TunaNumber, ChannelNumber]
    A state array with the indexes [SyncronizedTime, TunaNumber, DataElement]
        where DataElement is {id, sync, button, aligned, error, second, counter, decimal_second};
    A channel map which maps TunaID -> TunaNumber
```
   
In Python, these are returned from the TunaDataFrame list as [adc, state,
channelmap] by the function 'timeline' and in MATLAB these are returned as
[nd_array, state, channelmap] by the function 'packet_to_ndarray'.

The button reading is at 1/4 of the sampling rate, i.e., if you use the default 100Hz sample rate the button is read each 40 milliseconds.

