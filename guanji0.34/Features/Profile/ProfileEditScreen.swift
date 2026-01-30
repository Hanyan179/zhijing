import SwiftUI
import Combine

/// 个人资料编辑页面
/// Requirements: 1.4 - WHEN the user taps the header, THE Profile_Screen SHALL navigate to a profile edit screen
/// 
/// 此页面用于编辑用户的静态核心信息 (StaticCore)：
/// - 基本身份：昵称、头像、性别、出生年月、籍贯、常居地
/// - 职业信息：职业、行业、学历
///
/// 数据持久化：NarrativeUserProfileRepository -> narrative_user_profile.json
public struct ProfileEditScreen: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ProfileEditViewModel()
    
    public init() {}
    
    public var body: some View {
        List {
            // MARK: - 头像和昵称
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        // 头像
                        Circle()
                            .fill(Colors.slateLight)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.largeTitle)
                                    .foregroundStyle(Colors.indigo)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Colors.indigo.opacity(0.3), lineWidth: 2)
                            )
                        
                        Text(Localization.tr("Profile.TapToChangeAvatar"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
                
                HStack {
                    Label {
                        Text(Localization.tr("Profile.Nickname"))
                    } icon: {
                        Image(systemName: "person.text.rectangle")
                            .foregroundStyle(Colors.indigo)
                    }
                    Spacer()
                    TextField(Localization.tr("Profile.NicknamePlaceholder"), text: $viewModel.nickname)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.primary)
                }
            }
            
            // MARK: - 基本信息
            Section(header: Text(Localization.tr("Profile.BasicInfo"))) {
                // 性别
                HStack {
                    Label {
                        Text(Localization.tr("field_gender"))
                    } icon: {
                        Image(systemName: "person.fill")
                            .foregroundStyle(Colors.indigo)
                    }
                    Spacer()
                    Picker("", selection: $viewModel.selectedGender) {
                        Text(Localization.tr("Profile.NotSet")).tag(nil as Gender?)
                        ForEach(Gender.allCases, id: \.self) { gender in
                            Text(gender.displayName).tag(gender as Gender?)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Colors.indigo)
                }
                
                // 出生年月
                HStack {
                    Label {
                        Text(Localization.tr("field_birthDate"))
                    } icon: {
                        Image(systemName: "calendar")
                            .foregroundStyle(Colors.indigo)
                    }
                    Spacer()
                    TextField("YYYY-MM", text: $viewModel.birthYearMonth)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numbersAndPunctuation)
                }
                
                // 籍贯
                HStack {
                    Label {
                        Text(Localization.tr("field_hometown"))
                    } icon: {
                        Image(systemName: "house")
                            .foregroundStyle(Colors.indigo)
                    }
                    Spacer()
                    TextField(Localization.tr("Profile.HometownPlaceholder"), text: $viewModel.hometown)
                        .multilineTextAlignment(.trailing)
                }
                
                // 常居地
                HStack {
                    Label {
                        Text(Localization.tr("field_currentCity"))
                    } icon: {
                        Image(systemName: "building.2")
                            .foregroundStyle(Colors.indigo)
                    }
                    Spacer()
                    TextField(Localization.tr("Profile.CurrentCityPlaceholder"), text: $viewModel.currentCity)
                        .multilineTextAlignment(.trailing)
                }
            }
            
            // MARK: - 职业信息
            Section(header: Text(Localization.tr("Profile.CareerInfo"))) {
                // 职业
                HStack {
                    Label {
                        Text(Localization.tr("field_occupation"))
                    } icon: {
                        Image(systemName: "briefcase")
                            .foregroundStyle(Colors.indigo)
                    }
                    Spacer()
                    TextField(Localization.tr("Profile.OccupationPlaceholder"), text: $viewModel.occupation)
                        .multilineTextAlignment(.trailing)
                }
                
                // 行业
                HStack {
                    Label {
                        Text(Localization.tr("field_industry"))
                    } icon: {
                        Image(systemName: "building")
                            .foregroundStyle(Colors.indigo)
                    }
                    Spacer()
                    TextField(Localization.tr("Profile.IndustryPlaceholder"), text: $viewModel.industry)
                        .multilineTextAlignment(.trailing)
                }
                
                // 学历
                HStack {
                    Label {
                        Text(Localization.tr("field_education"))
                    } icon: {
                        Image(systemName: "graduationcap")
                            .foregroundStyle(Colors.indigo)
                    }
                    Spacer()
                    Picker("", selection: $viewModel.selectedEducation) {
                        Text(Localization.tr("Profile.NotSet")).tag(nil as Education?)
                        ForEach(Education.allCases, id: \.self) { edu in
                            Text(edu.displayName).tag(edu as Education?)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Colors.indigo)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(Localization.tr("Profile.EditProfile"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadProfile()
        }
        .onDisappear {
            viewModel.saveProfile()
        }
    }
}

// MARK: - ViewModel

/// ViewModel for ProfileEditScreen
/// Handles data binding and persistence via NarrativeUserProfileRepository
final class ProfileEditViewModel: ObservableObject {
    @Published var nickname: String = ""
    @Published var selectedGender: Gender? = nil
    @Published var birthYearMonth: String = ""
    @Published var hometown: String = ""
    @Published var currentCity: String = ""
    @Published var occupation: String = ""
    @Published var industry: String = ""
    @Published var selectedEducation: Education? = nil
    
    private let repository = NarrativeUserProfileRepository.shared
    private var originalProfile: NarrativeUserProfile?
    
    func loadProfile() {
        let profile = repository.load()
        originalProfile = profile
        
        // Load StaticCore fields
        let core = profile.staticCore
        nickname = core.nickname ?? ""
        selectedGender = core.gender
        birthYearMonth = core.birthYearMonth ?? ""
        hometown = core.hometown ?? ""
        currentCity = core.currentCity ?? ""
        occupation = core.occupation ?? ""
        industry = core.industry ?? ""
        selectedEducation = core.education
    }
    
    func saveProfile() {
        guard var profile = originalProfile else { return }
        
        // Update StaticCore fields
        profile.staticCore.nickname = nickname.isEmpty ? nil : nickname
        profile.staticCore.gender = selectedGender
        profile.staticCore.birthYearMonth = birthYearMonth.isEmpty ? nil : birthYearMonth
        profile.staticCore.hometown = hometown.isEmpty ? nil : hometown
        profile.staticCore.currentCity = currentCity.isEmpty ? nil : currentCity
        profile.staticCore.occupation = occupation.isEmpty ? nil : occupation
        profile.staticCore.industry = industry.isEmpty ? nil : industry
        profile.staticCore.education = selectedEducation
        
        repository.save(profile)
    }
}

#Preview {
    NavigationStack {
        ProfileEditScreen()
    }
}
