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
                       system_prompt: "给一年后的自己：如果不考虑数据指标，你对现在做的这件事，感到快乐吗？",
                       journal_now_id: "e_2024_fear",
                       journal_future_id: "e_today_reply_to_past",
                       interval_days: 365,
                       delivery_date: "2099.01.01"),
        QuestionEntry(id: "q_yesterday_reflection",
                       created_at: ChronologyAnchor.YESTERDAY_DATE,
                       updated_at: ChronologyAnchor.YESTERDAY_DATE,
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
                                        JournalEntry(id: "e_2024_fear", type: .text, subType: nil, chronology: .future, content: "服务器部署完毕。明天就是 Beta 上线日。虽然团队都在庆祝，但我心里很慌。我们试图构建的“数字内省”系统，真的会有人用吗？\n\n这感觉就像在深海里点燃一根火柴。", url: nil, timestamp: "23:55", category: .work, metadata: nil)
                                   ])

        let sceneReunion = SceneGroup(type: "scene",
                                      id: "scene_reunion",
                                      timeRange: "19:00 - 21:00",
                                      location: buildLocation(rawName: "Anfu Road 322", lat: 31.2145, lng: 121.4320),
                                      entries: [
                                        JournalEntry(id: "e_reunion_talk", type: .text, subType: nil, chronology: .present, content: "和 Sarah 在 RAC 见面。光线刚刚好打在她的侧脸上。我们聊起了当年的理想，虽然大家都变了，但眼神里的光还在。\n\n她说：“不要为了效率而牺牲了诗意。”", url: nil, timestamp: "19:30", category: .social, metadata: nil),
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
                                                JournalEntry(id: "e_today_dream", type: .text, subType: nil, chronology: .present, content: "梦境碎片：\n在一辆行驶在云端的列车上，车窗外不是天空，而是深海。鲸鱼在云层间穿梭。检票员是一只拿着怀表的兔子，问我：“你的时间是顺时针还是逆时针流动的？”", url: nil, timestamp: "07:30", category: .dream, metadata: nil),
                                                JournalEntry(id: "e_today_coffee", type: .image, subType: nil, chronology: .present, content: "Morning fuel. Cold brew with a slice of lemon.", url: "https://images.unsplash.com/photo-1517701604599-bb29b5dd73ad?q=80&w=1000&auto=format&fit=crop", timestamp: "08:15", category: .emotion, metadata: nil)
                                           ])

        let journeyToday = JourneyBlock(type: "journey",
                                        id: "journey_today_commute",
                                        origin: buildLocation(rawName: "Yanping Road 123", lat: 31.2288, lng: 121.4450),
                                        destination: buildLocation(rawName: "Yunjin Road 701", lat: 31.1688, lng: 121.4650),
                                        mode: .car,
                                        duration: "42 min",
                                        entries: [
                                            JournalEntry(id: "e_today_music", type: .text, subType: nil, chronology: .present, content: "延安高架有点堵。这种灰色的天气，最适合听 Ryuichi Sakamoto 的《Opus》。感觉整个城市都在呼吸。", url: nil, timestamp: "09:10", category: .health, metadata: nil)
                                        ])

        let sceneTodayWork = SceneGroup(type: "scene",
                                        id: "scene_today_work",
                                        timeRange: "09:30 - 14:00",
                                        location: buildLocation(rawName: "Yunjin Road 701", lat: 31.1688, lng: 121.4650),
                                        entries: [
                                            JournalEntry(id: "e_today_ui_polish", type: .text, subType: nil, chronology: .present, content: "重构了 Profile 页面的动效。决定去掉所有的分割线，完全用留白和“玻璃层级”来区分信息。Less borders, more depth.", url: nil, timestamp: "10:45", category: .work, metadata: nil),
                                            JournalEntry(id: "e_today_reply_to_past", type: .text, subType: nil, chronology: .present, content: "嗨，2024年的 Alex。\n\n那根火柴没有熄灭，它点亮了一整片海域。虽然Beta版当时bug很多，但现在的“观己”已经有了真实的生命力。\n\n别怕，跳下去。", url: nil, timestamp: "12:30", category: .emotion, metadata: JournalEntry.Metadata(blocks: nil, reviewDate: nil, createdDate: ChronologyAnchor.TODAY_DATE, questionId: "q_legacy_2024", duration: nil, sender: nil))
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
    
    // MARK: - User Profile Mock Data
    
    /// Creates a realistic mock UserProfile with all five dimensions filled
    /// Requirements: Epic 1-5
    public static func mockUserProfile() -> UserProfile {
        let now = Date()
        
        // 1. Identity Dimension (身份与生理)
        let identityKernel = IdentityKernel(
            gender: .male,
            birthDate: "1992-03",
            height: 178,
            weight: 72,
            bloodType: .A,
            chronicConditions: [],
            basePhysicalCondition: .normal,
            geneticTraits: nil,
            hometown: "杭州",
            currentCity: "上海",
            education: .master,
            maritalStatus: .dating
        )
        
        let identityState = IdentityState(
            isSick: false,
            sicknessType: nil,
            painLocation: nil,
            bodyEnergy: 1,
            sleepQuality: .good,
            exerciseLevel: .moderate,
            hungerLevel: 2,
            thirstLevel: 2,
            fatigueLevel: 3,
            lastUpdatedAt: now
        )
        
        // 2. Personality Dimension (性格与心理)
        let personalityKernel = PersonalityKernel(
            mbtiType: "INFJ",
            bigFive: BigFiveScores(
                openness: 8,
                conscientiousness: 7,
                extraversion: 4,
                agreeableness: 7,
                neuroticism: 5
            ),
            valuePriorities: [.creativity, .freedom, .knowledge, .health, .love],
            decisionMode: .balanced,
            riskPreference: .moderate
        )
        
        let personalityState = PersonalityState(
            happiness: 7,
            anxiety: 4,
            anger: 2,
            calmness: 7,
            moodWeather: 1,
            moodDescription: .positive,
            currentStressors: ["项目截止日期"],
            stressLevel: 5,
            lastUpdatedAt: now
        )
        
        // 3. Social Dimension (社会与关系)
        let socialKernel = SocialKernel(
            coreRelationshipIDs: ["rel_partner_sarah", "rel_family_mom", "rel_friend_alex"],
            socialType: .passive,
            socialEnergy: .ambivert,
            familyStructure: .nuclear
        )
        
        let socialState = SocialState(
            recentSocialFrequency: .occasional,
            socialSatisfaction: 7,
            relationshipsImproving: ["rel_partner_sarah"],
            relationshipsTense: [],
            companionshipNeed: .neutral,
            lastUpdatedAt: now
        )
        
        // 4. Competence Dimension (能力与发展)
        let competenceKernel = CompetenceKernel(
            occupation: "产品设计师",
            industry: "科技/互联网",
            employmentStatus: .employed,
            skills: ["UI/UX设计", "用户研究", "原型设计", "Swift", "Figma"],
            expertise: "移动端产品设计",
            consumptionLevel: .medium,
            debtStatus: .light
        )
        
        let competenceState = CompetenceState(
            workIntensity: .normal,
            workStatus: .busy,
            currentTasks: ["观己App重构", "用户画像功能"],
            taskPressure: 6,
            achievementStatus: .neutral,
            careerSatisfaction: 7,
            lastUpdatedAt: now
        )
        
        // 5. Lifestyle Dimension (习惯与生活)
        let lifestyleKernel = LifestyleKernel(
            chronoType: .night,
            averageSleepHours: 7.0,
            longTermHobbies: ["阅读", "摄影", "跑步", "咖啡"],
            hobbyIntensity: .moderate,
            tastePreferences: ["清淡", "日料", "咖啡"],
            dietType: .omnivore,
            foodRestrictions: ["辣"]
        )
        
        let lifestyleState = LifestyleState(
            currentInterests: ["SwiftUI", "个人知识管理"],
            interestDuration: 30,
            recentEvents: ["完成了半马", "搬到新公寓"],
            eventImpact: .positive,
            planCompletionRate: 6,
            procrastinationLevel: 5,
            lastUpdatedAt: now
        )
        
        return UserProfile(
            id: "user_profile_main",
            createdAt: Calendar.current.date(byAdding: .year, value: -1, to: now) ?? now,
            updatedAt: now,
            identity: IdentityDimension(kernel: identityKernel, state: identityState),
            personality: PersonalityDimension(kernel: personalityKernel, state: personalityState),
            social: SocialDimension(kernel: socialKernel, state: socialState),
            competence: CompetenceDimension(kernel: competenceKernel, state: competenceState),
            lifestyle: LifestyleDimension(kernel: lifestyleKernel, state: lifestyleState)
        )
    }
    
    // MARK: - Relationship Profiles Mock Data
    
    /// Creates realistic mock RelationshipProfiles for all 7 relationship types
    /// Requirements: Epic 6
    public static func mockRelationshipProfiles() -> [RelationshipProfile] {
        let now = Date()
        let calendar = Calendar.current
        
        var profiles: [RelationshipProfile] = []
        
        // MARK: - 1. Alone (独处) - Special type, usually just one
        let alone = RelationshipProfile(
            id: "rel_alone_self",
            createdAt: calendar.date(byAdding: .year, value: -2, to: now) ?? now,
            updatedAt: now,
            type: .alone,
            displayName: "独处时光",
            realName: nil,
            avatar: "🧘",
            intimacyLevel: 10,
            interactionFrequency: .daily,
            emotionalConnection: 10,
            totalInteractions: 500,
            lastInteractionDate: now,
            recentInteractionDates: (0..<7).compactMap { calendar.date(byAdding: .day, value: -$0, to: now) },
            metadata: [:],
            notes: "与自己相处的时间",
            tags: ["冥想", "阅读", "思考"]
        )
        profiles.append(alone)
        
        // MARK: - 2. Partner (伴侣) - 2 examples
        var partner1 = RelationshipProfile(
            id: "rel_partner_sarah",
            createdAt: calendar.date(byAdding: .year, value: -3, to: now) ?? now,
            updatedAt: now,
            type: .partner,
            displayName: "Sarah",
            realName: "张晓雯",
            avatar: "💕",
            intimacyLevel: 9,
            interactionFrequency: .daily,
            emotionalConnection: 9,
            totalInteractions: 1200,
            lastInteractionDate: now,
            recentInteractionDates: (0..<20).compactMap { calendar.date(byAdding: .day, value: -$0, to: now) },
            metadata: [:],
            notes: "在RAC认识的，喜欢艺术和设计",
            tags: ["设计师", "艺术", "咖啡"]
        )
        partner1.partnerStatus = "dating"
        partner1.anniversaryMet = "03-15"
        partner1.anniversaryDating = "06-20"
        profiles.append(partner1)
        
        var partner2 = RelationshipProfile(
            id: "rel_partner_ex",
            createdAt: calendar.date(byAdding: .year, value: -5, to: now) ?? now,
            updatedAt: calendar.date(byAdding: .year, value: -2, to: now) ?? now,
            type: .partner,
            displayName: "前任",
            realName: nil,
            avatar: "💔",
            intimacyLevel: 2,
            interactionFrequency: .veryRare,
            emotionalConnection: 3,
            totalInteractions: 800,
            lastInteractionDate: calendar.date(byAdding: .month, value: -6, to: now),
            recentInteractionDates: [],
            metadata: [:],
            notes: "大学时期的恋人，和平分手",
            tags: ["大学", "回忆"]
        )
        partner2.partnerStatus = "separated"
        profiles.append(partner2)
        
        // MARK: - 3. Family (家人) - 3 examples
        var family1 = RelationshipProfile(
            id: "rel_family_mom",
            createdAt: calendar.date(byAdding: .year, value: -10, to: now) ?? now,
            updatedAt: now,
            type: .family,
            displayName: "妈妈",
            realName: nil,
            avatar: "👩",
            intimacyLevel: 10,
            interactionFrequency: .frequent,
            emotionalConnection: 10,
            totalInteractions: 2000,
            lastInteractionDate: calendar.date(byAdding: .day, value: -1, to: now),
            recentInteractionDates: (0..<10).compactMap { calendar.date(byAdding: .day, value: -$0 * 2, to: now) },
            metadata: [:],
            notes: "每周视频通话",
            tags: ["杭州", "关心"]
        )
        family1.familyRole = "parent"
        family1.livingTogether = false
        profiles.append(family1)
        
        var family2 = RelationshipProfile(
            id: "rel_family_dad",
            createdAt: calendar.date(byAdding: .year, value: -10, to: now) ?? now,
            updatedAt: now,
            type: .family,
            displayName: "爸爸",
            realName: nil,
            avatar: "👨",
            intimacyLevel: 8,
            interactionFrequency: .regular,
            emotionalConnection: 8,
            totalInteractions: 1500,
            lastInteractionDate: calendar.date(byAdding: .day, value: -3, to: now),
            recentInteractionDates: (0..<5).compactMap { calendar.date(byAdding: .day, value: -$0 * 5, to: now) },
            metadata: [:],
            notes: "话不多但很支持我",
            tags: ["杭州", "支持"]
        )
        family2.familyRole = "parent"
        family2.livingTogether = false
        profiles.append(family2)
        
        var family3 = RelationshipProfile(
            id: "rel_family_sister",
            createdAt: calendar.date(byAdding: .year, value: -10, to: now) ?? now,
            updatedAt: now,
            type: .family,
            displayName: "小妹",
            realName: nil,
            avatar: "👧",
            intimacyLevel: 9,
            interactionFrequency: .frequent,
            emotionalConnection: 9,
            totalInteractions: 1800,
            lastInteractionDate: calendar.date(byAdding: .day, value: -2, to: now),
            recentInteractionDates: (0..<8).compactMap { calendar.date(byAdding: .day, value: -$0 * 3, to: now) },
            metadata: [:],
            notes: "在北京工作，经常微信聊天",
            tags: ["北京", "闺蜜"]
        )
        family3.familyRole = "sibling"
        family3.livingTogether = false
        profiles.append(family3)
        
        // MARK: - 4. Friends (朋友) - 3 examples
        var friend1 = RelationshipProfile(
            id: "rel_friend_alex",
            createdAt: calendar.date(byAdding: .year, value: -8, to: now) ?? now,
            updatedAt: now,
            type: .friends,
            displayName: "Alex",
            realName: "李明",
            avatar: "🎸",
            intimacyLevel: 9,
            interactionFrequency: .frequent,
            emotionalConnection: 9,
            totalInteractions: 600,
            lastInteractionDate: calendar.date(byAdding: .day, value: -3, to: now),
            recentInteractionDates: (0..<6).compactMap { calendar.date(byAdding: .day, value: -$0 * 4, to: now) },
            metadata: [:],
            notes: "大学室友，现在在同一个城市",
            tags: ["大学", "音乐", "跑步"]
        )
        friend1.friendIntimacy = "bestFriend"
        friend1.yearsKnown = 8
        profiles.append(friend1)
        
        var friend2 = RelationshipProfile(
            id: "rel_friend_mike",
            createdAt: calendar.date(byAdding: .year, value: -3, to: now) ?? now,
            updatedAt: now,
            type: .friends,
            displayName: "Mike",
            realName: nil,
            avatar: "🏃",
            intimacyLevel: 7,
            interactionFrequency: .regular,
            emotionalConnection: 6,
            totalInteractions: 150,
            lastInteractionDate: calendar.date(byAdding: .day, value: -7, to: now),
            recentInteractionDates: (0..<4).compactMap { calendar.date(byAdding: .day, value: -$0 * 7, to: now) },
            metadata: [:],
            notes: "跑步群认识的，每周一起晨跑",
            tags: ["跑步", "健身"]
        )
        friend2.friendIntimacy = "friend"
        friend2.yearsKnown = 3
        profiles.append(friend2)
        
        var friend3 = RelationshipProfile(
            id: "rel_friend_lily",
            createdAt: calendar.date(byAdding: .year, value: -1, to: now) ?? now,
            updatedAt: now,
            type: .friends,
            displayName: "Lily",
            realName: nil,
            avatar: "📚",
            intimacyLevel: 5,
            interactionFrequency: .occasional,
            emotionalConnection: 5,
            totalInteractions: 30,
            lastInteractionDate: calendar.date(byAdding: .day, value: -14, to: now),
            recentInteractionDates: (0..<2).compactMap { calendar.date(byAdding: .day, value: -$0 * 14, to: now) },
            metadata: [:],
            notes: "读书会认识的",
            tags: ["读书", "文学"]
        )
        friend3.friendIntimacy = "acquaintance"
        friend3.yearsKnown = 1
        profiles.append(friend3)
        
        // MARK: - 5. Colleagues (同事) - 3 examples
        var colleague1 = RelationshipProfile(
            id: "rel_colleague_boss",
            createdAt: calendar.date(byAdding: .year, value: -2, to: now) ?? now,
            updatedAt: now,
            type: .colleagues,
            displayName: "王总",
            realName: nil,
            avatar: "👔",
            intimacyLevel: 6,
            interactionFrequency: .frequent,
            emotionalConnection: 5,
            totalInteractions: 400,
            lastInteractionDate: now,
            recentInteractionDates: (0..<15).compactMap { calendar.date(byAdding: .day, value: -$0, to: now) },
            metadata: [:],
            notes: "直属领导，很支持创新",
            tags: ["领导", "支持"]
        )
        colleague1.workRelationship = "superior"
        colleague1.company = "观己科技"
        colleague1.department = "产品部"
        profiles.append(colleague1)
        
        var colleague2 = RelationshipProfile(
            id: "rel_colleague_dev",
            createdAt: calendar.date(byAdding: .year, value: -2, to: now) ?? now,
            updatedAt: now,
            type: .colleagues,
            displayName: "小陈",
            realName: nil,
            avatar: "💻",
            intimacyLevel: 7,
            interactionFrequency: .daily,
            emotionalConnection: 6,
            totalInteractions: 800,
            lastInteractionDate: now,
            recentInteractionDates: (0..<20).compactMap { calendar.date(byAdding: .day, value: -$0, to: now) },
            metadata: [:],
            notes: "iOS开发，配合很默契",
            tags: ["开发", "Swift", "默契"]
        )
        colleague2.workRelationship = "peer"
        colleague2.company = "观己科技"
        colleague2.department = "技术部"
        profiles.append(colleague2)
        
        var colleague3 = RelationshipProfile(
            id: "rel_colleague_intern",
            createdAt: calendar.date(byAdding: .month, value: -3, to: now) ?? now,
            updatedAt: now,
            type: .colleagues,
            displayName: "实习生小张",
            realName: nil,
            avatar: "🎓",
            intimacyLevel: 4,
            interactionFrequency: .frequent,
            emotionalConnection: 4,
            totalInteractions: 60,
            lastInteractionDate: now,
            recentInteractionDates: (0..<10).compactMap { calendar.date(byAdding: .day, value: -$0 * 2, to: now) },
            metadata: [:],
            notes: "新来的实习生，很有潜力",
            tags: ["实习", "学习"]
        )
        colleague3.workRelationship = "subordinate"
        colleague3.company = "观己科技"
        colleague3.department = "产品部"
        profiles.append(colleague3)
        
        // MARK: - 6. Online Friends (网友) - 2 examples
        var online1 = RelationshipProfile(
            id: "rel_online_designer",
            createdAt: calendar.date(byAdding: .year, value: -2, to: now) ?? now,
            updatedAt: now,
            type: .onlineFriends,
            displayName: "设计师老K",
            realName: nil,
            avatar: "🎨",
            intimacyLevel: 6,
            interactionFrequency: .regular,
            emotionalConnection: 5,
            totalInteractions: 200,
            lastInteractionDate: calendar.date(byAdding: .day, value: -5, to: now),
            recentInteractionDates: (0..<4).compactMap { calendar.date(byAdding: .day, value: -$0 * 7, to: now) },
            metadata: [:],
            notes: "即刻上认识的，经常交流设计心得",
            tags: ["设计", "即刻", "交流"]
        )
        online1.platform = "即刻"
        online1.hasMetInPerson = true
        profiles.append(online1)
        
        var online2 = RelationshipProfile(
            id: "rel_online_writer",
            createdAt: calendar.date(byAdding: .month, value: -6, to: now) ?? now,
            updatedAt: now,
            type: .onlineFriends,
            displayName: "写作者阿文",
            realName: nil,
            avatar: "✍️",
            intimacyLevel: 4,
            interactionFrequency: .occasional,
            emotionalConnection: 4,
            totalInteractions: 50,
            lastInteractionDate: calendar.date(byAdding: .day, value: -10, to: now),
            recentInteractionDates: (0..<3).compactMap { calendar.date(byAdding: .day, value: -$0 * 10, to: now) },
            metadata: [:],
            notes: "小红书上关注的写作博主",
            tags: ["写作", "小红书"]
        )
        online2.platform = "小红书"
        online2.hasMetInPerson = false
        profiles.append(online2)
        
        // MARK: - 7. Pet (宠物) - 2 examples
        var pet1 = RelationshipProfile(
            id: "rel_pet_mochi",
            createdAt: calendar.date(byAdding: .year, value: -3, to: now) ?? now,
            updatedAt: now,
            type: .pet,
            displayName: "糯米",
            realName: nil,
            avatar: "🐱",
            intimacyLevel: 10,
            interactionFrequency: .daily,
            emotionalConnection: 10,
            totalInteractions: 3000,
            lastInteractionDate: now,
            recentInteractionDates: (0..<30).compactMap { calendar.date(byAdding: .day, value: -$0, to: now) },
            metadata: [:],
            notes: "三岁的橘猫，很粘人",
            tags: ["橘猫", "粘人", "治愈"]
        )
        pet1.petType = "cat"
        pet1.petAge = 3
        pet1.petBreed = "橘猫"
        profiles.append(pet1)
        
        var pet2 = RelationshipProfile(
            id: "rel_pet_fish",
            createdAt: calendar.date(byAdding: .month, value: -6, to: now) ?? now,
            updatedAt: now,
            type: .pet,
            displayName: "小金",
            realName: nil,
            avatar: "🐠",
            intimacyLevel: 5,
            interactionFrequency: .daily,
            emotionalConnection: 4,
            totalInteractions: 180,
            lastInteractionDate: now,
            recentInteractionDates: (0..<30).compactMap { calendar.date(byAdding: .day, value: -$0, to: now) },
            metadata: [:],
            notes: "办公桌上的金鱼，看着很解压",
            tags: ["金鱼", "办公室", "解压"]
        )
        pet2.petType = "fish"
        pet2.petAge = 1
        pet2.petBreed = "金鱼"
        profiles.append(pet2)
        
        return profiles
    }
    
    // MARK: - Convenience Static Properties
    
    /// Static property for easy access to mock user profile
    public static let userProfile: UserProfile = {
        let profile = UserProfile(
            id: "user_profile_1",
            createdAt: Date(),
            updatedAt: Date(),
            identity: IdentityDimension(
                kernel: IdentityKernel(
                    gender: .male,
                    birthDate: "1992-03",
                    height: 178,
                    weight: 72,
                    bloodType: .A,
                    chronicConditions: ["过敏性鼻炎"],
                    basePhysicalCondition: .normal,
                    geneticTraits: ["近视"],
                    hometown: "杭州",
                    currentCity: "上海",
                    education: .master,
                    maritalStatus: .dating
                ),
                state: IdentityState(
                    isSick: false,
                    sicknessType: nil,
                    painLocation: nil,
                    bodyEnergy: 1,
                    sleepQuality: .good,
                    exerciseLevel: .moderate,
                    hungerLevel: 2,
                    thirstLevel: 2,
                    fatigueLevel: 3,
                    lastUpdatedAt: Date()
                )
            ),
            personality: PersonalityDimension(
                kernel: PersonalityKernel(
                    mbtiType: "INTJ",
                    bigFive: BigFiveScores(
                        openness: 8,
                        conscientiousness: 7,
                        extraversion: 4,
                        agreeableness: 6,
                        neuroticism: 5
                    ),
                    valuePriorities: [.freedom, .knowledge, .creativity, .health, .family],
                    decisionMode: .logical,
                    riskPreference: .moderate
                ),
                state: PersonalityState(
                    happiness: 7,
                    anxiety: 4,
                    anger: 2,
                    calmness: 7,
                    moodWeather: 1,
                    moodDescription: .positive,
                    currentStressors: ["项目截止日期"],
                    stressLevel: 5,
                    lastUpdatedAt: Date()
                )
            ),
            social: SocialDimension(
                kernel: SocialKernel(
                    coreRelationshipIDs: ["rel_partner_1", "rel_family_mom", "rel_family_dad", "rel_friend_sarah"],
                    socialType: .passive,
                    socialEnergy: .introvert,
                    familyStructure: .nuclear
                ),
                state: SocialState(
                    recentSocialFrequency: .occasional,
                    socialSatisfaction: 7,
                    relationshipsImproving: ["rel_friend_sarah"],
                    relationshipsTense: [],
                    companionshipNeed: .neutral,
                    lastUpdatedAt: Date()
                )
            ),
            competence: CompetenceDimension(
                kernel: CompetenceKernel(
                    occupation: "产品经理",
                    industry: "互联网/科技",
                    employmentStatus: .employed,
                    skills: ["产品设计", "用户研究", "数据分析", "Swift"],
                    expertise: "AI产品",
                    consumptionLevel: .medium,
                    debtStatus: .light
                ),
                state: CompetenceState(
                    workIntensity: .normal,
                    workStatus: .busy,
                    currentTasks: ["观己 v0.35 发布", "用户访谈"],
                    taskPressure: 6,
                    achievementStatus: .neutral,
                    careerSatisfaction: 7,
                    lastUpdatedAt: Date()
                )
            ),
            lifestyle: LifestyleDimension(
                kernel: LifestyleKernel(
                    chronoType: .night,
                    averageSleepHours: 7.0,
                    longTermHobbies: ["摄影", "跑步", "阅读", "咖啡"],
                    hobbyIntensity: .moderate,
                    tastePreferences: ["辣", "咖啡", "日料"],
                    dietType: .omnivore,
                    foodRestrictions: ["海鲜过敏"]
                ),
                state: LifestyleState(
                    currentInterests: ["学习 SwiftUI", "冥想"],
                    interestDuration: 30,
                    recentEvents: ["搬新家"],
                    eventImpact: .positive,
                    planCompletionRate: 6,
                    procrastinationLevel: 5,
                    lastUpdatedAt: Date()
                )
            )
        )
        return profile
    }()
    
    /// Static property for easy access to mock relationship profiles
    public static let relationshipProfiles: [RelationshipProfile] = {
        var profiles: [RelationshipProfile] = []
        
        // MARK: Partner (伴侣)
        var partner1 = RelationshipProfile(
            id: "rel_partner_1",
            type: .partner,
            displayName: "小雨",
            realName: nil,
            avatar: "❤️",
            intimacyLevel: 10,
            interactionFrequency: .daily,
            emotionalConnection: 10,
            totalInteractions: 365,
            lastInteractionDate: Date(),
            recentInteractionDates: (0..<30).map { Date().addingTimeInterval(TimeInterval(-$0 * 86400)) },
            notes: "我的另一半，一起走过了三年",
            tags: ["重要", "每日"]
        )
        partner1.partnerStatus = "dating"
        partner1.anniversaryMet = "03-15"
        partner1.anniversaryDating = "06-20"
        profiles.append(partner1)
        
        // MARK: Family (家人)
        var familyMom = RelationshipProfile(
            id: "rel_family_mom",
            type: .family,
            displayName: "妈妈",
            avatar: "👩",
            intimacyLevel: 9,
            interactionFrequency: .frequent,
            emotionalConnection: 9,
            totalInteractions: 120,
            lastInteractionDate: Date().addingTimeInterval(-86400),
            recentInteractionDates: [Date().addingTimeInterval(-86400), Date().addingTimeInterval(-172800)],
            notes: "每周视频通话",
            tags: ["家人"]
        )
        familyMom.familyRole = "parent"
        familyMom.livingTogether = false
        profiles.append(familyMom)
        
        var familyDad = RelationshipProfile(
            id: "rel_family_dad",
            type: .family,
            displayName: "爸爸",
            avatar: "👨",
            intimacyLevel: 8,
            interactionFrequency: .regular,
            emotionalConnection: 8,
            totalInteractions: 80,
            lastInteractionDate: Date().addingTimeInterval(-172800),
            recentInteractionDates: [Date().addingTimeInterval(-172800)],
            notes: "话不多但很关心我",
            tags: ["家人"]
        )
        familyDad.familyRole = "parent"
        familyDad.livingTogether = false
        profiles.append(familyDad)
        
        var familySister = RelationshipProfile(
            id: "rel_family_sister",
            type: .family,
            displayName: "小妹",
            avatar: "👧",
            intimacyLevel: 8,
            interactionFrequency: .occasional,
            emotionalConnection: 8,
            totalInteractions: 45,
            lastInteractionDate: Date().addingTimeInterval(-604800),
            recentInteractionDates: [Date().addingTimeInterval(-604800)],
            notes: "在读大学，偶尔聊天",
            tags: ["家人"]
        )
        familySister.familyRole = "sibling"
        familySister.livingTogether = false
        profiles.append(familySister)
        
        // MARK: Friends (朋友)
        var friendSarah = RelationshipProfile(
            id: "rel_friend_sarah",
            type: .friends,
            displayName: "Sarah",
            avatar: "👩‍🦰",
            intimacyLevel: 8,
            interactionFrequency: .regular,
            emotionalConnection: 8,
            totalInteractions: 50,
            lastInteractionDate: Date().addingTimeInterval(-259200),
            recentInteractionDates: [Date().addingTimeInterval(-259200)],
            notes: "大学同学，现在在做设计",
            tags: ["老友", "设计"]
        )
        friendSarah.friendIntimacy = "closeFriend"
        friendSarah.yearsKnown = 8
        profiles.append(friendSarah)
        
        var friendMike = RelationshipProfile(
            id: "rel_friend_mike",
            type: .friends,
            displayName: "老王",
            avatar: "🧔",
            intimacyLevel: 7,
            interactionFrequency: .occasional,
            emotionalConnection: 7,
            totalInteractions: 30,
            lastInteractionDate: Date().addingTimeInterval(-1209600),
            recentInteractionDates: [Date().addingTimeInterval(-1209600)],
            notes: "健身搭子",
            tags: ["运动"]
        )
        friendMike.friendIntimacy = "friend"
        friendMike.yearsKnown = 3
        profiles.append(friendMike)
        
        var friendLily = RelationshipProfile(
            id: "rel_friend_lily",
            type: .friends,
            displayName: "Lily",
            avatar: "👩‍💼",
            intimacyLevel: 6,
            interactionFrequency: .occasional,
            emotionalConnection: 6,
            totalInteractions: 20,
            lastInteractionDate: Date().addingTimeInterval(-2592000),
            recentInteractionDates: [],
            notes: "前同事，偶尔约饭",
            tags: ["前同事"]
        )
        friendLily.friendIntimacy = "acquaintance"
        friendLily.yearsKnown = 2
        profiles.append(friendLily)
        
        // MARK: Colleagues (同事)
        var colleagueManager = RelationshipProfile(
            id: "rel_colleague_manager",
            type: .colleagues,
            displayName: "张总",
            avatar: "👔",
            intimacyLevel: 5,
            interactionFrequency: .frequent,
            emotionalConnection: 4,
            totalInteractions: 100,
            lastInteractionDate: Date(),
            recentInteractionDates: (0..<5).map { Date().addingTimeInterval(TimeInterval(-$0 * 86400)) },
            notes: "直属领导，很支持我的想法",
            tags: ["工作"]
        )
        colleagueManager.workRelationship = "superior"
        colleagueManager.company = "观己科技"
        colleagueManager.department = "产品部"
        profiles.append(colleagueManager)
        
        var colleagueDev = RelationshipProfile(
            id: "rel_colleague_dev",
            type: .colleagues,
            displayName: "小陈",
            avatar: "👨‍💻",
            intimacyLevel: 6,
            interactionFrequency: .daily,
            emotionalConnection: 5,
            totalInteractions: 200,
            lastInteractionDate: Date(),
            recentInteractionDates: (0..<10).map { Date().addingTimeInterval(TimeInterval(-$0 * 86400)) },
            notes: "iOS 开发，配合很默契",
            tags: ["工作", "技术"]
        )
        colleagueDev.workRelationship = "peer"
        colleagueDev.company = "观己科技"
        colleagueDev.department = "研发部"
        profiles.append(colleagueDev)
        
        // MARK: Online Friends (网友)
        var onlineFriend1 = RelationshipProfile(
            id: "rel_online_1",
            type: .onlineFriends,
            displayName: "摄影大神",
            avatar: "📷",
            intimacyLevel: 4,
            interactionFrequency: .occasional,
            emotionalConnection: 4,
            totalInteractions: 15,
            lastInteractionDate: Date().addingTimeInterval(-604800),
            recentInteractionDates: [Date().addingTimeInterval(-604800)],
            notes: "小红书认识的，经常交流摄影技巧",
            tags: ["摄影", "小红书"]
        )
        onlineFriend1.platform = "小红书"
        onlineFriend1.hasMetInPerson = false
        profiles.append(onlineFriend1)
        
        var onlineFriend2 = RelationshipProfile(
            id: "rel_online_2",
            type: .onlineFriends,
            displayName: "跑步群主",
            avatar: "🏃",
            intimacyLevel: 5,
            interactionFrequency: .regular,
            emotionalConnection: 5,
            totalInteractions: 25,
            lastInteractionDate: Date().addingTimeInterval(-172800),
            recentInteractionDates: [Date().addingTimeInterval(-172800), Date().addingTimeInterval(-432000)],
            notes: "跑步群认识的，线下跑过几次",
            tags: ["跑步", "微信"]
        )
        onlineFriend2.platform = "微信"
        onlineFriend2.hasMetInPerson = true
        profiles.append(onlineFriend2)
        
        // MARK: Pet (宠物)
        var pet1 = RelationshipProfile(
            id: "rel_pet_mochi",
            type: .pet,
            displayName: "糯米",
            avatar: "🐱",
            intimacyLevel: 10,
            interactionFrequency: .daily,
            emotionalConnection: 10,
            totalInteractions: 730,
            lastInteractionDate: Date(),
            recentInteractionDates: (0..<30).map { Date().addingTimeInterval(TimeInterval(-$0 * 86400)) },
            notes: "两岁的英短，最喜欢趴在键盘上",
            tags: ["毛孩子"]
        )
        pet1.petType = "cat"
        pet1.petAge = 2
        pet1.petBreed = "英国短毛猫"
        profiles.append(pet1)
        
        return profiles
    }()
    
    /// Get relationship profiles grouped by type
    public static func getRelationshipsByType() -> [CompanionType: [RelationshipProfile]] {
        var grouped: [CompanionType: [RelationshipProfile]] = [:]
        for type in CompanionType.allCases {
            grouped[type] = relationshipProfiles.filter { $0.type == type }
        }
        return grouped
    }
    
    /// Get a specific relationship profile by ID
    public static func getRelationshipProfile(id: String) -> RelationshipProfile? {
        relationshipProfiles.first { $0.id == id }
    }
}
