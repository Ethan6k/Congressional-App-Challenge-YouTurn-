//
//  FutureImageGenerator.swift
//  TestApp
//
//  Sends a prompt (and optionally a reference photo) to Gemini through
//  Firebase AI Logic and holds the resulting image. The app uses one of
//  these per future scenario. Prompts are built in FutureScenario.swift.
//

import Combine
import FirebaseAILogic
import Foundation
import SwiftUI
import UIKit

@MainActor
final class FutureImageGenerator: ObservableObject {
    @Published private(set) var image: UIImage?
    @Published private(set) var isGenerating = false
    @Published private(set) var errorMessage: String?

    /// Generates an image and returns it (or nil if it failed).
    @discardableResult
    func generate(prompt: String, referenceImage: UIImage? = nil) async -> UIImage? {
        isGenerating = true
        errorMessage = nil

        defer { isGenerating = false }

        do {
            let ai = FirebaseAI.firebaseAI(backend: .googleAI())
            let model = ai.generativeModel(
                modelName: "gemini-3.1-flash-image",
                generationConfig: GenerationConfig(
                    responseModalities: [.image],
                    imageConfig: ImageConfig(aspectRatio: .portrait3x4)
                )
            )

            // Send the reference photo along with the prompt when there is one.
            let response: GenerateContentResponse
            if let referenceImage {
                response = try await model.generateContent(referenceImage, prompt)
            } else {
                response = try await model.generateContent(prompt)
            }

            guard let imageData = response.inlineDataParts.first?.data,
                  let generatedImage = UIImage(data: imageData) else {
                errorMessage = "No image was returned. Please try again."
                return nil
            }

            image = generatedImage
            return generatedImage
        } catch {
            print("Firebase AI image generation failed: \(error)")
            errorMessage = "Image generation failed: \(error.localizedDescription)"
            return nil
        }
    }

    /// Shows a previously saved image (e.g. when the app reopens).
    func show(_ savedImage: UIImage?) {
        image = savedImage
    }

    /// Clears the image (e.g. when the user picks a different time frame).
    func reset() {
        image = nil
        errorMessage = nil
    }

    func clearError() {
        errorMessage = nil
    }
}
