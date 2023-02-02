import Foundation

func topologicalSort(src: Cell) throws -> [(cell: Cell, refs: [UInt32])] {
    var pending: [Cell] = [src]
    var allCells = [String: (cell: Cell, refs: [String])]()
    var notPermCells = Set<String>()
    var sorted: [String] = []
    
    while pending.count > 0 {
        let cells = pending
        pending = []
        for cell in cells {
            let hash = cell.hash().hexString()
            if allCells.keys.contains(hash) {
                continue
            }
            
            notPermCells.insert(hash)
            allCells[hash] = (cell: cell, refs: cell.refs.map { $0.hash().hexString() })
            
            for r in cell.refs {
                pending.append(r)
            }
        }
    }
    
    var tempMark = Set<String>()
    func visit(hash: String) throws {
        if !notPermCells.contains(hash) {
            return
        }
        if tempMark.contains(hash) {
            throw TonError.custom("Not a DAG")
        }
        
        tempMark.insert(hash)
        for c in allCells[hash]!.refs {
            try visit(hash: c)
        }
        
        sorted.insert(hash, at: 0)
        tempMark.remove(hash)
        notPermCells.remove(hash)
    }
    
    while notPermCells.count > 0 {
        let id = Array(notPermCells)[0]
        try visit(hash: id)
    }
    
    var indexes = [String: UInt32]()
    for i in 0..<sorted.count {
        indexes[sorted[i]] = UInt32(i)
    }
    
    var result: [(cell: Cell, refs: [UInt32])] = []
    for ent in sorted {
        let rrr = allCells[ent]!
        result.append((cell: rrr.cell, refs: rrr.refs.map { indexes[$0]! }))
    }
    
    return result
}
