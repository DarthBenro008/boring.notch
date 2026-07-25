//
//  CoreAudioOutputProvider.swift
//  customNotch
//

import CoreAudio
import Foundation
import NotchPluginCore
import CustomNotchPluginSDK

enum CoreAudioOutputError: Error, LocalizedError {
    case noDevices
    case setFailed(OSStatus)
    case queryFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .noDevices: return "No audio output devices found"
        case .setFailed(let s): return "Failed to set default output (\(s))"
        case .queryFailed(let s): return "Audio query failed (\(s))"
        }
    }
}

/// Live Core Audio implementation of `AudioOutputProviding`.
final class CoreAudioOutputProvider: AudioOutputProviding {
    var defaultOutputDeviceID: UInt32? {
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )
        guard status == noErr, deviceID != 0 else { return nil }
        return deviceID
    }

    func listOutputDevices() throws -> [AudioOutputDevice] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &dataSize
        )
        guard status == noErr else { throw CoreAudioOutputError.queryFailed(status) }

        let count = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: count)
        status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &dataSize,
            &deviceIDs
        )
        guard status == noErr else { throw CoreAudioOutputError.queryFailed(status) }

        let defaultID = defaultOutputDeviceID
        var devices: [AudioOutputDevice] = []

        for id in deviceIDs {
            guard hasOutputChannels(id) else { continue }
            let name = stringProperty(id, selector: kAudioObjectPropertyName) ?? "Device \(id)"
            let uid = stringProperty(id, selector: kAudioDevicePropertyDeviceUID) ?? "\(id)"
            let transport = transportType(for: id)
            devices.append(
                AudioOutputDevice(
                    id: id,
                    name: name,
                    uid: uid,
                    transportType: transport,
                    isDefault: id == defaultID
                )
            )
        }

        return AudioOutputLogic.sortedDevices(devices)
    }

    func setDefaultOutputDevice(id: UInt32) throws {
        var deviceID = AudioDeviceID(id)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let size = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            size,
            &deviceID
        )
        guard status == noErr else { throw CoreAudioOutputError.setFailed(status) }
    }

    // MARK: - Helpers

    private func hasOutputChannels(_ deviceID: AudioDeviceID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        let sizeStatus = AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &dataSize)
        guard sizeStatus == noErr, dataSize > 0 else { return false }

        let raw = UnsafeMutableRawPointer.allocate(byteCount: Int(dataSize), alignment: MemoryLayout<AudioBufferList>.alignment)
        defer { raw.deallocate() }
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &dataSize, raw)
        guard status == noErr else { return false }

        let bufferList = raw.bindMemory(to: AudioBufferList.self, capacity: 1)
        let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
        var channels = 0
        for buffer in buffers {
            channels += Int(buffer.mNumberChannels)
        }
        return channels > 0
    }

    private func stringProperty(_ deviceID: AudioDeviceID, selector: AudioObjectPropertySelector) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &dataSize) == noErr else {
            return nil
        }
        var cfString: CFString? = nil as CFString?
        // Prefer CFString property path
        var size = UInt32(MemoryLayout<CFString?>.size)
        var value: Unmanaged<CFString>?
        let status = withUnsafeMutablePointer(to: &value) { ptr -> OSStatus in
            AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, ptr)
        }
        if status == noErr, let unmanaged = value {
            return unmanaged.takeUnretainedValue() as String
        }

        // Fallback: C string buffer
        var buffer = [CChar](repeating: 0, count: 256)
        var bufferSize = UInt32(buffer.count)
        let cStatus = buffer.withUnsafeMutableBufferPointer { buf -> OSStatus in
            AudioObjectGetPropertyData(deviceID, &address, 0, nil, &bufferSize, buf.baseAddress!)
        }
        if cStatus == noErr {
            return String(cString: buffer)
        }
        _ = cfString
        return nil
    }

    private func transportType(for deviceID: AudioDeviceID) -> AudioTransportType {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var transport: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &transport)
        guard status == noErr else { return .unknown }
        return AudioOutputLogic.transportType(fourCC: transport)
    }
}
