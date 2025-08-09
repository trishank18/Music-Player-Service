import Foundation
import Combine
extension Publisher {
    func handleLoadingState<T>(
        loadingPublisher: PassthroughSubject<Bool, Never>
    ) -> Publishers.HandleEvents<Self> {
        self.handleEvents(
            receiveSubscription: { _ in
                loadingPublisher.send(true)
            },
            receiveCompletion: { _ in
                loadingPublisher.send(false)
            },
            receiveCancel: {
                loadingPublisher.send(false)
            }
        )
    }
    func debounceAndRemoveDuplicates<T: Equatable>(
        for delay: DispatchQueue.SchedulerTimeType.Stride,
        scheduler: DispatchQueue = DispatchQueue.main
    ) -> Publishers.RemoveDuplicates<Publishers.Debounce<Self, DispatchQueue>> where Output == T {
        self
            .debounce(for: delay, scheduler: scheduler)
            .removeDuplicates()
    }
    func retryWithBackoff(
        retries: Int,
        delay: TimeInterval = 1.0
    ) -> Publishers.Delay<Publishers.Retry<Self>, DispatchQueue> {
        self
            .retry(retries)
            .delay(for: .seconds(delay), scheduler: DispatchQueue.global())
    }
    func replaceErrorWithDefault<T>(
        _ defaultValue: T
    ) -> Publishers.ReplaceError<Publishers.Map<Self, T>> where Output == T {
        self
            .map { $0 }
            .replaceError(with: defaultValue)
    }
    func ignoreErrors() -> Publishers.Catch<Self, Empty<Output, Never>> {
        self.catch { _ in Empty() }
    }
    func performOnMain<T>(
        _ action: @escaping (T) -> Void
    ) -> Publishers.HandleEvents<Self> where Output == T {
        self.handleEvents(receiveOutput: { value in
            DispatchQueue.main.async {
                action(value)
            }
        })
    }
    func asyncValue() async throws -> Output {
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = self.sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                },
                receiveValue: { value in
                    continuation.resume(returning: value)
                }
            )
        }
    }
}
extension Publisher where Output: Collection {
    func isEmpty() -> Publishers.Map<Self, Bool> {
        self.map { $0.isEmpty }
    }
    func count() -> Publishers.Map<Self, Int> {
        self.map { $0.count }
    }
    func filterEmpty() -> Publishers.Filter<Self> {
        self.filter { !$0.isEmpty }
    }
}

extension Publisher where Output: Equatable {
    func distinctUntilChanged() -> Publishers.RemoveDuplicates<Self> {
        self.removeDuplicates()
    }
}
struct LoadingStatePublisher<Upstream: Publisher>: Publisher {
    typealias Output = (value: Upstream.Output?, isLoading: Bool)
    typealias Failure = Upstream.Failure
    
    private let upstream: Upstream
    
    init(upstream: Upstream) {
        self.upstream = upstream
    }
    
    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = LoadingStateSubscription(subscriber: subscriber, upstream: upstream)
        subscriber.receive(subscription: subscription)
    }
}

private class LoadingStateSubscription<Upstream: Publisher, Downstream: Subscriber>: Subscription
where Downstream.Input == (value: Upstream.Output?, isLoading: Bool),
      Downstream.Failure == Upstream.Failure {
    
    private var cancellable: AnyCancellable?
    private let subscriber: Downstream
    
    init(subscriber: Downstream, upstream: Upstream) {
        self.subscriber = subscriber
        _ = subscriber.receive((value: nil, isLoading: true))
        
        cancellable = upstream.sink(
            receiveCompletion: { [weak self] completion in
                _ = self?.subscriber.receive((value: nil, isLoading: false))
                self?.subscriber.receive(completion: completion)
            },
            receiveValue: { [weak self] value in
                _ = self?.subscriber.receive((value: value, isLoading: false))
            }
        )
    }
    
    func request(_ demand: Subscribers.Demand) {}
    
    func cancel() {
        cancellable?.cancel()
    }
}

