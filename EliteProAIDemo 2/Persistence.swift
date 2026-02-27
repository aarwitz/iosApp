import Foundation

enum Persistence {
    static func documentsURL(filename: String) -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent(filename)
    }

    static func load<T: Decodable>(_ type: T.Type, from filename: String) -> T? {
        let url = documentsURL(filename: filename)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Load failed (\(filename)): \(error)")
            return nil
        }
    }

    static func save<T: Encodable>(_ value: T, to filename: String) {
        let url = documentsURL(filename: filename)
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(value)
            try data.write(to: url, options: [.atomic])
        } catch {
            print("Save failed (\(filename)): \(error)")
        }
    }

    static func delete(_ filename: String) {
        let url = documentsURL(filename: filename)
        try? FileManager.default.removeItem(at: url)
    }
}
