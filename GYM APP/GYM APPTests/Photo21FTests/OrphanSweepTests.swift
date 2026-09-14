//
//  OrphanSweepTests.swift
//  GYM APPTests
//
//  Phase 21F regression — sweepOrphanFiles correctly removes only orphan .jpg files.
//

import Testing
import Foundation
@testable import GYM_APP

@Suite("PhotoOrphanSweep")
struct OrphanSweepTests {

    // Creates an isolated PhotoStorageService backed by a temporary directory.
    // The temp directory is cleaned up by the defer block inside the helper closure.
    private func withTempStorage(
        _ work: (PhotoStorageService, URL) throws -> Void
    ) throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        try work(PhotoStorageService(rootURL: tempDir), tempDir)
    }

    // Relative path helper matching PhotoStorageService's own logic.
    private func relativePath(from file: URL, root: URL) -> String {
        let docPath  = root.standardizedFileURL.path
        let filePath = file.standardizedFileURL.path
        guard filePath.hasPrefix(docPath) else { return filePath }
        let rel = String(filePath.dropFirst(docPath.count))
        return rel.hasPrefix("/") ? String(rel.dropFirst()) : rel
    }

    // MARK: - Orphan removal

    @Test("sweepOrphanFiles removes .jpg not in knownRelativePaths and returns count 1")
    func sweepRemovesOrphanJpg() throws {
        try withTempStorage { storage, root in
            let dir = root.appendingPathComponent("Athletes")
                .appendingPathComponent(UUID().uuidString)
                .appendingPathComponent("CheckIns")
                .appendingPathComponent(UUID().uuidString)
                .appendingPathComponent("original")
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let file = dir.appendingPathComponent("orphan.jpg")
            try Data("fake".utf8).write(to: file)

            let removed = storage.sweepOrphanFiles(knownRelativePaths: [])
            #expect(removed == 1)
            #expect(!FileManager.default.fileExists(atPath: file.path))
        }
    }

    @Test("sweepOrphanFiles preserves files whose relative path is in knownRelativePaths")
    func sweepPreservesKnownFile() throws {
        try withTempStorage { storage, root in
            let dir = root.appendingPathComponent("Athletes")
                .appendingPathComponent(UUID().uuidString)
                .appendingPathComponent("CheckIns")
                .appendingPathComponent(UUID().uuidString)
                .appendingPathComponent("original")
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let file = dir.appendingPathComponent("known.jpg")
            try Data("fake".utf8).write(to: file)

            let rel = relativePath(from: file, root: root)
            let removed = storage.sweepOrphanFiles(knownRelativePaths: [rel])
            #expect(removed == 0)
            #expect(FileManager.default.fileExists(atPath: file.path))
        }
    }

    @Test("sweepOrphanFiles skips non-.jpg files")
    func sweepSkipsNonJpgFiles() throws {
        try withTempStorage { storage, root in
            let dir = root.appendingPathComponent("Athletes").appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let pngFile = dir.appendingPathComponent("image.png")
            try Data("fake".utf8).write(to: pngFile)

            let removed = storage.sweepOrphanFiles(knownRelativePaths: [])
            #expect(removed == 0)
            #expect(FileManager.default.fileExists(atPath: pngFile.path))
        }
    }

    @Test("sweepOrphanFiles returns 0 when Athletes directory does not exist")
    func sweepReturnsZeroWhenNoAthletesDirExists() {
        let nonExistentRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let storage = PhotoStorageService(rootURL: nonExistentRoot)
        let removed = storage.sweepOrphanFiles(knownRelativePaths: [])
        #expect(removed == 0)
    }

    @Test("sweepOrphanFiles removes orphan but leaves known file — mixed scenario")
    func sweepMixedScenario() throws {
        try withTempStorage { storage, root in
            let dir = root.appendingPathComponent("Athletes")
                .appendingPathComponent(UUID().uuidString)
                .appendingPathComponent("CheckIns")
                .appendingPathComponent(UUID().uuidString)
                .appendingPathComponent("original")
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

            let orphan = dir.appendingPathComponent("orphan.jpg")
            let known  = dir.appendingPathComponent("known.jpg")
            try Data("a".utf8).write(to: orphan)
            try Data("b".utf8).write(to: known)

            let rel = relativePath(from: known, root: root)
            let removed = storage.sweepOrphanFiles(knownRelativePaths: [rel])
            #expect(removed == 1)
            #expect(!FileManager.default.fileExists(atPath: orphan.path))
            #expect(FileManager.default.fileExists(atPath: known.path))
        }
    }
}