extension Publisher {
    func withLoadingState() -> LoadingStatePublisher<Self> {
        LoadingStatePublisher(upstream: self)
    }
}
struct SearchPublisher {
    static func create<T>(
        from searchText: Published<String>.Publisher,
        searchFunction: @escaping (String) -> AnyPublisher<T, APIError>,
        debounceDelay: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(500)
    ) -> AnyPublisher<T, APIError> {
        searchText
            .debounce(for: debounceDelay, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .filter { !$0.isEmpty }
            .flatMapLatest { query in
                searchFunction(query)
                    .catch { error in
                        print("Search error: \(error)")
                        return Just([] as! T)
                            .setFailureType(to: APIError.self)
                    }
            }
            .eraseToAnyPublisher()
    }
}
@propertyWrapper
struct PublishedState<T> {
    private let subject: CurrentValueSubject<T, Never>
    
    var wrappedValue: T {
        get { subject.value }
        set { subject.send(newValue) }
    }
    
    var projectedValue: AnyPublisher<T, Never> {
        subject.eraseToAnyPublisher()
    }
    
    init(wrappedValue: T) {
        subject = CurrentValueSubject(wrappedValue)
    }
}
struct NetworkPublisher {
    static func create<T: Codable>(
        url: URL,
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder()
    ) -> AnyPublisher<T, APIError> {
        session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: T.self, decoder: decoder)
            .mapError { error in
                if error is DecodingError {
                    return APIError.decodingError(error)
                } else {
                    return APIError.networkError(error)
                }
            }
            .eraseToAnyPublisher()
    }
    static func createWithCache<T: Codable>(
        url: URL,
        cacheKey: String,
        cache: NSCache<NSString, NSData> = URLCache.shared as! NSCache<NSString, NSData>,
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder()
    ) -> AnyPublisher<T, APIError> {
        if let cachedData = cache.object(forKey: cacheKey as NSString) {
            return Just(cachedData as Data)
                .decode(type: T.self, decoder: decoder)
                .mapError { APIError.decodingError($0) }
                .eraseToAnyPublisher()
        }
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .handleEvents(receiveOutput: { data in
                cache.setObject(data as NSData, forKey: cacheKey as NSString)
            })
            .decode(type: T.self, decoder: decoder)
            .mapError { error in
                if error is DecodingError {
                    return APIError.decodingError(error)
                } else {
                    return APIError.networkError(error)
                }
            }
            .eraseToAnyPublisher()
    }
}
extension Publishers {
    static func countdown(
        from initialValue: Int,
        interval: TimeInterval = 1.0,
        on scheduler: DispatchQueue = .main
    ) -> AnyPublisher<Int, Never> {
        Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .scan(initialValue) { current, _ in
                max(0, current - 1)
            }
            .prefix { $0 >= 0 }
            .eraseToAnyPublisher()
    }
    static func progressTimer(
        duration: TimeInterval,
        interval: TimeInterval = 0.1,
        on scheduler: DispatchQueue = .main
    ) -> AnyPublisher<Double, Never> {
        let steps = Int(duration / interval)
        
        return Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .scan(0) { current, _ in current + 1 }
            .map { step in
                min(1.0, Double(step) / Double(steps))
            }
            .prefix { $0 <= 1.0 }
            .eraseToAnyPublisher()
    }
}
struct ValidationPublisher {
    static func email(_ text: String) -> AnyPublisher<Bool, Never> {
        Just(text)
            .map { email in
                let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
                let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
                return emailPredicate.evaluate(with: email)
            }
            .eraseToAnyPublisher()
    }
    static func passwordStrength(_ password: String) -> AnyPublisher<PasswordStrength, Never> {
        Just(password)
            .map { pwd in
                var score = 0
                
                if pwd.count >= 8 { score += 1 }
                if pwd.range(of: "[A-Z]", options: .regularExpression) != nil { score += 1 }
                if pwd.range(of: "[a-z]", options: .regularExpression) != nil { score += 1 }
                if pwd.range(of: "[0-9]", options: .regularExpression) != nil { score += 1 }
                if pwd.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil { score += 1 }
                
                switch score {
                case 0...2: return .weak
                case 3...4: return .medium
                default: return .strong
                }
            }
            .eraseToAnyPublisher()
    }
}

