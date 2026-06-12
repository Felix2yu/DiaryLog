import Foundation
import AVFoundation

final class AudioRecorder: NSObject {
    static let shared = AudioRecorder()

    private var recorder: AVAudioRecorder?
    private(set) var currentFileURL: URL?
    private(set) var isRecording = false
    var onMeterUpdate: ((Float) -> Void)?
    private var meterTimer: Timer?

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory,
                                 in: .userDomainMask)[0]
    }

    var recordingsDirectory: URL {
        let url = documentsURL.appendingPathComponent("Recordings",
                                                      isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url,
                                                     withIntermediateDirectories: true)
        }
        return url
    }

    func requestPermissionIfNeeded() async -> Bool {
        let status = AVAudioSession.sharedInstance().recordPermission
        switch status {
        case .granted:
            return true
        case .denied, .restricted:
            return false
        case .undetermined:
            return await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        @unknown default:
            return false
        }
    }

    func startRecording() throws -> URL {
        if isRecording {
            stopRecording()
        }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let fileName = "diary-\(Int(Date().timeIntervalSince1970))-\(UUID().uuidString.prefix(8)).m4a"
        let fileURL = recordingsDirectory.appendingPathComponent(fileName)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 96000
        ]

        let recorder = try AVAudioRecorder(url: fileURL, settings: settings)
        recorder.isMeteringEnabled = true
        recorder.delegate = self
        recorder.record()

        self.recorder = recorder
        self.currentFileURL = fileURL
        self.isRecording = true

        self.meterTimer?.invalidate()
        let meterTimer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            recorder.updateMeters()
            let power = recorder.averagePower(forChannel: 0)
            self.onMeterUpdate?(power)
        }
        RunLoop.main.add(meterTimer, forMode: .common)
        self.meterTimer = meterTimer

        return fileURL
    }

    func stopRecording() {
        meterTimer?.invalidate()
        meterTimer = nil
        recorder?.stop()
        recorder = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false,
                                                       options: .notifyOthersOnDeactivation)
    }

    func currentDuration() -> TimeInterval {
        recorder?.currentTime ?? 0
    }

    func fileURL(for fileName: String) -> URL {
        recordingsDirectory.appendingPathComponent(fileName)
    }

    func deleteFile(fileName: String) {
        let url = fileURL(for: fileName)
        try? FileManager.default.removeItem(at: url)
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        isRecording = false
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        isRecording = false
    }
}
