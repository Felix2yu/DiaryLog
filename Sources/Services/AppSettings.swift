import Foundation

final class AppSettings {
    static let shared = AppSettings()

    private enum Key {
        static let baseURL = "asr_base_url"
        static let apiKey = "asr_api_key"
        static let asrModel = "asr_model"
        static let chatModel = "chat_model"
        static let asrPrompt = "asr_prompt"
        static let optimizePrompt = "optimize_prompt"
        static let dayCutoffHour = "day_cutoff_hour"
        static let dayCutoffMinute = "day_cutoff_minute"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if defaults.string(forKey: Key.asrModel) == nil {
            defaults.set("whisper-1", forKey: Key.asrModel)
        }
        if defaults.string(forKey: Key.chatModel) == nil {
            defaults.set("gpt-4o-mini", forKey: Key.chatModel)
        }
        if defaults.string(forKey: Key.asrPrompt) == nil {
            defaults.set(
                "这是一段中文日记语音记录。请去除语气词如'呃'、'嗯'、'那个'、'话说'、'然后'、'就是'、'你知道'等，保留完整语义，正确输出中文标点，识别段落。",
                forKey: Key.asrPrompt
            )
        }
        if defaults.string(forKey: Key.optimizePrompt) == nil {
            defaults.set(
                "你是一名中文日记润色助手。请修正用户输入中的错别字，重新组织语序使表达更自然流畅，合并冗余语句，补全合理的标点符号与分段，保持原意与语气，不添加额外内容。只返回润色后的文本，不要加前缀或解释。",
                forKey: Key.optimizePrompt
            )
        }
        if defaults.object(forKey: Key.dayCutoffHour) == nil {
            defaults.set(8, forKey: Key.dayCutoffHour)
        }
        if defaults.object(forKey: Key.dayCutoffMinute) == nil {
            defaults.set(0, forKey: Key.dayCutoffMinute)
        }
    }

    var baseURL: String {
        get { defaults.string(forKey: Key.baseURL) ?? "https://api.openai.com" }
        set { defaults.set(newValue, forKey: Key.baseURL) }
    }

    var apiKey: String {
        get { defaults.string(forKey: Key.apiKey) ?? "" }
        set { defaults.set(newValue, forKey: Key.apiKey) }
    }

    var asrModel: String {
        get { defaults.string(forKey: Key.asrModel) ?? "whisper-1" }
        set { defaults.set(newValue, forKey: Key.asrModel) }
    }

    var chatModel: String {
        get { defaults.string(forKey: Key.chatModel) ?? "gpt-4o-mini" }
        set { defaults.set(newValue, forKey: Key.chatModel) }
    }

    var asrPrompt: String {
        get { defaults.string(forKey: Key.asrPrompt) ?? "" }
        set { defaults.set(newValue, forKey: Key.asrPrompt) }
    }

    var optimizePrompt: String {
        get { defaults.string(forKey: Key.optimizePrompt) ?? "" }
        set { defaults.set(newValue, forKey: Key.optimizePrompt) }
    }

    var dayCutoffHour: Int {
        get { defaults.object(forKey: Key.dayCutoffHour) as? Int ?? 8 }
        set { defaults.set(newValue, forKey: Key.dayCutoffHour) }
    }

    var dayCutoffMinute: Int {
        get { defaults.object(forKey: Key.dayCutoffMinute) as? Int ?? 0 }
        set { defaults.set(newValue, forKey: Key.dayCutoffMinute) }
    }

    var dayCutoffDateComponents: DateComponents {
        DateComponents(hour: dayCutoffHour, minute: dayCutoffMinute)
    }

    func diaryDate(for date: Date, calendar: Calendar = .current) -> Date {
        var cal = calendar
        cal.timeZone = .current
        let startOfDay = cal.startOfDay(for: date)
        guard let cutoff = cal.date(bySettingHour: dayCutoffHour,
                                    minute: dayCutoffMinute,
                                    second: 0,
                                    of: date) else {
            return startOfDay
        }
        if date < cutoff {
            return cal.date(byAdding: .day, value: -1, to: startOfDay) ?? startOfDay
        }
        return startOfDay
    }
}
