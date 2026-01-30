import Foundation

public enum ChronologyAnchor {
    public static let TODAY_DATE = "2025.11.21"
    public static let YESTERDAY_DATE = "2025.11.20"
    public static let THREE_DAYS_AGO = "2025.11.18"
    public static let ONE_YEAR_AGO_DATE = "2024.11.21"
    public static let TWO_YEARS_AGO_DATE = "2023.11.21"
}

public enum MockDataService {
    public static let mappings: [AddressMapping] = [
        AddressMapping(id: "map_home", userId: "user_1", name: "Home / 静安", icon: "home", color: "indigo"),
        AddressMapping(id: "map_office", userId: "user_1", name: "WestBund AI Tower", icon: "briefcase", color: "slate"),
        AddressMapping(id: "map_cafe", userId: "user_1", name: "RAC Bar", icon: "coffee", color: "amber"),
        AddressMapping(id: "map_gym", userId: "user_1", name: "Pure Fitness", icon: "heart", color: "rose"),
        AddressMapping(id: "map_park", userId: "user_1", name: "Fuxing Park", icon: "tree", color: "emerald"),
        AddressMapping(id: "map_beach", userId: "user_1", name: "Aranya", icon: "vacation", color: "sky")
    ]

    public static let fences: [AddressFence] = [
        AddressFence(id: "fence_home", mappingId: "map_home", lat: 31.2288, lng: 121.4450, radius: 100, originalRawName: "Yanping Road 123"),
        AddressFence(id: "fence_office", mappingId: "map_office", lat: 31.1688, lng: 121.4650, radius: 200, originalRawName: "Yunjin Road 701"),
        AddressFence(id: "fence_cafe", mappingId: "map_cafe", lat: 31.2145, lng: 121.4320, radius: 50, originalRawName: "Anfu Road 322"),
        AddressFence(id: "fence_gym", mappingId: "map_gym", lat: 31.2200, lng: 121.4500, radius: 80, originalRawName: "Nanjing West Road 999"),
        AddressFence(id: "fence_park", mappingId: "map_park", lat: 31.2190, lng: 121.4600, radius: 150, originalRawName: "Fuxing Middle Road"),
        AddressFence(id: "fence_beach", mappingId: "map_beach", lat: 39.8200, lng: 119.2300, radius: 500, originalRawName: "Golden Coast")
    ]

    public static func buildLocation(rawName: String, lat: Double, lng: Double) -> LocationVO {
        let repoFences = LocationRepository.shared.fences
        let repoMappings = LocationRepository.shared.mappings
        if let hitFence = repoFences.first(where: { hypot(($0.lat - lat) * 111_000, ($0.lng - lng) * 111_000) <= $0.radius }) {
            if let mapping = repoMappings.first(where: { $0.id == hitFence.mappingId }) {
                return LocationVO(status: .mapped,
                                  mappingId: mapping.id,
                                  snapshot: LocationSnapshot(lat: lat, lng: lng),
                                  displayText: mapping.name,
                                  originalRawName: rawName,
                                  icon: mapping.icon,
                                  color: mapping.color)
            }
        }
        return LocationVO(status: .raw,
                           mappingId: nil,
                           snapshot: LocationSnapshot(lat: lat, lng: lng),
                           displayText: rawName,
                           originalRawName: rawName,
                           icon: nil,
                           color: nil)
    }

    public static let questions: [QuestionEntry] = [
        QuestionEntry(id: "q_legacy_2024",
                       created_at: ChronologyAnchor.ONE_YEAR_AGO_DATE,
                       updated_at: ChronologyAnchor.ONE_YEAR_AGO_DATE,
                       dayId: ChronologyAnchor.ONE_YEAR_AGO_DATE,
                       system_prompt: "给一年后的自己：如果不考虑数据指标，你对现在做的这件事，感到快乐吗？",
                       journal_now_id: "e_2024_fear",
                       journal_future_id: "e_today_reply_to_past",
                       interval_days: 365,
                       delivery_date: "2099.01.01"),
        QuestionEntry(id: "q_yesterday_reflection",
                       created_at: ChronologyAnchor.YESTERDAY_DATE,
                       updated_at: ChronologyAnchor.YESTERDAY_DATE,
                       dayId: ChronologyAnchor.YESTERDAY_DATE,
                       system_prompt: "每日一问：昨天跑步的时候，你在想什么？",
                       journal_now_id: "e_yesterday_run",
                       journal_future_id: nil,
                       interval_days: 1,
                       delivery_date: ChronologyAnchor.TODAY_DATE)
    ]

