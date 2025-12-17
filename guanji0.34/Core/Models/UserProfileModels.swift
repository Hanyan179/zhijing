import Foundation

// MARK: - L3 Layer: User Profile (Semantic Memory)
// ⚠️ DEPRECATED: Use NarrativeUserProfile from NarrativeProfileModels.swift instead
// This model contains score-based fields that cannot be extracted from user diaries.
// Migration: Use ProfileMigrationService to migrate to NarrativeUserProfile.

/// User profile with five-dimension model
/// - Warning: Deprecated. Use `NarrativeUserProfile` instead.
@available(*, deprecated, message: "Use NarrativeUserProfile from NarrativeProfileModels.swift")
public struct UserProfile: Codable, Identifiable {
    public let id: String
    public let createdAt: Date
    public var updatedAt: Date
    
    // Five dimensions
    public var identity: IdentityDimension
    public var personality: PersonalityDimension
    public var social: SocialDimension
    public var competence: CompetenceDimension
    public var lifestyle: LifestyleDimension
    
    public init(
        id: String = UUID().uuidString,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        identity: IdentityDimension = IdentityDimension(),
        personality: PersonalityDimension = PersonalityDimension(),
        social: SocialDimension = SocialDimension(),
        competence: CompetenceDimension = CompetenceDimension(),
        lifestyle: LifestyleDimension = LifestyleDimension()
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.identity = identity
        self.personality = personality
        self.social = social
        self.competence = competence
        self.lifestyle = lifestyle
    }
}

// MARK: - 1. Identity Dimension (身份与生理)

public struct IdentityDimension: Codable {
    public var kernel: IdentityKernel
    public var state: IdentityState
    
    public init(
        kernel: IdentityKernel = IdentityKernel(),
        state: IdentityState = IdentityState()
    ) {
        self.kernel = kernel
        self.state = state
    }
}

public struct IdentityKernel: Codable {
    // Basic info
    public var gender: Gender?
    public var birthDate: String?               // YYYY-MM
    public var height: Int?                     // cm
    public var weight: Int?                     // kg
    public var bloodType: BloodType?
    
    // Physical traits
    public var chronicConditions: [String]
    public var basePhysicalCondition: PhysicalCondition
    public var geneticTraits: [String]?
    
    // Social identity
    public var hometown: String?
    public var currentCity: String?
    public var education: Education?
    public var maritalStatus: MaritalStatus?
    
    public init(
        gender: Gender? = nil,
        birthDate: String? = nil,
        height: Int? = nil,
        weight: Int? = nil,
        bloodType: BloodType? = nil,
        chronicConditions: [String] = [],
        basePhysicalCondition: PhysicalCondition = .normal,
        geneticTraits: [String]? = nil,
        hometown: String? = nil,
        currentCity: String? = nil,
        education: Education? = nil,
        maritalStatus: MaritalStatus? = nil
    ) {
        self.gender = gender
        self.birthDate = birthDate
        self.height = height
        self.weight = weight
        self.bloodType = bloodType
        self.chronicConditions = chronicConditions
        self.basePhysicalCondition = basePhysicalCondition
        self.geneticTraits = geneticTraits
        self.hometown = hometown
        self.currentCity = currentCity
        self.education = education
        self.maritalStatus = maritalStatus
    }
}

public struct IdentityState: Codable {
    // Health status
    public var isSick: Bool
    public var sicknessType: String?
    public var painLocation: String?
    
    // Energy status
    public var bodyEnergy: Int                  // -3 to +3
    public var sleepQuality: SleepQuality
    public var exerciseLevel: ExerciseLevel
    
    // Physical needs
    public var hungerLevel: Int?                // 1-5
    public var thirstLevel: Int?                // 1-5
    public var fatigueLevel: Int?               // 1-5
    
    public var lastUpdatedAt: Date
    
    public init(
        isSick: Bool = false,
        sicknessType: String? = nil,
        painLocation: String? = nil,
        bodyEnergy: Int = 0,
        sleepQuality: SleepQuality = .normal,
        exerciseLevel: ExerciseLevel = .sedentary,
        hungerLevel: Int? = nil,
        thirstLevel: Int? = nil,
        fatigueLevel: Int? = nil,
        lastUpdatedAt: Date = Date()
    ) {
        self.isSick = isSick
        self.sicknessType = sicknessType
        self.painLocation = painLocation
        self.bodyEnergy = bodyEnergy
        self.sleepQuality = sleepQuality
        self.exerciseLevel = exerciseLevel
        self.hungerLevel = hungerLevel
        self.thirstLevel = thirstLevel
        self.fatigueLevel = fatigueLevel
        self.lastUpdatedAt = lastUpdatedAt
    }
}

