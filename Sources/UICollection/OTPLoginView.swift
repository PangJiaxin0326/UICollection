//
//  OTPLoginView.swift
//  UICollection
//
//  Created by Jiaxin Pang on 2026/5/20.
//

import Foundation
import SwiftUI

struct OTPLoginView: View {
    @State private var mobileNumber = ""
    @State private var countryCode: Country?
    @State private var showVerificationView = false
    @FocusState private var focusedField: Field?

    private let termsOfServiceURL: URL?
    private let privacyPolicyURL: URL?
    private let sendCode: (String) async throws -> Void
    private let verifyCode: (String, String) async throws -> Void
    private let onAuthenticate: (String) async throws -> Void

    private enum Field: Hashable {
        case mobileNumber
    }

    public init(
        termsOfServiceURL: URL? = nil,
        privacyPolicyURL: URL? = nil,
        sendCode: @escaping (String) async throws -> Void,
        verifyCode: @escaping (String, String) async throws -> Void,
        onAuthenticate: @escaping (String) async throws -> Void
    ) {
        self.termsOfServiceURL = termsOfServiceURL
        self.privacyPolicyURL = privacyPolicyURL
        self.sendCode = sendCode
        self.verifyCode = verifyCode
        self.onAuthenticate = onAuthenticate
    }

    private var trimmedMobileNumber: String {
        mobileNumber.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var phoneDigits: String {
        trimmedMobileNumber.filter(\.isNumber)
    }

    private var canRequestCode: Bool {
        phoneDigits.isEmpty == false
    }

    private var verificationIdentity: String {
        trimmedMobileNumber
    }

    private var verificationRecipient: String {
        guard let dialCode = countryCode?.dialCode,
              dialCode.isEmpty == false,
              phoneDigits.isEmpty == false
        else {
            return trimmedMobileNumber
        }

        return dialCode + phoneDigits
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerField
            loginField
            sendButton
            Spacer(minLength: 0)
            legalAgreements
        }
        .padding([.horizontal, .top], 20)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            Color.clear
                .contentShape(.rect)
                .onTapGesture {
                    focusedField = nil
                }
        }
        .sheet(isPresented: $showVerificationView) {
            VerificationView(
                recipient: verificationRecipient,
                identity: verificationIdentity,
                sendCode: sendCode,
                verifyCode: verifyCode,
                onAuthenticate: onAuthenticate
            )
            .padding(.horizontal, 30)
            .padding(.bottom, 20)
        }
    }

    private var headerField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome Back")
                .font(.largeTitle)

            Text("Please verify your phone number to continue.")
                .font(.callout)
        }
        .fontWeight(.medium)
        .padding(.top, 5)
    }

    private var loginField: some View {
        HStack(spacing: 8) {
            CountryCodePicker(selection: $countryCode)
                .frame(height: 50)
                .background(.ultraThinMaterial)
                .clipShape(.capsule)

            HStack(spacing: 5) {
                Image(systemName: "phone.fill")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(width: 30)
                    .accessibilityHidden(true)

                mobileNumberField
            }
            .frame(height: 50)
            .background(.ultraThinMaterial)
            .clipShape(.capsule)
        }
        .padding(.top, 10)
    }

    @ViewBuilder
    private var mobileNumberField: some View {
#if os(iOS)
        TextField("Mobile Number", text: $mobileNumber)
            .textContentType(.telephoneNumber)
            .keyboardType(.phonePad)
            .focused($focusedField, equals: .mobileNumber)
            .padding(.horizontal, 12)
#else
        TextField("Mobile Number", text: $mobileNumber)
            .textContentType(.telephoneNumber)
            .focused($focusedField, equals: .mobileNumber)
            .padding(.horizontal, 12)
#endif
    }

    private var sendButton: some View {
        Button {
            guard canRequestCode else { return }
            showVerificationView = true
        } label: {
            Text("Send Code")
                .font(.callout)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.glassProminent)
        .disabled(canRequestCode == false)
    }

    @ViewBuilder
    private var legalAgreements: some View {
        if termsOfServiceURL != nil || privacyPolicyURL != nil {
            HStack(spacing: 4) {
                if let termsOfServiceURL {
                    Link("Terms of Service", destination: termsOfServiceURL)
                        .underline()
                }

                if termsOfServiceURL != nil, privacyPolicyURL != nil {
                    Text("&")
                }

                if let privacyPolicyURL {
                    Link("Privacy Policy", destination: privacyPolicyURL)
                        .underline()
                }
            }
            .font(.callout)
            .fontWeight(.medium)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
        }
    }
}

/// VerificationField
extension OTPLoginView {
    enum CodeType: Int, CaseIterable {
        case four = 4
        case six = 6
    }

    enum TypingState {
        case typing
        case valid
        case invalid
    }

    enum TextFieldStyle: String, CaseIterable {
        case roundedBorder = "Rounded Border"
        case underlined = "Underlined"
    }

