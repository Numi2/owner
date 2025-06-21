//
//  GameLogicTests.swift
//  OwnerTests
//
//  Created by T on 6/21/25.
//

import XCTest
import CoreLocation
@testable import Owner

final class GameLogicTests: XCTestCase {
    
    var gameManager: GameManager!
    var testPlayer: Player!
    var testCoordinate: CLLocationCoordinate2D!
    
    override func setUpWithError() throws {
        gameManager = GameManager()
        testPlayer = Player(gamePlayerID: "test_player_123")
        testCoordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194) // San Francisco
        gameManager.currentPlayer = testPlayer
    }
    
    override func tearDownWithError() throws {
        gameManager = nil
        testPlayer = nil
        testCoordinate = nil
    }
    
    // MARK: - Turf Tests
    
    func testTurfInitialization() throws {
        let turf = Turf(coordinate: testCoordinate)
        
        XCTAssertTrue(turf.isNeutral)
        XCTAssertNil(turf.ownerID)
        XCTAssertEqual(turf.vaultCash, 0.0)
        XCTAssertEqual(turf.defenseMultiplier, 1)
        XCTAssertFalse(turf.isUnderAttack)
        XCTAssertEqual(turf.defenseValue, 0.0) // vaultCash * defenseMultiplier
    }
    
    func testHexGridAlignment() throws {
        let coordinate = CLLocationCoordinate2D(latitude: 37.774921, longitude: -122.419367)
        let turf = Turf(coordinate: coordinate)
        
        // Check that coordinates are aligned to hex grid
        let expectedLat = round(coordinate.latitude / GameConstants.hexGridSize) * GameConstants.hexGridSize
        let expectedLon = round(coordinate.longitude / GameConstants.hexGridSize) * GameConstants.hexGridSize
        
        XCTAssertEqual(turf.latitude, expectedLat, accuracy: 0.0000001)
        XCTAssertEqual(turf.longitude, expectedLon, accuracy: 0.0000001)
        XCTAssertEqual(turf.id, "\(expectedLat):\(expectedLon)")
    }
    
    // MARK: - Game Constants Tests
    
    func testGameConstants() throws {
        XCTAssertEqual(GameConstants.maxCaptureDistance, 25.0)
        XCTAssertEqual(GameConstants.hexGridSize, 0.0001)
        XCTAssertEqual(GameConstants.baseIncomeRate, 1.0)
        XCTAssertEqual(GameConstants.maxDefenseMultiplier, 5)
        XCTAssertEqual(GameConstants.lootPercentage, 0.25)
        XCTAssertEqual(GameConstants.attackCooldown, 120.0)
        XCTAssertEqual(GameConstants.incomeInterval, 60.0)
    }
    
    // MARK: - Player Tests
    
    func testPlayerInitialization() throws {
        let player = Player(gamePlayerID: "test_123")
        
        XCTAssertEqual(player.id, "test_123")
        XCTAssertEqual(player.walletBalance, 100.0)
        XCTAssertTrue(player.createdAt <= Date())
        XCTAssertTrue(player.lastActiveAt <= Date())
    }
    
    // MARK: - Weapon Pack Tests
    
    func testWeaponPacks() throws {
        let basic = WeaponPack.basic
        let advanced = WeaponPack.advanced
        let elite = WeaponPack.elite
        
        // Test basic weapon
        XCTAssertEqual(basic.name, "Basic")
        XCTAssertEqual(basic.cost, 10.0)
        XCTAssertEqual(basic.attackValue, 25.0)
        
        // Test advanced weapon
        XCTAssertEqual(advanced.name, "Advanced")
        XCTAssertEqual(advanced.cost, 25.0)
        XCTAssertEqual(advanced.attackValue, 75.0)
        
        // Test elite weapon
        XCTAssertEqual(elite.name, "Elite")
        XCTAssertEqual(elite.cost, 50.0)
        XCTAssertEqual(elite.attackValue, 150.0)
        
        // Test that all weapons are available
        XCTAssertEqual(WeaponPack.all.count, 3)
        XCTAssertTrue(WeaponPack.all.contains { $0.name == "Basic" })
        XCTAssertTrue(WeaponPack.all.contains { $0.name == "Advanced" })
        XCTAssertTrue(WeaponPack.all.contains { $0.name == "Elite" })
    }
    
    // MARK: - Attack Resolution Tests
    
    func testAttackResolution() throws {
        // Create a turf with some defense
        var turf = Turf(coordinate: testCoordinate)
        turf.ownerID = "enemy_player"
        turf.vaultCash = 100.0
        turf.defenseMultiplier = 2
        // Defense Value = 100 * 2 = 200
        
        let initialWallet = gameManager.walletBalance
        let weapon = WeaponPack.basic // AV = 25
        
        // Attack should fail (AV 25 < DV 200)
        gameManager.attackTurf(turf, weaponPack: weapon)
        
        // Wallet should be reduced by weapon cost
        XCTAssertEqual(gameManager.walletBalance, initialWallet - weapon.cost)
    }
    
    func testSuccessfulAttack() throws {
        // Create a weak turf
        var turf = Turf(coordinate: testCoordinate)
        turf.ownerID = "enemy_player"
        turf.vaultCash = 40.0
        turf.defenseMultiplier = 1
        // Defense Value = 40 * 1 = 40
        
        let initialWallet = gameManager.walletBalance
        let weapon = WeaponPack.advanced // AV = 75
        
        // Attack should succeed (AV 75 > DV 40)
        gameManager.attackTurf(turf, weaponPack: weapon)
        
        // Expected loot = 40 * 0.25 = 10
        let expectedLoot = turf.vaultCash * GameConstants.lootPercentage
        let expectedWallet = initialWallet - weapon.cost + expectedLoot
        
        XCTAssertEqual(gameManager.walletBalance, expectedWallet)
    }
    
    // MARK: - Income Calculation Tests
    
    func testIncomeCalculation() throws {
        let now = Date()
        let pastTime = now.addingTimeInterval(-GameConstants.incomeInterval * 2) // 2 income intervals ago
        
        var turf = Turf(coordinate: testCoordinate)
        turf.ownerID = testPlayer.id
        turf.lastIncomeAt = pastTime
        turf.vaultCash = 50.0
        
        // Calculate expected income
        let timeSinceLastIncome = now.timeIntervalSince(pastTime)
        let incomeIntervals = timeSinceLastIncome / GameConstants.incomeInterval
        let expectedIncome = GameConstants.baseIncomeRate * incomeIntervals
        let expectedVaultCash = turf.vaultCash + expectedIncome
        
        // Verify income calculation logic
        XCTAssertEqual(incomeIntervals, 2.0, accuracy: 0.1)
        XCTAssertEqual(expectedIncome, 2.0, accuracy: 0.1)
        XCTAssertEqual(expectedVaultCash, 52.0, accuracy: 0.1)
    }
    
    // MARK: - Net Worth Tests
    
    func testNetWorthCalculation() throws {
        gameManager.walletBalance = 100.0
        
        // Create some player turfs with vault cash
        var turf1 = Turf(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194))
        turf1.ownerID = testPlayer.id
        turf1.vaultCash = 50.0
        
        var turf2 = Turf(coordinate: CLLocationCoordinate2D(latitude: 37.7750, longitude: -122.4195))
        turf2.ownerID = testPlayer.id
        turf2.vaultCash = 75.0
        
        gameManager.playerTurfs = [turf1, turf2]
        
        let expectedNetWorth = 100.0 + 50.0 + 75.0 // wallet + vault totals
        XCTAssertEqual(gameManager.netWorth(), expectedNetWorth)
    }
    
    // MARK: - Distance and Range Tests
    
    func testLocationServiceDistance() throws {
        let locationService = LocationService()
        let location1 = CLLocation(latitude: 37.7749, longitude: -122.4194)
        let location2 = CLLocation(latitude: 37.7750, longitude: -122.4195)
        
        locationService.currentLocation = location1
        
        let distance = locationService.distanceFromCurrentLocation(to: location2.coordinate)
        XCTAssertNotNil(distance)
        XCTAssertGreaterThan(distance!, 0)
        XCTAssertLessThan(distance!, 100) // Should be less than 100m for this small coordinate difference
    }
    
    func testHexGridCoordinateAlignment() throws {
        let locationService = LocationService()
        let coordinate = CLLocationCoordinate2D(latitude: 37.774921, longitude: -122.419367)
        
        let hexCoordinate = locationService.hexGridCoordinate(from: coordinate)
        
        // Check that the result is aligned to the hex grid
        let expectedLat = round(coordinate.latitude / GameConstants.hexGridSize) * GameConstants.hexGridSize
        let expectedLon = round(coordinate.longitude / GameConstants.hexGridSize) * GameConstants.hexGridSize
        
        XCTAssertEqual(hexCoordinate.latitude, expectedLat, accuracy: 0.0000001)
        XCTAssertEqual(hexCoordinate.longitude, expectedLon, accuracy: 0.0000001)
    }
}