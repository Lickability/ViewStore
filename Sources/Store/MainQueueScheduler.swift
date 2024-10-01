//
//  MainQueueScheduler.swift
//  ViewStore
//
//  Created by Kenneth Ackerson on 7/13/22.
//

import Foundation
import Combine
import SwiftUI

/// Scheduler that allows you to either have a `default` implementation of the `DispatchQueue.main` scheduler,  a `synchronous` implementation that will immediately call back, a `test` scheduler for fine grained control of time, and an `animated` scheduler to drive animations.
/// You will want to use this to avoid the behavior of `DispatchQueue.main`'s scheduler to schedule work asynchronously by default.
public final class MainQueueScheduler: Scheduler {

    /// Describes the characteristics of the scheduler.
    public enum SchedulerType: Equatable {

        /// Default `DispatchQueue.main` scheduler.
        case `default`

        /// Synchronous scheduler that calls on the main thread immediately.
        case synchronous
        
        /// Synchronous scheduler that is useful for fine grain control/custom advancement in time.
        case test
        
        /// Default `DispatchQueue.main` scheduler that performs its action with the specified animation.
        case animated(Animation)
    }

    private let type: SchedulerType

    private var actions: [(action: () -> (), date: DispatchQueue.SchedulerTimeType, sequence: UInt)] = []
    private var immediateNow: DispatchQueue.SchedulerTimeType = .init(.init(uptimeNanoseconds: 1))
    private var lastSequence: UInt = 0

    /// Creates a new `MainQueueScheduler`.
    /// - Parameter type: The scheduler type that determines the timing of work execute.
    public init(type: SchedulerType = .default) {
        self.type = type
    }

    // MARK: - Scheduler

    public var now: DispatchQueue.SchedulerTimeType {
        switch self.type {
        case .test:
            return immediateNow
        case .default, .animated, .synchronous:
            return DispatchQueue.main.now
        }
    }

    public var minimumTolerance: DispatchQueue.SchedulerTimeType.Stride {
        return DispatchQueue.main.minimumTolerance
    }

    // MARK: - MainQueueScheduler

    public func advance(by stride: TimeInterval = 1000000) {
        /// Borrowed from https://github.com/pointfreeco/combine-schedulers/blob/main/Sources/CombineSchedulers/TestScheduler.swift
        assert(self.type == .test)
        
        let finalDate = self.now.advanced(by: DispatchQueue.SchedulerTimeType.Stride(floatLiteral: stride))
        
        while self.now <= finalDate {
            self.actions.sort { ($0.date, $0.sequence) < ($1.date, $1.sequence) }
            
            guard
                let next = self.actions.first,
                finalDate >= next.date
            else {
                self.immediateNow = finalDate
                return
            }
            
            self.immediateNow = next.date
            
            self.actions.removeFirst()
            next.action()
        }
    }

    private func callOnMainThread(action: @escaping () -> Void) {
        if Thread.isMainThread {
            action()
        } else {
            DispatchQueue.main.sync(execute: action)
        }
    }
    
    private func nextSequence() -> UInt {
        self.lastSequence += 1
        return self.lastSequence
    }

    // MARK: - Scheduler

    public func schedule(after date: DispatchQueue.SchedulerTimeType, interval: DispatchQueue.SchedulerTimeType.Stride, tolerance: DispatchQueue.SchedulerTimeType.Stride, options: DispatchQueue.SchedulerOptions?, _ action: @escaping () -> Void) -> Cancellable {
        
        switch type {
        case .default:
            return DispatchQueue.main.schedule(after: date, interval: interval, tolerance: tolerance, options: options, action)
        case .test:
            actions.append((action, date, nextSequence()))
            return AnyCancellable { }
        case .synchronous:
            callOnMainThread(action: action)
            return AnyCancellable { }
        case let .animated(animation):
            return DispatchQueue.main.schedule(after: date, interval: interval, tolerance: tolerance, options: options) {
                withAnimation(animation) {
                    action()
                }
            }
        }
    }

    public func schedule(after date: DispatchQueue.SchedulerTimeType, tolerance: DispatchQueue.SchedulerTimeType.Stride, options: DispatchQueue.SchedulerOptions?, _ action: @escaping () -> Void) {
        switch self.type {
        case .default:
            DispatchQueue.main.schedule(after: date, tolerance: tolerance, options: options, action)
        case .test:
            actions.append((action, date, nextSequence()))
        case .synchronous:
            callOnMainThread(action: action)
        case let .animated(animation):
            DispatchQueue.main.schedule(after: date, tolerance: tolerance, options: options) {
                withAnimation(animation) {
                    action()
                }
            }
        }
    }

    public func schedule(options: DispatchQueue.SchedulerOptions?, _ action: @escaping () -> Void) {
        switch self.type {
        case .default:
            DispatchQueue.main.schedule(options: options, action)
        case .test:
            actions.append((action, self.now, nextSequence()))
        case .synchronous:
            callOnMainThread(action: action)
        case let .animated(animation):
            let animationAction = {
                withAnimation(animation) {
                    action()
                }
            }

            if Thread.isMainThread {
                animationAction()
            } else {
                DispatchQueue.main.schedule(animationAction)
            }
        }
    }
}
