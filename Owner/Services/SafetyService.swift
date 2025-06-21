//
//  SafetyService.swift
//  Owner
//
//  Created by T on 6/21/25.
//

import Foundation
import QuartzCore

/// Safety service to handle potential runtime issues and null pointer exceptions
class SafetyService {
    
    /// Safely perform NSMapTable operations with null checks
    static func safeMapGet<K, V>(_ mapTable: NSMapTable<K, V>?, key: K) -> V? {
        guard let mapTable = mapTable else {
            print("⚠️  NSMapTable is nil, returning nil")
            return nil
        }
        return mapTable.object(forKey: key)
    }
    
    /// Safely remove from NSMapTable with null checks
    static func safeMapRemove<K, V>(_ mapTable: NSMapTable<K, V>?, key: K) {
        guard let mapTable = mapTable else {
            print("⚠️  NSMapTable is nil, cannot remove key")
            return
        }
        mapTable.removeObject(forKey: key)
    }
    
    /// Safely set NSMapTable value with null checks
    static func safeMapSet<K, V>(_ mapTable: NSMapTable<K, V>?, key: K, value: V?) {
        guard let mapTable = mapTable else {
            print("⚠️  NSMapTable is nil, cannot set value")
            return
        }
        mapTable.setObject(value, forKey: key)
    }
    
    /// Handle missing resource files gracefully
    static func loadResourceFile(_ fileName: String, ofType type: String) -> String? {
        guard let path = Bundle.main.path(forResource: fileName, ofType: type) else {
            print("⚠️  Resource file '\(fileName).\(type)' not found in bundle")
            return nil
        }
        
        do {
            let content = try String(contentsOfFile: path)
            return content
        } catch {
            print("⚠️  Failed to load resource file '\(fileName).\(type)': \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Provide default CSV data if default.csv is missing
    static func getDefaultCSVData() -> String {
        // If default.csv is missing, return empty CSV or default data
        if let csvData = loadResourceFile("default", ofType: "csv") {
            return csvData
        } else {
            print("📄 Using fallback CSV data since default.csv is missing")
            return "id,name,value\n1,default,0\n" // Fallback CSV structure
        }
    }
    
    /// Validate view bounds for Metal layer operations
    static func isValidViewSize(_ size: CGSize) -> Bool {
        return size.width > 0 && size.height > 0
    }
    
    /// Safely set Metal layer drawable size
    static func safeSetDrawableSize(_ layer: CAMetalLayer?, size: CGSize) {
        guard let layer = layer else {
            print("⚠️  CAMetalLayer is nil")
            return
        }
        
        guard isValidViewSize(size) else {
            print("⚠️  Invalid size for CAMetalLayer: \(size)")
            return
        }
        
        layer.drawableSize = size
    }
}
