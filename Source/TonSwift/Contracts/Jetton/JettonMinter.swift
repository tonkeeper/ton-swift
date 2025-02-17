//
//  JettonMinter.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

import Foundation
import BigInt

let jettonMinterBoc = "B5EE9C7241020B010001ED000114FF00F4A413F4BCF2C80B0102016202030202CC040502037A60090A03EFD9910E38048ADF068698180B8D848ADF07D201800E98FE99FF6A2687D007D206A6A18400AA9385D47181A9AA8AAE382F9702480FD207D006A18106840306B90FD001812881A28217804502A906428027D012C678B666664F6AA7041083DEECBEF29385D71811A92E001F1811802600271812F82C207F97840607080093DFC142201B82A1009AA0A01E428027D012C678B00E78B666491646580897A007A00658064907C80383A6465816503E5FFE4E83BC00C646582AC678B28027D0109E5B589666664B8FD80400FE3603FA00FA40F82854120870542013541403C85004FA0258CF1601CF16CCC922C8CB0112F400F400CB00C9F9007074C8CB02CA07CBFFC9D05008C705F2E04A12A1035024C85004FA0258CF16CCCCC9ED5401FA403020D70B01C3008E1F8210D53276DB708010C8CB055003CF1622FA0212CB6ACB1FCB3FC98042FB00915BE200303515C705F2E049FA403059C85004FA0258CF16CCCCC9ED54002E5143C705F2E049D43001C85004FA0258CF16CCCCC9ED54007DADBCF6A2687D007D206A6A183618FC1400B82A1009AA0A01E428027D012C678B00E78B666491646580897A007A00658064FC80383A6465816503E5FFE4E840001FAF16F6A2687D007D206A6A183FAA904051007F09"

public class JettonMinter {
    let cell: Cell

    init(bocString: String = jettonMinterBoc) throws {
        cell = try Cell.fromBase64(src: bocString)
    }

    func createDataCell(
        owner: Address,
        metadata: Cell,
        jettonWalletCode: Cell
    ) throws -> Cell {
        try Builder()
            .store(coins: .init(0)) // total supply
            .store(address: owner)
            .store(ref: metadata)
            .store(ref: jettonWalletCode)
            .endCell()
    }

    func createMintBody(
        destination: Address,
        jettonAmount: BigInt,
        amount: BigInt = 50000000,
        queryId: Int = 0
    ) throws -> Cell {
        try Builder()
            .store(uint: 21, bits: 32) // OP-code mint
            .store(uint: queryId, bits: 64)
            .store(address: destination)
            .store(coins: Coins(amount))
            .store(
                ref: try Builder()
                    .store(uint: 0x178d4519, bits: 32) // OP-code transfer
                    .store(uint: queryId, bits: 64)
                    .store(coins: Coins(jettonAmount)) // jetton amount
                    .store(address: nil) // from_address
                    .store(address: nil) // response_address
                    .store(coins: .init(0)) // forward amount
                    .store(bit: .zero) // forward_payload in this slice, not separate cell
                    .endCell()
            )
            .endCell()
    }

    func createChangeAdminAddress(
        newAdmin: Address,
        queryId: Int = 0
    ) throws -> Cell {
        try Builder()
            .store(uint: 3, bits: 32) // OP-code
            .store(uint: queryId, bits: 64) // query_id
            .store(address: newAdmin)
            .endCell()
    }

    func createEditContent(
        metadata: Cell,
        queryId: Int = 0
    ) throws -> Cell {
        try Builder()
            .store(uint: 4, bits: 32) // OP-code
            .store(uint: queryId, bits: 64) //query_id
            .store(ref: metadata)
            .endCell()
    }
}