    public static let loveLogs: [LoveLog] = [
        LoveLog(id: "love_mom_checkin",
                mentionTime: ChronologyAnchor.YESTERDAY_DATE,
                timestamp: "20:00",
                sender: "Mom",
                receiver: "Me",
                content: "注意保暖",
                originalText: "上海降温了，记得穿那件深蓝色的外套，别只要风度不要温度。")
    ]

    public static let achievements: [String: UserAchievement] = [
        "def_winter_sea": UserAchievement(definitionId: "def_winter_sea",
                                           status: .unlocked,
                                           currentLevel: 1,
                                           progressValue: 1,
                                           targetValue: 1,
                                           aiGeneratedTitle: LocalizedString(en: "Frozen Horizon", zh: "冰封地平线"),
                                           aiPoeticDescription: LocalizedString(en: "You stood where the water turned to stone.", zh: "你站在了海水凝固成石的地方。"),
                                           aiComment: nil,
                                           relatedEntryIDs: ["e_2023_ocean", "e_2023_photo"],
                                           lastUpdatedAt: ChronologyAnchor.TWO_YEARS_AGO_DATE,
                                           unlockedAt: ChronologyAnchor.TWO_YEARS_AGO_DATE)
    ]

    public static let timeline: [String: [TimelineItem]] = {
        let scene2023 = SceneGroup(type: "scene",
                                   id: "scene_2023_beach",
                                   timeRange: "06:30 - 08:00",
                                   location: buildLocation(rawName: "Golden Coast", lat: 39.8200, lng: 119.2300),
                                   entries: [
                                        JournalEntry(id: "e_2023_ocean", type: .text, subType: nil, chronology: .present, content: "第一次在冬天看海。孤独图书馆旁边没有任何人，只有海浪的声音。鲸鱼在云端，我们在岸边。我觉得自己像一颗被冲刷了很久的石头，终于停下来了。", url: nil, timestamp: "06:45", category: .emotion, metadata: nil),
                                        JournalEntry(id: "e_2023_photo", type: .image, subType: nil, chronology: .present, content: "Frozen horizon.", url: "https://images.unsplash.com/photo-1519865885898-a54a6f2c7eea?q=80&w=1000&auto=format&fit=crop", timestamp: "07:00", category: .media, metadata: nil)
                                   ])

        let scene2024 = SceneGroup(type: "scene",
                                   id: "scene_2024_origin",
                                   timeRange: "23:45 - 00:15",
                                   location: buildLocation(rawName: "Yunjin Road 701", lat: 31.1688, lng: 121.4650),
                                   entries: [
                                        JournalEntry(id: "e_2024_fear", type: .text, subType: nil, chronology: .future, content: "服务器部署完毕。明天就是 Beta 上线日。虽然团队都在庆祝，但我心里很慌。我们试图构建的\"数字内省\"系统，真的会有人用吗？\n\n这感觉就像在深海里点燃一根火柴。", url: nil, timestamp: "23:55", category: .work, metadata: nil)
                                   ])

        let sceneReunion = SceneGroup(type: "scene",
                                      id: "scene_reunion",
                                      timeRange: "19:00 - 21:00",
                                      location: buildLocation(rawName: "Anfu Road 322", lat: 31.2145, lng: 121.4320),
                                      entries: [
                                        JournalEntry(id: "e_reunion_talk", type: .text, subType: nil, chronology: .present, content: "和 Sarah 在 RAC 见面。光线刚刚好打在她的侧脸上。我们聊起了当年的理想，虽然大家都变了，但眼神里的光还在。\n\n她说：\"不要为了效率而牺牲了诗意。\"", url: nil, timestamp: "19:30", category: .social, metadata: nil),
                                        JournalEntry(id: "e_reunion_pic", type: .image, subType: nil, chronology: .present, content: "Two cups, two paths.", url: "https://images.unsplash.com/photo-1511920170033-f8396924c348?q=80&w=1000&auto=format&fit=crop", timestamp: "20:15", category: .emotion, metadata: nil)
                                      ])

        let sceneYesterday = SceneGroup(type: "scene",
                                        id: "scene_yesterday_workout",
                                        timeRange: "19:00 - 20:30",
                                        location: buildLocation(rawName: "Nanjing West Road 999", lat: 31.2200, lng: 121.4500),
                                        entries: [
                                            JournalEntry(id: "e_yesterday_run", type: .text, subType: nil, chronology: .future, content: "Zone 2 running. 5km. Head is clear.", url: nil, timestamp: "19:45", category: .social, metadata: nil)
                                        ])

        let sceneTodayMorning = SceneGroup(type: "scene",
                                           id: "scene_today_morning",
                                           timeRange: "07:15 - 08:30",
                                           location: buildLocation(rawName: "Yanping Road 123", lat: 31.2288, lng: 121.4450),
                                           entries: [
                                                JournalEntry(id: "e_today_dream", type: .text, subType: nil, chronology: .present, content: "梦境碎片：\n在一辆行驶在云端的列车上，车窗外不是天空，而是深海。鲸鱼在云层间穿梭。检票员是一只拿着怀表的兔子，问我：\"你的时间是顺时针还是逆时针流动的？\"", url: nil, timestamp: "07:30", category: .dream, metadata: nil),
                                                JournalEntry(id: "e_today_coffee", type: .image, subType: nil, chronology: .present, content: "Morning fuel. Cold brew with a slice of lemon.", url: "https://images.unsplash.com/photo-1517701604599-bb29b5dd73ad?q=80&w=1000&auto=format&fit=crop", timestamp: "08:15", category: .emotion, metadata: nil)
                                           ])

        let journeyToday = JourneyBlock(type: "journey",
                                        id: "journey_today_commute",
                                        origin: buildLocation(rawName: "Yanping Road 123", lat: 31.2288, lng: 121.4450),
                                        destination: buildLocation(rawName: "Yunjin Road 701", lat: 31.1688, lng: 121.4650),
                                        mode: .car,
                                        entries: [
                                            JournalEntry(id: "e_today_music", type: .text, subType: nil, chronology: .present, content: "延安高架有点堵。这种灰色的天气，最适合听 Ryuichi Sakamoto 的《Opus》。感觉整个城市都在呼吸。", url: nil, timestamp: "09:10", category: .health, metadata: nil)
                                        ])

        let sceneTodayWork = SceneGroup(type: "scene",
                                        id: "scene_today_work",
                                        timeRange: "09:30 - 14:00",
                                        location: buildLocation(rawName: "Yunjin Road 701", lat: 31.1688, lng: 121.4650),
                                        entries: [
                                            JournalEntry(id: "e_today_ui_polish", type: .text, subType: nil, chronology: .present, content: "重构了 Profile 页面的动效。决定去掉所有的分割线，完全用留白和\"玻璃层级\"来区分信息。Less borders, more depth.", url: nil, timestamp: "10:45", category: .work, metadata: nil),
                                            JournalEntry(id: "e_today_reply_to_past", type: .text, subType: nil, chronology: .present, content: "嗨，2024年的 Alex。\n\n那根火柴没有熄灭，它点亮了一整片海域。虽然Beta版当时bug很多，但现在的\"智镜\"已经有了真实的生命力。\n\n别怕，跳下去。", url: nil, timestamp: "12:30", category: .emotion, metadata: JournalEntry.Metadata(blocks: nil, reviewDate: nil, createdDate: ChronologyAnchor.TODAY_DATE, questionId: "q_legacy_2024", duration: nil, sender: nil))
                                        ])

        return [
            ChronologyAnchor.TWO_YEARS_AGO_DATE: [.scene(scene2023)],
            ChronologyAnchor.ONE_YEAR_AGO_DATE: [.scene(scene2024)],
            ChronologyAnchor.THREE_DAYS_AGO: [.scene(sceneReunion)],
            ChronologyAnchor.YESTERDAY_DATE: [.scene(sceneYesterday)],
            ChronologyAnchor.TODAY_DATE: [.scene(sceneTodayMorning), .journey(journeyToday), .scene(sceneTodayWork)]
        ]
    }()

