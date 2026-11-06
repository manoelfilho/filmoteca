import Alamofire
import Foundation

/// Implementação de `HTTPClient` com Alamofire.
public final class AlamofireHTTPClient: HTTPClient {
    private let session: Session

    public init(session: Session = .default) {
        self.session = session
    }

    public func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        let dataResponse = await session
            .request(
                request.url,
                method: Alamofire.HTTPMethod(rawValue: request.method.rawValue),
                parameters: request.query.isEmpty ? nil : request.query,
                encoder: URLEncodedFormParameterEncoder(destination: .queryString),
                headers: HTTPHeaders(request.headers),
                requestModifier: { urlRequest in
                    if let timeout = request.timeout {
                        urlRequest.timeoutInterval = timeout
                    }
                }
            )
            .serializingData(emptyResponseCodes: Set(200..<300))
            .response

        // Com resposta HTTP, devolve o corpo mesmo em erro (4xx/5xx):
        // quem chama decide como interpretar o status.
        if let httpResponse = dataResponse.response {
            return HTTPResponse(
                statusCode: httpResponse.statusCode,
                headers: httpResponse.headers.dictionary,
                data: dataResponse.data ?? Data()
            )
        }

        throw NetworkError(dataResponse.error)
    }
}

extension NetworkError {
    init(_ error: AFError?) {
        guard let error else {
            self = .invalidResponse
            return
        }

        if error.isExplicitlyCancelledError {
            self = .cancelled
            return
        }

        if error.isInvalidURLError || error.isParameterEncoderError {
            self = .invalidRequest(error.localizedDescription)
            return
        }

        if let urlError = error.underlyingError as? URLError {
            switch urlError.code {
            case .cancelled:
                self = .cancelled
            case .timedOut:
                self = .timeout
            case .notConnectedToInternet, .networkConnectionLost, .cannotFindHost,
                 .cannotConnectToHost, .dnsLookupFailed, .dataNotAllowed, .internationalRoamingOff:
                self = .connectivity
            default:
                self = .transport(urlError.localizedDescription)
            }
            return
        }

        self = .transport(error.localizedDescription)
    }
}
