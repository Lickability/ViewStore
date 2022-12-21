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
        
        let vs = await PhotoListViewStore(provider: mock,  clock: testClock).forTest(clock: testClock)
        vs.send(.toggleShowsPhotoCount(true))
        await testClock.advance()
        
        XCTAssertEqual(vs.viewState.showsPhotoCount, true)
    }
    
    func testSearchProperlyFiltersByTitle() async throws {
        let mock = MockItemProvider(photosCount: 3)
        let testClock = TestClock()

        let vs = await PhotoListViewStore(provider: mock, clock: testClock).forTest(clock: testClock)
        
        vs.viewState.status.verify(photosCount: 3, firstPhotoTitleIfApplicable: nil)

        vs.send(.search("2"))

        await testClock.advance(by: .seconds(1))

        vs.viewState.status.verify(photosCount: 1, firstPhotoTitleIfApplicable: "2")
    }
    
    
    func testSearchProperlyFiltersByTitleTwice() async throws {
        let mock = MockItemProvider(photosCount: 3)
        let testClock = TestClock()

        let vs = await PhotoListViewStore(provider: mock, clock: testClock).forTest(clock: testClock)
                
        vs.viewState.status.verify(photosCount: 3, firstPhotoTitleIfApplicable: nil)
        
        vs.send(.search("2"))

        await testClock.advance(by: .seconds(1))

        vs.viewState.status.verify(photosCount: 1, firstPhotoTitleIfApplicable: "2")
        
        vs.send(.search("1"))

        await testClock.advance(by: .seconds(1))

        vs.viewState.status.verify(photosCount: 1, firstPhotoTitleIfApplicable: "1")
    }
    
}

extension PhotoListViewStore.ViewState.Status {
    func verify(photosCount: Int, firstPhotoTitleIfApplicable: String?) {
        if let photos = self.photos {
            XCTAssertEqual(photos.count, photosCount)
            if let firstPhotoTitleIfApplicable {
                XCTAssertTrue(photos[0].title.contains(firstPhotoTitleIfApplicable))
            }
        } else {
            XCTFail()
        }
    }
    
    var photos: [Photo]? {
        switch self {
        case .error(_), .loading:
            return nil
        case let .content(photos):
            return photos
        }
    }
}

extension ViewStore {
    func forTest(clock: TestClock<Duration>) async -> Self {
        await clock.advance()
        return self
    }
}