enum PasswordStrength {
    case weak, medium, strong
}
class CancellableStorage {
    private var cancellables = Set<AnyCancellable>()
    
    func store(_ cancellable: AnyCancellable) {
        cancellables.insert(cancellable)
    }
    
    func cancelAll() {
        cancellables.removeAll()
    }
    
    deinit {
        cancelAll()
    }
}

extension AnyCancellable {
    func store(in storage: CancellableStorage) {
        storage.store(self)
    }
}
@propertyWrapper
struct Reactive<T> {
    private let subject: CurrentValueSubject<T, Never>
    
    var wrappedValue: T {
        get { subject.value }
        set { subject.send(newValue) }
    }
    
    var projectedValue: CurrentValueSubject<T, Never> {
        subject
    }
    
    init(wrappedValue: T) {
        subject = CurrentValueSubject(wrappedValue)
    }
}
extension Publishers.CombineLatest {
    static func whenBothReady<A: Publisher, B: Publisher>(
        _ publisherA: A,
        _ publisherB: B
    ) -> Publishers.CombineLatest<A, B> where A.Failure == B.Failure {
        Publishers.CombineLatest(publisherA, publisherB)
    }
}

extension Publishers.CombineLatest3 {
    static func whenAllReady<A: Publisher, B: Publisher, C: Publisher>(
        _ publisherA: A,
        _ publisherB: B,
        _ publisherC: C
    ) -> Publishers.CombineLatest3<A, B, C> where A.Failure == B.Failure, B.Failure == C.Failure {
        Publishers.CombineLatest3(publisherA, publisherB, publisherC)
    }
}
extension Publisher {
    func logError(
        prefix: String = "Error",
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) -> Publishers.HandleEvents<Self> {
        handleEvents(receiveCompletion: { completion in
            if case .failure(let error) = completion {
                print("[\(prefix)] \(URL(fileURLWithPath: file).lastPathComponent).\(function):\(line) - \(error)")
            }
        })
    }
    func fallback<T>(
        to fallbackValue: T
    ) -> Publishers.Catch<Self, Just<T>> where Output == T {
        self.catch { _ in Just(fallbackValue) }
    }
    func retryWhen<T: Publisher>(
        _ retryTrigger: T
    ) -> Publishers.FlatMap<Self, Publishers.Catch<Self, Publishers.FlatMap<T, Just<Output>>>> where T.Output == Void, T.Failure == Never {
        self.catch { _ in
            retryTrigger.flatMap { _ in Just(self) }
        }
        .flatMap { $0 }
    }
}

#if DEBUG
extension Publisher {
    func debugPrint(
        prefix: String = "Debug",
        printTimeStamps: Bool = true
    ) -> Publishers.HandleEvents<Self> {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        
        return handleEvents(
            receiveSubscription: { subscription in
                let timestamp = printTimeStamps ? "[\(formatter.string(from: Date()))] " : ""
                print("\(timestamp)\(prefix): Subscription - \(subscription)")
            },
            receiveOutput: { output in
                let timestamp = printTimeStamps ? "[\(formatter.string(from: Date()))] " : ""
                print("\(timestamp)\(prefix): Output - \(output)")
            },
            receiveCompletion: { completion in
                let timestamp = printTimeStamps ? "[\(formatter.string(from: Date()))] " : ""
                print("\(timestamp)\(prefix): Completion - \(completion)")
            },
            receiveCancel: {
                let timestamp = printTimeStamps ? "[\(formatter.string(from: Date()))] " : ""
                print("\(timestamp)\(prefix): Cancelled")
            }
        )
    }
}
#endif