    struct VerificationField: View {
        var type: CodeType
        var style: TextFieldStyle = .roundedBorder
        @Binding var value: String
        var validate: (String) async -> TypingState

        @State private var state: TypingState = .typing
        @State private var invalidTrigger = false
        @State private var validationTask: Task<Void, Never>?
        @FocusState private var isActive: Bool

        var body: some View {
            HStack(spacing: style == .roundedBorder ? 6 : 10) {
                ForEach(0..<type.rawValue, id: \.self) { index in
                    CharacterView(index)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: value)
            .animation(.easeInOut(duration: 0.2), value: isActive)
            .compositingGroup()
            .phaseAnimator([0, 10, -10, -10, -5, 5, 0], trigger: invalidTrigger) { content, offset in
                content.offset(x: offset)
            } animation: { _ in
                .linear(duration: 0.06)
            }
            .background {
                hiddenTextField
            }
            .contentShape(.rect)
            .onTapGesture {
                isActive = true
            }
            .onChange(of: value) { _, newValue in
                handleValueChange(newValue)
            }
            .onDisappear {
                validationTask?.cancel()
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Verification code")
            .accessibilityValue(accessibilityValue)
            .accessibilityAddTraits(.isButton)
        }

        @ViewBuilder
        private var hiddenTextField: some View {
#if os(iOS)
            TextField("", text: $value)
                .focused($isActive)
                .textContentType(.oneTimeCode)
                .keyboardType(.numberPad)
                .mask(alignment: .trailing) {
                    Rectangle()
                        .frame(width: 1, height: 1)
                        .opacity(0.01)
                }
                .allowsHitTesting(false)
#else
            TextField("", text: $value)
                .focused($isActive)
                .textContentType(.oneTimeCode)
                .mask(alignment: .trailing) {
                    Rectangle()
                        .frame(width: 1, height: 1)
                        .opacity(0.01)
                }
                .allowsHitTesting(false)
#endif
        }

        private var accessibilityValue: String {
            if value.isEmpty {
                return "No digits entered"
            }

            return "\(value.count) of \(type.rawValue) digits entered"
        }

        private func handleValueChange(_ newValue: String) {
            let sanitizedValue = Self.sanitizedCode(newValue, maximumLength: type.rawValue)
            guard sanitizedValue == newValue else {
                value = sanitizedValue
                return
            }

            validationTask?.cancel()
            state = .typing

            guard sanitizedValue.count == type.rawValue else {
                return
            }

            validationTask = Task { @MainActor in
                let validationState = await validate(sanitizedValue)
                guard Task.isCancelled == false, value == sanitizedValue else {
                    return
                }

                state = validationState
                if validationState == .invalid {
                    invalidTrigger.toggle()
                }
            }
        }

        private func CharacterView(_ index: Int) -> some View {
            Group {
                if style == .roundedBorder {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(borderColor(index), lineWidth: 2)
                } else {
                    VStack(spacing: 0) {
                        Spacer()
                        Rectangle()
                            .fill(borderColor(index))
                            .frame(height: 1)
                    }
                }
            }
            .frame(height: 50)
            .overlay {
                let stringValue = string(index)
                if stringValue.isEmpty == false {
                    Text(stringValue)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                        .transition(.blurReplace)
                }
            }
            .frame(maxWidth: .infinity)
        }

        private func string(_ index: Int) -> String {
            guard value.count > index else {
                return ""
            }

            let stringIndex = value.index(value.startIndex, offsetBy: index)
            return String(value[stringIndex])
        }

        private func borderColor(_ index: Int) -> Color {
            switch state {
            case .typing:
                value.count == index && isActive ? Color.primary : .gray
            case .valid:
                .green
            case .invalid:
                .red
            }
        }

        private nonisolated static func sanitizedCode(_ code: String, maximumLength: Int) -> String {
            String(code.filter(\.isNumber).prefix(maximumLength))
        }
    }

}

/// VerificationView
extension OTPLoginView {
    struct VerificationView: View {
        let recipient: String
        let identity: String

        @Environment(\.dismiss) private var dismiss
        @State private var isCodeSent = false
        @State private var code = ""
        @State private var alertMessage = ""
        @State private var showAlert = false
        @State private var showSuccessBlur = false
        @State private var isProcessingCode = false
        @State private var currentValidationID = 0

        private let sendCode: (String) async throws -> Void
        private let verifyCode: (String, String) async throws -> Void
        private let onAuthenticate: (String) async throws -> Void
        private let codeType: CodeType = .six

        init(
            recipient: String,
            identity: String,
            sendCode: @escaping (String) async throws -> Void,
            verifyCode: @escaping (String, String) async throws -> Void,
            onAuthenticate: @escaping (String) async throws -> Void
        ) {
            self.recipient = recipient
            self.identity = identity
            self.sendCode = sendCode
            self.verifyCode = verifyCode
            self.onAuthenticate = onAuthenticate
        }

