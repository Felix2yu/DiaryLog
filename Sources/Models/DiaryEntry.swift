import Foundation
import SwiftData

@Model
final class DiaryEntry {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var rawTranscript: String
    var optimizedText: String?
    var audioFileName: String
    var audioDuration: Double
    var asrModel: String?
    var optimizeModel: String?
    var isOptimized: Bool

    init(id: UUID = UUID(),
         createdAt: Date = Date(),
         rawTranscript: String,
         optimizedText: String? = nil,
         audioFileName: String,
         audioDuration: Double = 0,
         asrModel: String? = nil,
         optimizeModel: String? = nil,
         isOptimized: Bool = false) {
        self.id = id
        self.createdAt = createdAt
        self.rawTranscript = rawTranscript
        self.optimizedText = optimizedText
        self.audioFileName = audioFileName
        self.audioDuration = audioDuration
        self.asrModel = asrModel
        self.optimizeModel = optimizeModel
        self.isOptimized = isOptimized
    }

    var displayText: String {
        if let optimizedText, !optimizedText.isEmpty {
            return optimizedText
        }
        return rawTranscript
    }
}
