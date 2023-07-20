//
//  Edge.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

class Edge<T> {
    let label: Bitstring
    let node: Node<T>
    
    init(label: Bitstring, node: Node<T>) {
        self.label = label
        self.node = node
    }
}
