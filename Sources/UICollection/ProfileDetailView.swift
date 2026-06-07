//
//  ProfileDetailView.swift
//  UICollection
//
//  Created by Jiaxin Pang on 2026/6/7.
//

import Foundation
import PhotosUI
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

@MainActor
public protocol ProfileDetailViewContent: DynamicProperty {
    var avatarURL: URL { get }
    var userName: Binding<String> { get }
    var userPronouns: Binding<String> { get }
    var userBio: Binding<String> { get }
    var journalingFocus: Binding<String> { get }
    var profileNotes: Binding<String> { get }
    var countryDisplay: String? { get }
    var birthdayDisplay: String? { get }
    var constellation: ProfileDetailConstellation? { get }

    func saveAvatarData(_ data: Data) async
}

public struct ProfileDetailConstellation: Equatable, Sendable {
    public let name: String
    public let symbol: String

    public init(name: String, symbol: String) {
        self.name = name
        self.symbol = symbol
    }
}

public struct ProfileDetailView<Content: ProfileDetailViewContent>: View {
    @State private var photosPickerItem: PhotosPickerItem?
    private var content: Content

    public init(content: Content) {
        self.content = content
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                identityCard
                aboutCard
                journalGuidanceCard
                personalDetailsCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 80)
        }
        .background(profileBackground)
        .navigationTitle(Text("Profile", bundle: .module))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onChange(of: photosPickerItem) { _, item in
            guard let item else { return }
            photosPickerItem = nil
            Task { await saveAvatar(from: item) }
        }
    }

    @ViewBuilder
    private var profileBackground: some View {
        #if canImport(UIKit)
        Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
        #elseif canImport(AppKit)
        Color(nsColor: .windowBackgroundColor).ignoresSafeArea()
        #else
        Color.clear.ignoresSafeArea()
        #endif
    }

    private var identityCard: some View {
        // Capture the URL up-front: `PhotosPicker`'s label closure is
        // `@Sendable`, so it can't reach into a main-actor-isolated
        // computed property at render time.
        let url = content.avatarURL
        return VStack(spacing: 16) {
            PhotosPicker(selection: $photosPickerItem, matching: .images, photoLibrary: .shared()) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .empty:
                        ProgressView()
                    case .failure:
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.teal.gradient)
                    @unknown default:
                        Color.clear
                    }
                }
                .frame(width: 96, height: 96)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(.separator, lineWidth: 0.5)
                }
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(uiCollectionText("Change avatar"))

            VStack(spacing: 8) {
                TextField(
                    UICollectionLocalization.string("Add your name"),
                    text: content.userName,
                    prompt: uiCollectionText("Add your name")
                )
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.plain)
                    .submitLabel(.done)

                TextField(
                    UICollectionLocalization.string("Pronouns"),
                    text: content.userPronouns,
                    prompt: uiCollectionText("Pronouns")
                )
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.plain)
                    .submitLabel(.done)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .dashboardCard()
    }

    private func saveAvatar(from item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        await content.saveAvatarData(data)
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            ProfileSectionHeader(title: "About")

            EditableProfileField(
                icon: "text.bubble.fill",
                tint: .teal,
                label: "Bio",
                placeholder: "A short bio or intention",
                text: content.userBio,
                lineLimit: 2...5
            )
        }
        .padding(16)
        .dashboardCard()
    }

    private var journalGuidanceCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            ProfileSectionHeader(title: "Journal Guidance")

            EditableProfileField(
                icon: "scope",
                tint: .blue,
                label: "Journal Focus",
                placeholder: "What you want this journal to help with",
                text: content.journalingFocus,
                lineLimit: 2...5
            )

            Divider().padding(.leading, 52)

            EditableProfileField(
                icon: "person.text.rectangle.fill",
                tint: .purple,
                label: "Personal Context",
                placeholder: "Background the assistant should remember",
                text: content.profileNotes,
                lineLimit: 3...8
            )
        }
        .padding(16)
        .dashboardCard()
    }

    private var personalDetailsCard: some View {
        let sign = content.constellation
        return VStack(alignment: .leading, spacing: 0) {
            ProfileSectionHeader(title: "Personal Details")

            LockedProfileRow(
                icon: "mappin.and.ellipse",
                tint: .red,
                label: "Country",
                value: content.countryDisplay
            )

            Divider().padding(.leading, 52)

            LockedProfileRow(
                icon: "gift.fill",
                tint: .pink,
                label: "Birthday",
                value: content.birthdayDisplay
            )

            Divider().padding(.leading, 52)

            LockedProfileRow(
                icon: sign?.symbol ?? "sparkles",
                tint: .indigo,
                label: "Constellation",
                value: sign?.name,
                isSystemImage: sign == nil
            )
        }
        .padding(16)
        .dashboardCard()
    }
}

private struct ProfileSectionHeader: View {
    var title: LocalizedStringKey

    var body: some View {
        Text(title, bundle: .module)
            .font(.caption2.weight(.semibold))
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
            .padding(.bottom, 10)
    }
}

private struct EditableProfileField: View {
    var icon: String
    var tint: Color
    var label: LocalizedStringKey
    var placeholder: LocalizedStringKey
    @Binding var text: String
    var lineLimit: ClosedRange<Int>

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ProfileFieldIcon(icon: icon, tint: tint)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 6) {
                Text(label, bundle: .module)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                TextField(
                    "",
                    text: $text,
                    prompt: Text(placeholder, bundle: .module),
                    axis: .vertical
                )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(lineLimit)
                    .textFieldStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
    }
}

private struct LockedProfileRow: View {
    var icon: String
    var tint: Color
    var label: LocalizedStringKey
    var value: String?
    var isSystemImage = true

    var body: some View {
        HStack(spacing: 12) {
            ProfileFieldIcon(icon: icon, tint: tint, isSystemImage: isSystemImage)

            VStack(alignment: .leading, spacing: 3) {
                Text(label, bundle: .module)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                if let value {
                    Text(value)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                } else {
                    uiCollectionText("Not set")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
                }
            }

            Spacer(minLength: 12)

            Image(systemName: "sparkles")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 12)
    }
}

private struct ProfileFieldIcon: View {
    var icon: String
    var tint: Color
    var isSystemImage = true

    var body: some View {
        Group {
            if isSystemImage {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
            } else {
                Text(icon)
                    .font(.system(size: 18, weight: .semibold))
            }
        }
        .foregroundStyle(tint)
        .frame(width: 36, height: 36)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }
}
