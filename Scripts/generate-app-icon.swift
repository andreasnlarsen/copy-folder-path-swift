#!/usr/bin/env swift

import CoreGraphics
import ImageIO
import Foundation
import UniformTypeIdentifiers

struct IconSlot {
    let filename: String
    let pixels: Int
    let icnsType: String
}

let slots = [
    IconSlot(filename: "icon_16x16.png", pixels: 16, icnsType: "icp4"),
    IconSlot(filename: "icon_16x16@2x.png", pixels: 32, icnsType: "ic11"),
    IconSlot(filename: "icon_32x32.png", pixels: 32, icnsType: "icp5"),
    IconSlot(filename: "icon_32x32@2x.png", pixels: 64, icnsType: "ic12"),
    IconSlot(filename: "icon_128x128.png", pixels: 128, icnsType: "ic07"),
    IconSlot(filename: "icon_128x128@2x.png", pixels: 256, icnsType: "ic13"),
    IconSlot(filename: "icon_256x256.png", pixels: 256, icnsType: "ic08"),
    IconSlot(filename: "icon_256x256@2x.png", pixels: 512, icnsType: "ic14"),
    IconSlot(filename: "icon_512x512.png", pixels: 512, icnsType: "ic09"),
    IconSlot(filename: "icon_512x512@2x.png", pixels: 1024, icnsType: "ic10")
]

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let sourceURL = root.appendingPathComponent("Resources/AppIconSource.png")
let iconsetURL = root.appendingPathComponent("Resources/AppIcon.iconset")
let icnsURL = root.appendingPathComponent("Resources/AppIcon.icns")

guard
    let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
    let sourceImage = CGImageSourceCreateImageAtIndex(source, 0, nil)
else {
    fatalError("Could not read \(sourceURL.path)")
}

try? FileManager.default.removeItem(at: iconsetURL)
try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

for slot in slots {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil,
        width: slot.pixels,
        height: slot.pixels,
        bitsPerComponent: 8,
        bytesPerRow: slot.pixels * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        fatalError("Could not create context for \(slot.filename)")
    }

    context.interpolationQuality = .high
    context.clear(CGRect(x: 0, y: 0, width: slot.pixels, height: slot.pixels))
    context.draw(sourceImage, in: CGRect(x: 0, y: 0, width: slot.pixels, height: slot.pixels))

    guard let outputImage = context.makeImage() else {
        fatalError("Could not render \(slot.filename)")
    }

    let outputURL = iconsetURL.appendingPathComponent(slot.filename)
    guard let destination = CGImageDestinationCreateWithURL(
        outputURL as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else {
        fatalError("Could not create destination for \(slot.filename)")
    }

    CGImageDestinationAddImage(destination, outputImage, nil)
    guard CGImageDestinationFinalize(destination) else {
        fatalError("Could not write \(slot.filename)")
    }
}

var chunks = Data()

for slot in slots {
    let pngData = try Data(contentsOf: iconsetURL.appendingPathComponent(slot.filename))
    appendFourCharacterCode(slot.icnsType, to: &chunks)
    appendBigEndianUInt32(UInt32(pngData.count + 8), to: &chunks)
    chunks.append(pngData)
}

var icnsData = Data()
appendFourCharacterCode("icns", to: &icnsData)
appendBigEndianUInt32(UInt32(chunks.count + 8), to: &icnsData)
icnsData.append(chunks)
try icnsData.write(to: icnsURL, options: .atomic)

private func appendFourCharacterCode(_ string: String, to data: inout Data) {
    precondition(string.utf8.count == 4)
    data.append(contentsOf: string.utf8)
}

private func appendBigEndianUInt32(_ value: UInt32, to data: inout Data) {
    var bigEndianValue = value.bigEndian
    withUnsafeBytes(of: &bigEndianValue) { bytes in
        data.append(contentsOf: bytes)
    }
}
