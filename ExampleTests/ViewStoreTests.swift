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

final class ViewStoreTests: XCTestCase {

    func testToggleShowsPhotoCount() throws {
        let mock = MockItemProvider(photosCount: 3)
        let scheduler = MainQueueScheduler(type: .test)
        
        let vs = PhotoListViewStore(provider: mock, scheduler: scheduler)
        vs.send(.toggleShowsPhotoCount(true))
        
        scheduler.advance()
        
        XCTAssertEqual(vs.viewState.showsPhotoCount, true)
    }
    
    func testSearchProperlyFiltersByTitle() throws {
        let mock = MockItemProvider(photosCount: 3)
        let scheduler = MainQueueScheduler(type: .test)
        
        let vs = PhotoListViewStore(provider: mock, scheduler: scheduler)
        vs.send(.search("2"))
        
        scheduler.advance(by: 1)
        
        switch vs.viewState.status {
        case .error(_), .loading:
            XCTFail()
        case let .content(photos):
            XCTAssertEqual(photos.count, 1)
            XCTAssertTrue(photos[0].title.contains("2"))
        }
    }
    
    func testSearchProperlyFiltersAndSearchTextIsCorrect() {
        let mock = MockItemProvider(photosCount: 3)
        let scheduler = MainQueueScheduler(type: .test)
        
        let vs = PhotoListViewStore(provider: mock, scheduler: scheduler)
        vs.send(.search("2"))
        
        scheduler.advance(by: 1)
        
        XCTAssertEqual(vs.viewState.searchText, "2")
    }
}
