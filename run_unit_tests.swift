#!/usr/bin/env swift

import Foundation

print("=" + String(repeating: "=", count: 69))
print("Running Data Layer Unit Tests")
print("=" + String(repeating: "=", count: 69))
print("")

// Test files to compile and run
let testFiles = [
    "Tests/ProfileInsightModelsTests.swift",
    "Tests/InsightRepositoryTests.swift"
]

let sourceFiles = [
    "guanji0.34/Core/Models/ProfileInsightModels.swift",
    "guanji0.34/DataLayer/Repositories/InsightRepository.swift"
]

print("Compiling test files...")
print("")

// Create a temporary directory for compilation
let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("guanji_tests_\(UUID().uuidString)")
try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

// Compile command
let compileArgs = [
    "swiftc",
    "-sdk", "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk",
    "-target", "x86_64-apple-ios16.1-simulator",
    "-F", "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks",
    "-I", "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib",
    "-o", tempDir.appendingPathComponent("test_runner").path
] + testFiles + sourceFiles

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
process.arguments = compileArgs

do {
    try process.run()
    process.waitUntilExit()
    
    if process.terminationStatus == 0 {
        print("✅ Compilation successful")
        print("")
        print("Running tests...")
        print("")
        
        // Run the compiled test binary
        let runProcess = Process()
        runProcess.executableURL = tempDir.appendingPathComponent("test_runner")
        try runProcess.run()
        runProcess.waitUntilExit()
        
        if runProcess.terminationStatus == 0 {
            print("")
            print("✅ All tests passed!")
        } else {
            print("")
            print("❌ Some tests failed")
        }
    } else {
        print("❌ Compilation failed")
    }
} catch {
    print("Error: \(error)")
}

// Cleanup
try? FileManager.default.removeItem(at: tempDir)

print("")
print("=" + String(repeating: "=", count: 69))
