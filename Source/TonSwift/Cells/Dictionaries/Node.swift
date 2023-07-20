//
//  Node.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

enum Node<T> {
    case fork(left: Edge<T>, right: Edge<T>)
    case leaf(value: T)
}