        var body: some View {
            ZStack {
                if isCodeSent {
                    VerificationContent
                        .geometryGroup()
                        .transition(.blurReplace)
                } else {
                    SendingContent
                        .geometryGroup()
                        .transition(.blurReplace)
                }
            }
            .overlay {
                if isProcessingCode {
                    ProgressView()
                        .controlSize(.large)
                        .accessibilityLabel("Verifying code")
                }
            }
            .blur(radius: showSuccessBlur ? 14 : 0)
            .presentationDetents([.height(190)])
            .presentationBackground(.background)
            .interactiveDismissDisabled()
            .task {
                await sendVerificationCode()
            }
            .alert("Authentication Error", isPresented: $showAlert) {
                Button("OK") {
                    if isCodeSent == false {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }

        private var VerificationContent: some View {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Verification")
                        .font(.largeTitle)

                    Text("Enter the 6 digit code.")
                        .font(.callout)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .fontWeight(.medium)
                .overlay(alignment: .trailing) {
                    Button("Close", systemImage: "xmark.circle.fill") {
                        dismiss()
                    }
                    .labelStyle(.iconOnly)
                    .font(.title)
                    .tint(.gray)
                    .accessibilityLabel("Close verification")
                    .offset(x: 10, y: -15)
                }
                .padding(.top, 10)

                VerificationField(type: codeType, value: $code) { updatedCode in
                    await validate(code: updatedCode)
                }
                .padding(.top, 12)
            }
        }

        private var SendingContent: some View {
            VStack(spacing: 12) {
                let symbols = ["iphone", "ellipsis.message.fill", "paperplane.fill"]
                PhaseAnimator(symbols) { symbol in
                    Image(systemName: symbol)
                        .font(.system(size: 100))
                        .contentTransition(.symbolEffect)
                        .frame(width: 150, height: 150)
                        .accessibilityHidden(true)
                } animation: { _ in
                    .linear(duration: 1.2)
                }
                .frame(height: 150)

                Text("Sending Verification Code...")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
        }

        private func sendVerificationCode() async {
            guard isCodeSent == false else { return }

            do {
                try await sendCode(recipient)
                withAnimation(.easeInOut(duration: 0.2)) {
                    isCodeSent = true
                }
            } catch {
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }

        private func validate(code: String) async -> TypingState {
            guard code.count == codeType.rawValue else {
                return .typing
            }

            currentValidationID &+= 1
            let validationID = currentValidationID
            isProcessingCode = true
            defer {
                if currentValidationID == validationID {
                    isProcessingCode = false
                }
            }

            do {
                try Task.checkCancellation()
                try await verifyCode(recipient, code)
                try Task.checkCancellation()
                try await onAuthenticate(identity)
                try Task.checkCancellation()
                guard currentValidationID == validationID else {
                    return .typing
                }

                withAnimation(.easeInOut(duration: 0.2)) {
                    showSuccessBlur = true
                }

                try await Task.sleep(for: .seconds(0.35))
                try Task.checkCancellation()
                dismiss()
                return .valid
            } catch is CancellationError {
                return .typing
            } catch {
                guard currentValidationID == validationID else {
                    return .typing
                }

                alertMessage = error.localizedDescription
                showAlert = true
                return .invalid
            }
        }
    }
}

/// CountryCodePicker
extension OTPLoginView {
    struct Country: Identifiable, Codable, Hashable, Sendable {
        var id: String { code }

        let name: String
        let dialCode: String?
        let code: String
    }

    private enum CountryRepository {
        static let countries: [Country] = loadCountries()

        private static func loadCountries() -> [Country] {
            guard let url = Bundle.module.url(forResource: "CountryCodes", withExtension: "json") else {
                return []
            }

            do {
                let jsonData = try Data(contentsOf: url)
                let countries = try JSONDecoder().decode([Country].self, from: jsonData)
                return countries.filter { $0.dialCode?.isEmpty == false }
            } catch {
                return []
            }
        }
    }

    struct CountryCodePicker: View {
        @Binding var selection: Country?
        @Environment(\.locale) private var locale

        private let countries = CountryRepository.countries

        var body: some View {
            Picker("Country code", selection: $selection) {
                ForEach(countries) { country in
                    if let dialCode = country.dialCode {
                        Text("\(dialCode) (\(country.code))")
                            .tag(country as Country?)
                    }
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .tint(.primary)
            .accessibilityLabel("Country code")
            .onAppear(perform: selectDefaultCountryIfNeeded)
        }

        private func selectDefaultCountryIfNeeded() {
            guard selection == nil else {
                return
            }

            if let localeIdentifier = locale.region?.identifier,
               let localeCountry = countries.first(where: { $0.code == localeIdentifier }) {
                selection = localeCountry
            } else {
                selection = countries.first
            }
        }
    }
}


#Preview {
    OTPLoginView { _ in
    } verifyCode: { _, _ in
    } onAuthenticate: { _ in
    }
}
