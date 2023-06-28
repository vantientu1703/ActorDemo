//
//  ViewController.swift
//  ActorDemo
//
//  Created by Van Tu on 27/06/2023.
//

import UIKit
import Combine

class ViewController: UIViewController {
    
    var subscriptions = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    func futureIncrement(integer: Int, afterDelay delay: TimeInterval) -> Future<Int, Never> {
        Future<Int, Never> { promise in
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                promise(.success(integer + 1))
            }
        }
    }
    
    @IBOutlet weak var imageView: UIImageView!
    
    let url = URL(string: "https://upload.wikimedia.org/wikipedia/commons/b/b6/Image_created_with_a_mobile_phone.png")!
    
    @IBAction func asyncAwaitAction(_ sender: Any) {
        self.imageView.image = nil
        let startTime = Date()
        Task {
            self.imageView.image = try? await downloadImage(url: url)
            print("Async/awiat duration time: \(Date().timeIntervalSince(startTime))")
        }
        for i in 0...10 {
            print("Async/await printter index: \(i)")
        }
    }
    
    func downloadImage(url: URL) async throws -> UIImage? {
        let (data, _) = try await URLSession.shared.data(from: url)
        let image = UIImage(data: data)
        return image
    }
    
    func downloadImage(url: URL) -> AnyPublisher<UIImage?, URLError> {
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .map { data in
                UIImage(data: data)
            }
            .eraseToAnyPublisher()
    }
    
    func downloadImage(url: URL, completion: @escaping (UIImage?, Error?) -> Void) {
        URLSession.shared.dataTask(with: URLRequest(url: url)) { data, _, error in
            if let data = data {
                let image = UIImage(data: data)
                completion(image, nil)
            } else {
                completion(nil, error)
            }
        }
        .resume()
    }
    
    
    @IBAction func combineAction(_ sender: Any) {
        self.imageView.image = nil
        let startTime = Date()
        downloadImage(url: url)
            .handleEvents(receiveCompletion: { _ in
                print("Combine duration time: \(Date().timeIntervalSince(startTime))")
            })
            .receive(on: DispatchQueue.main)
        // chỗ này Combine hay hơn RxSwift vì mình phải xử lý errors thì mới gọi được function assign(to:on:)
            .replaceError(with: nil)
            .assign(to: \.image, on: self.imageView)
            .store(in: &subscriptions)
        
        for i in 0...10 {
            print("Combine printter index: \(i)")
        }
    }
    
    @IBAction func gcdAction(_ sender: Any) {
        self.imageView.image = nil
        let startTime = Date()
        downloadImage(url: url) { image, error in
            print("async/awiat duration time: \(Date().timeIntervalSince(startTime))")
            DispatchQueue.main.async { [weak self] in
                self?.imageView.image = image
            }
        }
    }
}
// dùng actor thay cho thread safety
actor Order {
    static let shared = Order()
    
    var products: [String] = []
    var price: Int = 0
    
    func addProduct(_ product: String) {
        products.append(product)
    }
}

class StringSubscriber: Subscriber {
    
    func receive(subscription: Subscription) {
        print("Received Subscription")
        subscription.request(.unlimited) // backpressure
    }
    
    
    func receive(_ input: String) -> Subscribers.Demand {
        print("Received Value", input)
        return .unlimited
    }
    
    func receive(completion: Subscribers.Completion<Never>) {
        print("Completed")
    }
    
    typealias Input = String
    typealias Failure = Never
}
