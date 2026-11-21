import Foundation

extension URLRequest {
    // URLSession turns a request body into a stream, so tests read it back from the stream.
    func bodyData() -> Data? {
        if let httpBody {
            return httpBody
        }
        guard let stream = httpBodyStream else { return nil }

        stream.open()
        defer { stream.close() }

        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1024)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count <= 0 { break }
            data.append(buffer, count: count)
        }
        return data
    }
}
