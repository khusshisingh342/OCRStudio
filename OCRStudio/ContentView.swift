import SwiftUI
import Vision
import UIKit
import AVFoundation

// ==========================================
// 📱 MAIN CONTENT VIEW
// ==========================================
struct ContentView: View {
    // Auth State
    @State private var isLoggedIn = false
    @State private var email = ""
    @State private var password = ""
    
    // Scanner & OCR State
    @State private var selectedImage: UIImage?
    @State private var extractedText = ""
    @State private var isProcessing = false
    @State private var showImagePicker = false
    @State private var pickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var copiedToast = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            if !isLoggedIn {
                loginCardView
                    .transition(.asymmetric(insertion: .move(edge: .leading), removal: .scale))
            } else {
                dashboardView
                    .transition(.asymmetric(insertion: .scale, removal: .move(edge: .trailing)))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isLoggedIn)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: pickerSourceType)
        }
    }

    // ==========================================
    // 🎨 FRONTEND 1: LOGIN PAGE
    // ==========================================
    private var loginCardView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundColor(AppTheme.primaryBlue)
                
                Text("OCR Studio")
                    .font(.title2).bold()
                    .foregroundColor(AppTheme.textDark)
                
                Text("Sign in to scan and extract text")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textMuted)
            }

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Email Address")
                        .font(.caption).bold()
                        .foregroundColor(AppTheme.textDark)
                    TextField("student@college.edu", text: $email)
                        .padding(12)
                        .background(AppTheme.secondaryBlue.opacity(0.6))
                        .cornerRadius(10)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Password")
                        .font(.caption).bold()
                        .foregroundColor(AppTheme.textDark)
                    SecureField("••••••••", text: $password)
                        .padding(12)
                        .background(AppTheme.secondaryBlue.opacity(0.6))
                        .cornerRadius(10)
                }

                Button(action: {
                    if !email.isEmpty && !password.isEmpty {
                        isLoggedIn = true
                    }
                }) {
                    Text("Sign In")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.primaryBlue)
                        .cornerRadius(10)
                }
                .padding(.top, 6)
            }
        }
        .padding(28)
        .frame(maxWidth: 380)
        .background(AppTheme.cardBackground)
        .cornerRadius(18)
        .shadow(color: AppTheme.primaryBlue.opacity(0.12), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 20)
    }

    // ==========================================
    // 🎨 FRONTEND 2: DASHBOARD PAGE
    // ==========================================
    private var dashboardView: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text.viewfinder")
                        .foregroundColor(AppTheme.primaryBlue)
                        .font(.headline)
                    Text("OCR Studio")
                        .font(.headline).bold()
                        .foregroundColor(AppTheme.textDark)
                }
                Spacer()
                Button(action: {
                    isLoggedIn = false
                    selectedImage = nil
                    extractedText = ""
                }) {
                    Text("Logout")
                        .font(.subheadline).bold()
                        .foregroundColor(AppTheme.primaryBlue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppTheme.secondaryBlue)
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(AppTheme.cardBackground)

            Spacer()

            // Main Scanner Container
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("Text Extraction Studio")
                            .font(.title3).bold()
                            .foregroundColor(AppTheme.textDark)
                        Text("Upload or scan an image to convert it into text")
                            .font(.caption)
                            .foregroundColor(AppTheme.textMuted)
                    }

                    // Upload & Camera Buttons
                    HStack(spacing: 12) {
                        Button(action: {
                            pickerSourceType = .photoLibrary
                            showImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "folder.fill")
                                Text("Upload")
                            }
                            .font(.subheadline).bold()
                            .foregroundColor(AppTheme.primaryBlue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppTheme.secondaryBlue)
                            .cornerRadius(10)
                        }

                        Button(action: {
                            checkCameraPermissionAndOpen()
                        }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Camera")
                            }
                            .font(.subheadline).bold()
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppTheme.primaryBlue)
                            .cornerRadius(10)
                        }
                    }

                    // Medium Image Preview
                    if let image = selectedImage {
                        VStack(spacing: 12) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 220)
                                .cornerRadius(10)
                                .padding(8)
                                .background(AppTheme.secondaryBlue.opacity(0.4))
                                .cornerRadius(12)

                            Button(action: { processOCR(on: image) }) {
                                HStack {
                                    if isProcessing {
                                        ProgressView().tint(.white)
                                    } else {
                                        Image(systemName: "sparkles")
                                        Text("Extract Text")
                                    }
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(AppTheme.primaryBlue)
                                .cornerRadius(10)
                            }
                            .disabled(isProcessing)
                        }
                    }

                    // Extracted Output & Compliance View
                    if !extractedText.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            // Rule-Based Compliance Report
                            ComplianceReportView(textToAnalyze: extractedText)
                            
                            // Raw Extracted Text Editor
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Raw OCR Output")
                                        .font(.caption).bold()
                                        .foregroundColor(AppTheme.textDark)
                                    Spacer()
                                    Button(action: {
                                        UIPasteboard.general.string = extractedText
                                        copiedToast = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            copiedToast = false
                                        }
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: copiedToast ? "checkmark" : "doc.on.doc")
                                            Text(copiedToast ? "Copied" : "Copy")
                                        }
                                        .font(.caption2).bold()
                                        .foregroundColor(AppTheme.primaryBlue)
                                    }
                                }

                                TextEditor(text: .constant(extractedText))
                                    .font(.system(.body, design: .monospaced))
                                    .frame(height: 120)
                                    .padding(8)
                                    .background(AppTheme.secondaryBlue.opacity(0.4))
                                    .cornerRadius(10)
                            }
                        }
                    }
                }
                .padding(24)
                .frame(maxWidth: 460)
                .background(AppTheme.cardBackground)
                .cornerRadius(18)
                .shadow(color: AppTheme.primaryBlue.opacity(0.08), radius: 15, x: 0, y: 8)
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            Spacer()
        }
    }

    // ==========================================
    // ⚙️ BACKEND ENGINE: APPLE VISION OCR
    // ==========================================
    private func processOCR(on image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        isProcessing = true
        extractedText = ""

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { request, error in
            DispatchQueue.main.async {
                self.isProcessing = false
                
                if let error = error {
                    self.extractedText = "Error: \(error.localizedDescription)"
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    self.extractedText = "No text recognized."
                    return
                }

                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }

                self.extractedText = recognizedStrings.joined(separator: "\n")
            }
        }
        
        request.recognitionLevel = .accurate
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.extractedText = "Failed to perform OCR: \(error.localizedDescription)"
                }
            }
        }
    }

    // ==========================================
    // 📸 CAMERA PERMISSION ENGINE
    // ==========================================
    private func checkCameraPermissionAndOpen() {
        #if targetEnvironment(simulator)
        print("Running on Simulator: Falling back to Photo Library.")
        pickerSourceType = .photoLibrary
        showImagePicker = true
        #else
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            pickerSourceType = .camera
            showImagePicker = true
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.pickerSourceType = .camera
                        self.showImagePicker = true
                    } else {
                        self.pickerSourceType = .photoLibrary
                        self.showImagePicker = true
                    }
                }
            }
            
        case .denied, .restricted:
            print("Camera access denied or restricted in iOS Settings.")
            pickerSourceType = .photoLibrary
            showImagePicker = true
            
        @unknown default:
            pickerSourceType = .photoLibrary
            showImagePicker = true
        }
        #endif
    }
}