// MARK: - Identity Enums

public enum Gender: String, Codable {
    case male, female, other
}

public enum BloodType: String, Codable {
    case A, B, AB, O
}

public enum PhysicalCondition: String, Codable {
    case weak, normal, strong
}

public enum Education: String, Codable {
    case highSchool, bachelor, master, phd
}

public enum MaritalStatus: String, Codable {
    case single, dating, married, divorced
}

public enum SleepQuality: String, Codable {
    case insomnia, poor, normal, good
}

public enum ExerciseLevel: String, Codable {
    case sedentary, light, moderate, intense
}

// MARK: - 2. Personality Dimension (性格与心理)

public struct PersonalityDimension: Codable {
    public var kernel: PersonalityKernel
    public var state: PersonalityState
    
    public init(
        kernel: PersonalityKernel = PersonalityKernel(),
        state: PersonalityState = PersonalityState()
    ) {
        self.kernel = kernel
        self.state = state
    }
}

public struct PersonalityKernel: Codable {
    // Standardized models
    public var mbtiType: String?
    public var bigFive: BigFiveScores?
    
    // Core values
    public var valuePriorities: [CoreValue]
    
    // Thinking preferences
    public var decisionMode: DecisionMode
    public var riskPreference: RiskPreference
    
    public init(
        mbtiType: String? = nil,
        bigFive: BigFiveScores? = nil,
        valuePriorities: [CoreValue] = [],
        decisionMode: DecisionMode = .balanced,
        riskPreference: RiskPreference = .moderate
    ) {
        self.mbtiType = mbtiType
        self.bigFive = bigFive
        self.valuePriorities = valuePriorities
        self.decisionMode = decisionMode
        self.riskPreference = riskPreference
    }
}

public struct PersonalityState: Codable {
    // Emotion indices (1-10)
    public var happiness: Int
    public var anxiety: Int
    public var anger: Int
    public var calmness: Int
    
    // Mood state
    public var moodWeather: Int                 // -3 to +3
    public var moodDescription: MoodDescription
    
    // Stressors
    public var currentStressors: [String]
    public var stressLevel: Int                 // 1-10
    
    public var lastUpdatedAt: Date
    
    public init(
        happiness: Int = 5,
        anxiety: Int = 5,
        anger: Int = 5,
        calmness: Int = 5,
        moodWeather: Int = 0,
        moodDescription: MoodDescription = .neutral,
        currentStressors: [String] = [],
        stressLevel: Int = 5,
        lastUpdatedAt: Date = Date()
    ) {
        self.happiness = happiness
        self.anxiety = anxiety
        self.anger = anger
        self.calmness = calmness
        self.moodWeather = moodWeather
        self.moodDescription = moodDescription
        self.currentStressors = currentStressors
        self.stressLevel = stressLevel
        self.lastUpdatedAt = lastUpdatedAt
    }
}

public struct BigFiveScores: Codable {
    public var openness: Int                    // 1-10
    public var conscientiousness: Int           // 1-10
    public var extraversion: Int                // 1-10
    public var agreeableness: Int               // 1-10
    public var neuroticism: Int                 // 1-10
    
    public init(
        openness: Int = 5,
        conscientiousness: Int = 5,
        extraversion: Int = 5,
        agreeableness: Int = 5,
        neuroticism: Int = 5
    ) {
        self.openness = openness
        self.conscientiousness = conscientiousness
        self.extraversion = extraversion
        self.agreeableness = agreeableness
        self.neuroticism = neuroticism
    }
}

// MARK: - Personality Enums

public enum CoreValue: String, Codable, CaseIterable {
    case freedom, family, money, health, achievement
    case love, friendship, knowledge, creativity, security
    
    public var localizedKey: String { "value_\(rawValue)" }
}

public enum DecisionMode: String, Codable {
    case logical, emotional, balanced
}

