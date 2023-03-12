import XCTest // импортируем фреймворк для тестирования
@testable import MovieQuiz // импортируем наше приложение для тестирования

final class ArrayTests: XCTestCase {
    func testGetValueInRange() throws { // тест на успешное взятие элемента по индексу
        
        // Given
        let array = [1, 7, 15, 19, 25]
        
        // When
        let value = array[safe: 2]
        
        // Then
        XCTAssertNotNil(value)
        XCTAssertEqual(value, 15)
    }
    
    func testGetValueOutOfRange() throws { // тест на взятие элемента по неправильному индексу
       
        // Given
        let array = [1, 3, 10, 14, 22]
        
        // When
        let value = array[safe: 10]
        
        // Then
        XCTAssertNil(value)
    }
}
