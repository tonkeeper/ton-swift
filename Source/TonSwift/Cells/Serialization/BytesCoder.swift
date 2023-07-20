//
//  BytesCoder.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

public class BytesCoder: TypeCoder {
    public typealias T = Data
    let size: Int
    
    init(size: Int) {
        self.size = size
    }
    
    public func storeValue(_ src: T, to builder: Builder) throws {
        try builder.store(data: src)
    }
    public func loadValue(from src: Slice) throws -> T {
        try src.loadBytes(size)
    }
}