public enum RiskPreference: String, Codable {
    case conservative, moderate, adventurous
}

public enum MoodDescription: String, Codable {
    case positive, neutral, negative, zen
}

// MARK: - 3. Social Dimension (社会与关系)

public struct SocialDimension: Codable {
    public var kernel: SocialKernel
    public var state: SocialState
    
    public init(
        kernel: SocialKernel = SocialKernel(),
        state: SocialState = SocialState()
    ) {
        self.kernel = kernel
        self.state = state
    }
}

public struct SocialKernel: Codable {
    // Core relationships (RelationshipProfile IDs)
    public var coreRelationshipIDs: [String]
    
    // Social tendencies
    public var socialType: SocialType
    public var socialEnergy: SocialEnergy
    
    // Family structure
    public var familyStructure: FamilyStructure
    
    public init(
        coreRelationshipIDs: [String] = [],
        socialType: SocialType = .passive,
        socialEnergy: SocialEnergy = .ambivert,
        familyStructure: FamilyStructure = .nuclear
    ) {
        self.coreRelationshipIDs = coreRelationshipIDs
        self.socialType = socialType
        self.socialEnergy = socialEnergy
        self.familyStructure = familyStructure
    }
}

public struct SocialState: Codable {
    // Social activity
    public var recentSocialFrequency: SocialFrequency
    public var socialSatisfaction: Int          // 1-10
    
    // Relationship tension
    public var relationshipsImproving: [String] // Person IDs
    public var relationshipsTense: [String]     // Person IDs
    
    // Emotional needs
    public var companionshipNeed: CompanionshipNeed
    
    public var lastUpdatedAt: Date
    
    public init(
        recentSocialFrequency: SocialFrequency = .occasional,
        socialSatisfaction: Int = 5,
        relationshipsImproving: [String] = [],
        relationshipsTense: [String] = [],
        companionshipNeed: CompanionshipNeed = .neutral,
        lastUpdatedAt: Date = Date()
    ) {
        self.recentSocialFrequency = recentSocialFrequency
        self.socialSatisfaction = socialSatisfaction
        self.relationshipsImproving = relationshipsImproving
        self.relationshipsTense = relationshipsTense
        self.companionshipNeed = companionshipNeed
        self.lastUpdatedAt = lastUpdatedAt
    }
}

// MARK: - Social Enums

public enum SocialType: String, Codable {
    case loner, passive, socialButterfly
}

public enum SocialEnergy: String, Codable {
    case introvert, ambivert, extrovert
}

public enum FamilyStructure: String, Codable {
    case nuclear, extended, alone, roommates
}

public enum SocialFrequency: String, Codable {
    case stayHome, occasional, frequent
}

public enum CompanionshipNeed: String, Codable {
    case needAlone, neutral, needCompany
}

// MARK: - 4. Competence Dimension (能力与发展)

public struct CompetenceDimension: Codable {
    public var kernel: CompetenceKernel
    public var state: CompetenceState
    
    public init(
        kernel: CompetenceKernel = CompetenceKernel(),
        state: CompetenceState = CompetenceState()
    ) {
        self.kernel = kernel
        self.state = state
    }
}

public struct CompetenceKernel: Codable {
    // Career info
    public var occupation: String?
    public var industry: String?
    public var employmentStatus: EmploymentStatus
    
    // Core skills
    public var skills: [String]
    public var expertise: String?
    
    // Economic status
    public var consumptionLevel: ConsumptionLevel
    public var debtStatus: DebtStatus
    
    public init(
        occupation: String? = nil,
        industry: String? = nil,
        employmentStatus: EmploymentStatus = .employed,
        skills: [String] = [],
        expertise: String? = nil,
        consumptionLevel: ConsumptionLevel = .medium,
        debtStatus: DebtStatus = .none
    ) {
        self.occupation = occupation
        self.industry = industry
        self.employmentStatus = employmentStatus
        self.skills = skills
        self.expertise = expertise
        self.consumptionLevel = consumptionLevel
        self.debtStatus = debtStatus
    }
}

public struct CompetenceState: Codable {
    // Work load
    public var workIntensity: WorkIntensity
    public var workStatus: WorkStatus
    
    // Current tasks
    public var currentTasks: [String]
    public var taskPressure: Int                // 1-10
    
