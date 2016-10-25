import Metal

var supportedDevices: [MTLDevice] = MTLCopyAllDevices()

if (supportedDevices.count > 0)
{
    for device in supportedDevices {
        var isSupported = device.supportsFeatureSet(MTLFeatureSet.osx_GPUFamily1_v1)
        print("\(device.name), supported: \(isSupported)")
    }
}
else
{
   print("No supported devices found")
}