    public static func getTimeline(for date: String) -> [TimelineItem] {
        timeline[date] ?? []
    }

    public static func getEntryMeta(id: String) -> (date: String, title: String)? {
        for (date, items) in timeline {
            for item in items {
                switch item {
                case .scene(let s):
                    if let hit = s.entries.first(where: { $0.id == id }) {
                        let title = hit.content ?? hit.category?.rawValue ?? ""
                        return (date, title)
                    }
                case .journey(let j):
                    if let hit = j.entries.first(where: { $0.id == id }) {
                        let title = hit.content ?? hit.category?.rawValue ?? ""
                        return (date, title)
                    }
                }
            }
        }
        return nil
    }

    public static func getJournalEntry(id: String) -> JournalEntry? {
        for (_, items) in timeline {
            for item in items {
                switch item {
                case .scene(let s):
                    if let hit = s.entries.first(where: { $0.id == id }) { return hit }
                case .journey(let j):
                    if let hit = j.entries.first(where: { $0.id == id }) { return hit }
                }
            }
        }
        return nil
    }
    
    // MARK: - Deprecated Mock Data Removed
    // UserProfile and RelationshipProfile mock data have been completely removed.
    // These models have been replaced by NarrativeUserProfile and NarrativeRelationship.
    // No migration is needed as the app has not been released yet.
}