    // Achievement
    public var achievementStatus: CareerAchievementStatus
    public var careerSatisfaction: Int          // 1-10
    
    public var lastUpdatedAt: Date
    
    public init(
        workIntensity: WorkIntensity = .normal,
        workStatus: WorkStatus = .normal,
        currentTasks: [String] = [],
        taskPressure: Int = 5,
        achievementStatus: CareerAchievementStatus = .neutral,
        careerSatisfaction: Int = 5,
        lastUpdatedAt: Date = Date()
    ) {
        self.workIntensity = workIntensity
        self.workStatus = workStatus
        self.currentTasks = currentTasks
        self.taskPressure = taskPressure
        self.achievementStatus = achievementStatus
        self.careerSatisfaction = careerSatisfaction
        self.lastUpdatedAt = lastUpdatedAt
    }
}

// MARK: - Competence Enums

public enum EmploymentStatus: String, Codable {
    case employed, student, unemployed, freelance
}

public enum ConsumptionLevel: String, Codable {
    case low, medium, high
}

public enum DebtStatus: String, Codable {
    case none, light, moderate, heavy
}

public enum WorkIntensity: String, Codable {
    case slacking, normal, overtime, hellMode
}

public enum WorkStatus: String, Codable {
    case vacation, normal, busy, crunchTime
}

/// Career achievement status (renamed to avoid conflict with AchievementStatus in AuxiliaryModels)
public enum CareerAchievementStatus: String, Codable {
    case frustrated, neutral, praised
}

// MARK: - 5. Lifestyle Dimension (习惯与生活)

public struct LifestyleDimension: Codable {
    public var kernel: LifestyleKernel
    public var state: LifestyleState
    
    public init(
        kernel: LifestyleKernel = LifestyleKernel(),
        state: LifestyleState = LifestyleState()
    ) {
        self.kernel = kernel
        self.state = state
    }
}

public struct LifestyleKernel: Codable {
    // Sleep habits
    public var chronoType: ChronoType
    public var averageSleepHours: Double?
    
    // Hobbies
    public var longTermHobbies: [String]
    public var hobbyIntensity: HobbyIntensity
    
    // Diet preferences
    public var tastePreferences: [String]
    public var dietType: DietType
    public var foodRestrictions: [String]
    
    public init(
        chronoType: ChronoType = .neutral,
        averageSleepHours: Double? = nil,
        longTermHobbies: [String] = [],
        hobbyIntensity: HobbyIntensity = .moderate,
        tastePreferences: [String] = [],
        dietType: DietType = .omnivore,
        foodRestrictions: [String] = []
    ) {
        self.chronoType = chronoType
        self.averageSleepHours = averageSleepHours
        self.longTermHobbies = longTermHobbies
        self.hobbyIntensity = hobbyIntensity
        self.tastePreferences = tastePreferences
        self.dietType = dietType
        self.foodRestrictions = foodRestrictions
    }
}

public struct LifestyleState: Codable {
    // Interest focus
    public var currentInterests: [String]
    public var interestDuration: Int?           // days
    
    // Life events
    public var recentEvents: [String]
    public var eventImpact: EventImpact
    
    // Execution
    public var planCompletionRate: Int          // 1-10
    public var procrastinationLevel: Int        // 1-10
    
    public var lastUpdatedAt: Date
    
    public init(
        currentInterests: [String] = [],
        interestDuration: Int? = nil,
        recentEvents: [String] = [],
        eventImpact: EventImpact = .neutral,
        planCompletionRate: Int = 5,
        procrastinationLevel: Int = 5,
        lastUpdatedAt: Date = Date()
    ) {
        self.currentInterests = currentInterests
        self.interestDuration = interestDuration
        self.recentEvents = recentEvents
        self.eventImpact = eventImpact
        self.planCompletionRate = planCompletionRate
        self.procrastinationLevel = procrastinationLevel
        self.lastUpdatedAt = lastUpdatedAt
    }
}

// MARK: - Lifestyle Enums

public enum ChronoType: String, Codable {
    case morning, neutral, night
}

public enum HobbyIntensity: String, Codable {
    case light, moderate, intense
}

public enum DietType: String, Codable {
    case omnivore, vegetarian, carnivore
}

public enum EventImpact: String, Codable {
    case positive, neutral, negative
}
