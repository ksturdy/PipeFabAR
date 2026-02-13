//
//  QRCodeGenerator.swift
//  PipeFabAR
//
//  Created on 2026-01-31.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

/// Utility for generating QR codes
struct QRCodeGenerator {

    /// Generate a QR code image from a string
    /// - Parameters:
    ///   - string: The string to encode (typically a URL)
    ///   - size: The desired size of the QR code image
    /// - Returns: A UIImage containing the QR code, or nil if generation fails
    static func generateQRCode(from string: String, size: CGSize = CGSize(width: 200, height: 200)) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        // Convert string to data
        guard let data = string.data(using: .utf8) else { return nil }

        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel") // High error correction

        // Get the QR code image
        guard let outputImage = filter.outputImage else { return nil }

        // Scale the image to the desired size
        let scaleX = size.width / outputImage.extent.size.width
        let scaleY = size.height / outputImage.extent.size.height
        let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        // Convert to CGImage then UIImage
        guard let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    /// Generate a SwiftUI Image containing a QR code
    /// - Parameters:
    ///   - string: The string to encode (typically a URL)
    ///   - size: The desired size of the QR code image
    /// - Returns: A SwiftUI Image containing the QR code
    static func generateQRCodeImage(from string: String, size: CGSize = CGSize(width: 200, height: 200)) -> Image {
        if let uiImage = generateQRCode(from: string, size: size) {
            return Image(uiImage: uiImage)
        } else {
            // Return a placeholder if QR generation fails
            return Image(systemName: "qrcode")
        }
    }
}
