//
//  ViewStoreTests.swift
//  ViewStoreTests
//
//  Created by Kenneth Ackerson on 7/13/22.
//

import XCTest
@testable import ViewStore
@testable import Provider
import Combine
import Clocks

@MainActor
final class ViewStoreTests: XCTestCase {

    func testToggleShowsPhotoCount() async throws {
        let mock = MockItemProvider(photosCount: 3)
        let testClock = TestClock()
        
        let vs = PhotoListViewStore(provider: mock,  clock: testClock)
        vs.send(.toggleShowsPhotoCount(true))
        await testClock.advance()

        
        XCTAssertEqual(vs.viewState.showsPhotoCount, true)
    }
    
    func testSearchProperlyFiltersByTitle() async throws {
        let mock = MockItemProvider(photosCount: 3)
        let testClock = TestClock()

        let vs = PhotoListViewStore(provider: mock, clock: testClock)
        vs.send(.search("2"))

        await testClock.advance(by: .seconds(1))

        switch vs.viewState.status {
        case .error(_), .loading:
            XCTFail()
        case let .content(photos):
            XCTAssertEqual(photos.count, 1)
            XCTAssertTrue(photos[0].title.contains("2"))
        }
    }
}
