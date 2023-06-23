//
//  File.swift
//  
//
//  Created by Marcus Arnett on 5/15/23.
//

import Foundation
import BigInt

public class TransactionResult {
    let transactionArgument: TransactionArgument
    var nestedResults: [TransactionArgument]
    
    public init(index: Int) {
        self.transactionArgument = TransactionArgument.result(
            Result(index: index)
        )
        self.nestedResults = []
    }
    
    public func nestedResultFor(_ resultIndex: Int) -> TransactionArgument? {
        if nestedResults.indices.contains(resultIndex) {
            return nestedResults[resultIndex]
        } else {
            switch transactionArgument {
            case .result(let result):
                let nestedResult = TransactionArgument.nestedResult(
                    NestedResult(
                        index: result.index,
                        resultIndex: resultIndex
                    )
                )
                nestedResults.append(nestedResult)
                return nestedResult
            default:
                return nil
            }
        }
    }
    
    public subscript(index: Int) -> TransactionArgument? {
        return nestedResultFor(index)
    }
}

public struct TransactionConstants {
    public static let MAX_GAS_OBJECTS = 256
    public static let MAX_GAS = 50_000_000_000
    public static let GAS_SAFE_OVERHEAD = 1_000
    public static let MAX_OBJECTS_PER_FETCH = 50
}

public struct BuildOptions {
    public let provider: SuiProvider?
    public let onlyTransactionKind: Bool?
}

public struct TransactionBlock {
    public var transactionBrand: Bool = true
    public var blockData: TransactionBlockDataBuilder?
    
    public static func isInstance(_ obj: Any) -> Bool {
        guard let obj = obj as? TransactionBlock else { return false }
        return obj.transactionBrand
    }
    
    public static func fromKind(serialized: Data) throws -> TransactionBlock {
        var tx = TransactionBlock()
        tx.blockData = try TransactionBlockDataBuilder.fromKindBytes(
            bytes: serialized
        )
        return tx
    }
    
    public static func fromKind(serialized: String) throws -> TransactionBlock {
        var tx = TransactionBlock()
        tx.blockData = try TransactionBlockDataBuilder.fromKindBytes(
            bytes: Data(B64.fromB64(sBase64: serialized))
        )
        return tx
    }
    
    public static func from(serialized: Data) throws -> TransactionBlock {
        var tx = TransactionBlock()
        tx.blockData = try TransactionBlockDataBuilder.fromBytes(bytes: serialized)
        return tx
    }
    
    public static func from(serialized: String) throws -> TransactionBlock {
        var tx = TransactionBlock()
        
        if serialized.starts(with: "{") {
            guard let data = serialized.data(using: .utf8) else { throw SuiError.notImplemented }
            let resultData = try JSONDecoder().decode(
                SerializedTransactionDataBuilder.self, from: data
            )
            tx.blockData = TransactionBlockDataBuilder.restore(data: resultData)
        } else {
            tx.blockData = try TransactionBlockDataBuilder.fromBytes(
                bytes: Data(B64.fromB64(sBase64: serialized))
            )
        }
        
        return tx
    }
    
    mutating public func setSender(sender: SuiAddress) {
        self.blockData?.serializedTransactionDataBuilder.sender = sender
    }
    
    mutating public func setSenderIfNotSet(sender: SuiAddress) {
        if ((self.blockData?.serializedTransactionDataBuilder.sender) == nil) {
            self.blockData?.serializedTransactionDataBuilder.sender = sender
        }
    }
    
    mutating public func setExpiration(expiration: TransactionExpiration) {
        self.blockData?.serializedTransactionDataBuilder.expiration = expiration
    }
    
    mutating public func setGasPrice(price: BigInt) {
        self.blockData?.serializedTransactionDataBuilder.gasConfig.price = "\(price)"
    }
    
    mutating public func setGasPrice(price: Int) {
        self.blockData?.serializedTransactionDataBuilder.gasConfig.price = "\(price)"
    }
    
    mutating public func setGasBudget(price: BigInt) {
        self.blockData?.serializedTransactionDataBuilder.gasConfig.budget = "\(price)"
    }
    
    mutating public func setGasBudget(price: Int) {
        self.blockData?.serializedTransactionDataBuilder.gasConfig.budget = "\(price)"
    }
    
    mutating public func setGasOwner(owner: String) {
        self.blockData?.serializedTransactionDataBuilder.gasConfig.owner = owner
    }
    
    public var gas: TransactionArgument {
        return TransactionArgument.gasCoin
    }
    
    mutating public func setGasPayment(payments: [SuiObjectRef]) throws {
        guard payments.count < TransactionConstants.MAX_GAS_OBJECTS else {
            throw SuiError.notImplemented
        }
        self.blockData?.serializedTransactionDataBuilder.gasConfig.payment = payments
    }
    
    mutating private func input(type: ValueType, value: SuiJsonValue?) throws -> TransactionBlockInput {
        if self.blockData == nil {
            self.blockData = TransactionBlockDataBuilder(
                serializedTransactionDataBuilder:
                    SerializedTransactionDataBuilder()
            )
        }
        guard let index = self.blockData?.serializedTransactionDataBuilder.inputs.count else {
            throw SuiError.invalidIndex
        }
        let input = TransactionBlockInput(
            index: index,
            value: value,
            type: type
        )
        self.blockData?.serializedTransactionDataBuilder.inputs.append(input)
        return input
    }
    
    public mutating func object(value: objectId) throws -> [TransactionBlockInput] {
        let id = getIdFromCallArg(arg: value)
        guard let blockData = self.blockData else { throw SuiError.notImplemented }
        let inserted = blockData.serializedTransactionDataBuilder.inputs.filter { input in
            if input.type == .object {
                guard let valueEnum = input.value else { return false }
                switch valueEnum {
                case .callArg(let callArg):
                    switch callArg {
                    case .ownedObject(let ownedObjectArg):
                        return id == ownedObjectArg.objectId
                    case .sharedObject(let sharedObjectArg):
                        return id == sharedObjectArg.objectId
                    default:
                        return false
                    }
                default:
                    return false
                }
            }
            
            return false
        }
        
        if !inserted.isEmpty {
            return inserted
        }
        
        return [
            try self.input(
                type: .object,
                value: SuiJsonValue.string(value)
            )
        ]
    }
    
    public mutating func object(value: ObjectCallArg) throws -> [TransactionBlockInput] {
        let id = getIdFromCallArg(arg: value)
        guard let blockData = self.blockData else { throw SuiError.notImplemented }
        let inserted = blockData.serializedTransactionDataBuilder.inputs.filter { input in
            if input.type == .object {
                guard let valueEnum = input.value else { return false }
                switch valueEnum {
                case .callArg(let callArg):
                    switch callArg {
                    case .ownedObject(let ownedObjectArg):
                        return id == ownedObjectArg.objectId
                    case .sharedObject(let sharedObjectArg):
                        return id == sharedObjectArg.objectId
                    default:
                        return false
                    }
                default:
                    return false
                }
            }
            
            return false
        }
        
        if !inserted.isEmpty {
            return inserted
        }
        
        switch value.object {
        case .immOrOwned(let immOrOwned):
            let ownedObj = immOrOwned.immOrOwned
            return [
                try self.input(
                    type: .object,
                    value: .callArg(
                        SuiCallArg.ownedObject(
                            OwnedObjectSuiCallArg(
                                type: "object",
                                objectType: "immOrOwnedObject",
                                objectId: ownedObj.objectId,
                                version: "\(ownedObj.version)",
                                digest: ownedObj.digest
                            )
                        )
                    )
                )
            ]
        case .shared(let sharedArg):
            let sharedObj = sharedArg.shared
            return [
                try self.input(
                    type: .object,
                    value: .callArg(
                        SuiCallArg.sharedObject(
                            SharedObjectSuiCallArg(
                                type: "object",
                                objectType: "sharedObject",
                                objectId: sharedObj.objectId,
                                initialSharedVersion: "\(sharedObj.initialSharedVersion)",
                                mutable: sharedObj.mutable
                            )
                        )
                    )
                )
            ]
        }
    }

    public mutating func objectRef(objectRef: SuiObjectRef) throws -> [TransactionBlockInput] {
        return try self.object(value: Inputs.objectRef(suiObjectRef: objectRef))
    }
    
    public mutating func shredObjectRef(sharedObjectRef: SharedObjectRef) throws -> [TransactionBlockInput] {
        return try self.object(value: Inputs.sharedObjectRef(sharedObjectRef: sharedObjectRef))
    }

    public mutating func pure(value: SuiJsonValue) throws -> TransactionBlockInput {
        return try self.input(type: .pure, value: value)
    }
    
    public mutating func add(transaction: SuiTransactionEnumType) throws -> TransactionArgument {
        self.blockData?.serializedTransactionDataBuilder.transactions.append(SuiTransaction(suiTransaction: transaction))
        guard let index = self.blockData?.serializedTransactionDataBuilder.transactions.count else {
            throw SuiError.invalidIndex
        }
        guard let result = TransactionResult(index: index - 1)[index - 1] else {
            throw SuiError.invalidResult
        }
        return result
    }
    
    public mutating func splitCoin(coin: TransactionArgument, amounts: [TransactionBlockInput]) throws -> TransactionArgument {
        try self.add(
            transaction: SuiTransactionEnumType.splitCoins(
                Transactions.splitCoins(
                    coins: ObjectTransactionArgument(
                        argument: coin
                    ),
                    amounts: amounts.map { TransactionArgument.input($0) }
                )
            )
        )
    }

    public mutating func mergeCoin(destination: TransactionBlockInput, sources: [TransactionBlockInput]) throws -> TransactionArgument {
        try self.add(
            transaction: SuiTransactionEnumType.mergeCoins(
                Transactions.mergeCoins(
                    destination: ObjectTransactionArgument(
                        argument: TransactionArgument.input(destination)
                    ),
                    sources: sources.map {
                        ObjectTransactionArgument(
                            argument: TransactionArgument.input($0)
                        )
                    }
                )
            )
        )
    }

    public mutating func publish(
        modules: [Data],
        dependencies: [objectId]
    ) throws -> TransactionArgument {
        try self.add(
            transaction: SuiTransactionEnumType.publish(
                Transactions.publish(
                    modules: modules.map { [UInt8]($0) },
                    dependencies: dependencies
                )
            )
        )
    }
    
    public mutating func upgrade(
        modules: [Data],
        dependencies: [objectId],
        packageId: objectId,
        ticket: TransactionBlockInput
    ) throws -> TransactionArgument {
        try self.add(
            transaction: SuiTransactionEnumType.upgrade(
                Transactions.upgrade(
                    modules: modules.map { [UInt8]($0) },
                    dependencies: dependencies,
                    packageId: packageId,
                    ticket: ObjectTransactionArgument(
                        argument: TransactionArgument.input(ticket)
                    )
                )
            )
        )
    }
    
    public mutating func moveCall(target: String, arguments: [TransactionArgument]?, typeArguments: [String]?) throws -> TransactionArgument {
        try self.add(
            transaction: SuiTransactionEnumType.moveCall(
                Transactions.moveCall(
                    input: MoveCallTransactionInput(
                        target: target,
                        arguments: arguments,
                        typeArguments: typeArguments
                    )
                )
            )
        )
    }
    
    public mutating func transferObject(objects: [TransactionArgument], address: TransactionBlockInput) throws -> TransactionArgument {
        try self.add(
            transaction: SuiTransactionEnumType.transferObjects(
                Transactions.transferObjects(
                    objects: objects.map {
                        ObjectTransactionArgument(
                            argument: $0
                        )
                    },
                    address: PureTransactionArgument(
                        argument: TransactionArgument.input(address),
                        type: "address"
                    )
                )
            )
        )
    }
    
    public mutating func makeMoveVec(type: String? = nil, objects: [TransactionBlockInput]) throws -> TransactionArgument {
        try self.add(
            transaction: SuiTransactionEnumType.makeMoveVec(
                Transactions.makeMoveVec(
                    type: type,
                    objects: objects.map {
                        ObjectTransactionArgument(
                            argument: TransactionArgument.input($0)
                        )
                    }
                )
            )
        )
    }

    public func serialize() throws -> Data {
        guard let blockData = self.blockData else { throw SuiError.notImplemented }
        return try JSONEncoder().encode(blockData.snapshot())
    }
    
    public mutating func build(_ provider: SuiProvider, _ onlyTransactionKind: Bool? = nil) async throws -> Data {
        try await self.prepare(provider: provider, onlyTransactionKind: onlyTransactionKind)
        return try self.blockData?.build(onlyTransactionKind: onlyTransactionKind) ?? Data()
    }

    public mutating func getDigest(_ provider: SuiProvider) async throws -> String {
        try await self.prepare(provider: provider)
        return try self.blockData?.getDigest() ?? ""
    }
    
    private mutating func prepareGasPayment(provider: SuiProvider, onlyTransactionKind: Bool? = nil) async throws {
        if self.isMissingSender(onlyTransactionKind) {
            throw SuiError.notImplemented
        }
        
        guard let gasOwner =
            self.blockData?.serializedTransactionDataBuilder.gasConfig.owner ??
            self.blockData?.serializedTransactionDataBuilder.sender
        else {
            throw SuiError.notImplemented
        }
        
        let coins = try await provider.getCoins(
            AccountAddress.fromHex(gasOwner),
            "0x2::sui::SUI"
        )
        
        print("INPUTS: \(self.blockData?.serializedTransactionDataBuilder.inputs)")
        print("COINS: \(coins)")
        
        throw SuiError.notImplemented
        
        let paymentCoins = coins.data.filter { coin in
            let matchingInput = self.blockData?.serializedTransactionDataBuilder.inputs.filter { input in
                if let value = input.value {
                    switch value {
                    case .callArg(let callArg):
                        switch callArg {
                        case .ownedObject(let ownedObject):
                            return coin.coinObjectId == ownedObject.objectId
                        default:
                            return false
                        }
                    default:
                        return false
                    }
                }
                return false
            }
            
            return matchingInput != nil && !matchingInput!.isEmpty
        }[0..<TransactionConstants.MAX_GAS_OBJECTS].map { coin in  // ERROR: INDEX OUT OF RANGE
            SuiObjectRef(
                version: UInt8(Int(coin.version) ?? 0),
                objectId: coin.coinObjectId,
                digest: coin.digest
            )
        }
        
        guard !paymentCoins.isEmpty else {
            throw SuiError.notImplemented
        }
        
        try self.setGasPayment(payments: paymentCoins)
    }
    
    private mutating func prepareGasPrice(provider: SuiProvider, onlyTransactionKind: Bool? = nil) async throws {
        if self.isMissingSender(onlyTransactionKind) {
            throw SuiError.notImplemented
        }
        
        self.setGasPrice(
            price: BigInt(
                try await provider.getGasPrice()
            )
        )
    }

    private mutating func prepareTransactions(provider: SuiProvider) async throws {
        guard let blockData = self.blockData?.serializedTransactionDataBuilder else {
            throw SuiError.notImplemented
        }
        
        var moveModulesToResolve: [MoveCallTransaction] = []
        
        struct ObjectsToResolve {
            let id: String
            var input: TransactionBlockInput
            let normalizedType: SuiMoveNormalizedType?
        }
        
        var objectsToResolve: [ObjectsToResolve] = []
        
        try await blockData.transactions.asyncForEach { tx in
            if tx.suiTransaction.kind == "MoveCall" {
                switch tx.suiTransaction {
                case .moveCall(let moveCall):
                    let needsResolution = moveCall.arguments.allSatisfy { argument in
                        switch argument {
                        case .input(let transactionBlockInput):
                            switch blockData.inputs[transactionBlockInput.index].value {
                            case .callArg:
                                return false
                            default:
                                return true
                            }
                        default:
                            return false
                        }
                    }
                    
                    if needsResolution {
                        moveModulesToResolve.append(moveCall)
                    }
                    
                    return
                default:
                    break
                }
            }
            
            func encodeInput(
                index: Int,
                blockData: inout SerializedTransactionDataBuilder,
                objectsToResolve: inout [ObjectsToResolve]
            ) throws {
                guard !(blockData.inputs.isEmpty), blockData.inputs.count > index else {
                    throw SuiError.notImplemented
                }
                let input = blockData.inputs[index]
                
                switch input.type {
                case .object:
                    switch input.value {
                    case .callArg:
                        return
                    case .string(let str):
                        objectsToResolve.append(ObjectsToResolve(id: str, input: input, normalizedType: nil))
                    default:
                        throw SuiError.notImplemented
                    }
                default:
                    if let value = input.value {
                        blockData.inputs[index] = TransactionBlockInput(
                            index: index,
                            value: SuiJsonValue.callArg(
                                SuiCallArg.pure(
                                    PureSuiCallArg(
                                        type: "pure",
                                        valueType: nil,
                                        value: value
                                    )
                                )
                            ),
                            type: .pure
                        )
                    }
                }
            }

            switch tx.suiTransaction {
            case .moveCall(let moveCallTransaction):
                try moveCallTransaction.arguments.forEach { txArgument in
                    switch txArgument {
                    case .input(let transactionBlockInput):
                        if self.blockData != nil {
                            try encodeInput(
                                index: transactionBlockInput.index,
                                blockData: &(self.blockData!.serializedTransactionDataBuilder),
                                objectsToResolve: &objectsToResolve
                            )
                        }
                    default:
                        break
                    }
                }
            case .transferObjects(let transferObjectsTransaction):
                try transferObjectsTransaction.objects.forEach { objectArgument in
                    switch objectArgument.argument {
                    case .input(let transactionBlockInput):
                        if self.blockData != nil {
                            try encodeInput(
                                index: transactionBlockInput.index,
                                blockData: &(self.blockData!.serializedTransactionDataBuilder),
                                objectsToResolve: &objectsToResolve
                            )
                        }
                    default:
                        break
                    }
                }
            case .splitCoins(let splitCoinsTransaction):
                try splitCoinsTransaction.amounts.forEach { pureTx in
                    switch pureTx.argument {
                    case .input(let transactionBlockInput):
                        if self.blockData != nil {
                            try encodeInput(
                                index: transactionBlockInput.index,
                                blockData: &(self.blockData!.serializedTransactionDataBuilder),
                                objectsToResolve: &objectsToResolve
                            )
                        }
                    default:
                        break
                    }
                }
                switch splitCoinsTransaction.coin.argument {
                case .input(let transactionBlockInput):
                    if self.blockData != nil {
                        try encodeInput(
                            index: transactionBlockInput.index,
                            blockData: &(self.blockData!.serializedTransactionDataBuilder),
                            objectsToResolve: &objectsToResolve
                        )
                    }
                default:
                    break
                }
            case .mergeCoins(let mergeCoinsTransaction):
                try mergeCoinsTransaction.sources.forEach { objectTx in
                    switch objectTx.argument {
                    case .input(let transactionBlockInput):
                        if self.blockData != nil {
                            try encodeInput(
                                index: transactionBlockInput.index,
                                blockData: &(self.blockData!.serializedTransactionDataBuilder),
                                objectsToResolve: &objectsToResolve
                            )
                        }
                    default:
                        break
                    }
                }
                switch mergeCoinsTransaction.destination.argument {
                case .input(let transactionBlockInput):
                    if self.blockData != nil {
                        try encodeInput(
                            index: transactionBlockInput.index,
                            blockData: &(self.blockData!.serializedTransactionDataBuilder),
                            objectsToResolve: &objectsToResolve
                        )
                    }
                default:
                    break
                }
            case .publish:
                break
            case .upgrade(let upgradeTransaction):
                switch upgradeTransaction.ticket.argument {
                case .input(let transactionBlockInput):
                    if self.blockData != nil {
                        try encodeInput(
                            index: transactionBlockInput.index,
                            blockData: &(self.blockData!.serializedTransactionDataBuilder),
                            objectsToResolve: &objectsToResolve
                        )
                    }
                default:
                    break
                }
            case .makeMoveVec(let makeMoveVecTransaction):
                try makeMoveVecTransaction.objects.forEach { objectTx in
                    switch objectTx.argument {
                    case .input(let transactionBlockInput):
                        if self.blockData != nil {
                            try encodeInput(
                                index: transactionBlockInput.index,
                                blockData: &(self.blockData!.serializedTransactionDataBuilder),
                                objectsToResolve: &objectsToResolve
                            )
                        }
                    default:
                        break
                    }
                }
            }
            
            if moveModulesToResolve.count > 0 {
                try await moveModulesToResolve.asyncForEach { moveCallTx in
                    let moveCallArguments = moveCallTx.target.components(separatedBy: "::")
                    
                    if moveCallArguments.count == 3 {
                        let packageId = moveCallArguments[0]
                        let moduleName = moveCallArguments[1]
                        let functionName = moveCallArguments[2]
                        
                        let normalized = try await provider.getNormalizedMoveFunction(
                            packageId, moduleName, functionName
                        )
                        
                        let hasTxContext =
                            normalized.parameters.count > 0 &&
                            self.isTxcontext(normalized.parameters.last!)
                        
                        let params = hasTxContext ? normalized.parameters.dropLast() : normalized.parameters
                        
                        guard params.count == moveCallTx.arguments.count else { throw SuiError.notImplemented }
                        
                        try params.enumerated().forEach { (idx, param) in
                            let arg = moveCallTx.arguments[idx]
                            
                            switch arg {
                            case .input(let blockInputArgument):
                                var input = blockData.inputs[blockInputArgument.index]
                                switch input.value {
                                case .callArg: return
                                default: break
                                }
                                guard let inputValue = input.value else { return }
                                
                                let serType = try self.getPureSerializationType(param, inputValue)
                                
                                if let serType {
                                    input.value = .callArg(.pure(PureSuiCallArg(type: serType, valueType: nil, value: inputValue)))
                                    return
                                }
                                
                                let structVal = self.extractStructTag(param)
                                
                                if structVal != nil {
                                    switch param {
                                    case .structure(let structObject):
                                        if !(structObject.typeArguments.isEmpty) {
                                            switch inputValue {
                                            case .string(let strInputValue):
                                                objectsToResolve.append(
                                                    ObjectsToResolve(
                                                        id: strInputValue,
                                                        input: input,
                                                        normalizedType: param
                                                    )
                                                )
                                                return
                                            default:
                                                throw SuiError.notImplemented
                                            }
                                        }
                                    default: break
                                    }
                                }
                            default: return
                            }
                            
                            throw SuiError.notImplemented
                        }
                        
                        if objectsToResolve.count > 0 {
                            let dedupedIds = objectsToResolve.map { $0.id }
                            let objectChunks = dedupedIds.chunked(into: TransactionConstants.MAX_OBJECTS_PER_FETCH)
                            
                            var objects: [SuiObjectResponse] = []
                            
                            try await objectChunks.asyncForEach {
                                let result = try await provider.getMultiObjects($0, GetObject(showOwner: true))
                                objects.append(contentsOf: result)
                            }
                            
                            var objectsById: [String: SuiObjectResponse] = [:]
                            
                            dedupedIds.enumerated().forEach { idx, id in
                                objectsById[id] = objects[idx]
                            }
                            
                            for var objectToResolve in objectsToResolve {
                                let object = objectsById[objectToResolve.id]
                                
                                if let object {
                                    let initialSharedVersion = self.getSharedObjectInitialVersion(object)
                                    
                                    if let initialSharedVersion {
                                        switch objectToResolve.input.value {
                                        case .callArg(let callArg):
                                            let mutable = self.isMutableSharedObjectInput(callArg) || (
                                                objectToResolve.normalizedType != nil &&
                                                extractMutableReference(objectToResolve.normalizedType!) != nil
                                            )
                                            
                                            switch callArg {
                                            case .sharedObject:
                                                objectToResolve.input.value = .callArg(
                                                    .sharedObject(
                                                        SharedObjectSuiCallArg(
                                                            type: "object",
                                                            objectType: "sharedObject",
                                                            objectId: objectToResolve.id,
                                                            initialSharedVersion: "\(initialSharedVersion)",
                                                            mutable: mutable
                                                        )
                                                    )
                                                )
                                            default:
                                                if let objRef = self.getObjectReference(object) {
                                                    let txInputs = try objectRef(objectRef: objRef)
                                                    objectToResolve.input.value = SuiJsonValue.array(
                                                        txInputs.map {
                                                            SuiJsonValue.input($0)
                                                        }
                                                    )
                                                }
                                            }
                                        default: break
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private mutating func prepare(provider: SuiProvider, onlyTransactionKind: Bool? = nil) async throws {
        if self.isMissingSender(onlyTransactionKind) {
            throw SuiError.notImplemented
        }
        
        try await self.prepareGasPrice(provider: provider, onlyTransactionKind: onlyTransactionKind)
        try await self.prepareTransactions(provider: provider)
        
        if let onlyTxKind = onlyTransactionKind, !onlyTxKind { return }

        try await self.prepareGasPayment(provider: provider, onlyTransactionKind: onlyTransactionKind)
        
        if let blockData = self.blockData, blockData.serializedTransactionDataBuilder.gasConfig.budget == nil {
            let dryRunResult = try await provider.dryRunTransactionBlock([UInt8](blockData.build()))
            
            guard dryRunResult.effects.status.status != .failure else {
                throw SuiError.notImplemented
            }
            
            let safeOverhead = TransactionConstants.GAS_SAFE_OVERHEAD * (
                Int(blockData.serializedTransactionDataBuilder.gasConfig.price ?? "1") ?? 1
            )
            
            let baseComputationCostWithOverhead = Int(dryRunResult.effects.gasUsed.computationCost) ?? 1 + safeOverhead
            
            let gasBudget =
                baseComputationCostWithOverhead +
                (Int(dryRunResult.effects.gasUsed.storageCost) ?? 1) -
                (Int(dryRunResult.effects.gasUsed.storageRebate) ?? 1)
            
            self.setGasBudget(
                price:
                    gasBudget > baseComputationCostWithOverhead ?
                    BigInt(gasBudget) :
                    BigInt(baseComputationCostWithOverhead)
            )
        }
    }
    
    private func isMissingSender(_ onlyTransactionKind: Bool? = nil) -> Bool {
        return
            onlyTransactionKind != nil &&
            !(onlyTransactionKind!) &&
            self.blockData?.serializedTransactionDataBuilder.sender == nil
    }
    
    private func isTxcontext(_ param: SuiMoveNormalizedType) -> Bool {
        let structTag = self.extractStructTag(param)
        
        return
            structTag?.address == "0x2" &&
            structTag?.module == "tx_context" &&
            structTag?.name == "TxContext"
    }
    
    private func extractStructTag(_ normalizedType: SuiMoveNormalizedType) -> SuiMoveNormalizedStructType? {
        let ref = self.extractReference(normalizedType)
        let mutRef = self.extractMutableReference(normalizedType)
        
        switch ref {
        case .structure(let structure):
            return structure
        default:
            break
        }
        
        switch mutRef {
        case .structure(let structure):
            return structure
        default:
            break
        }
        
        return nil
    }
    
    private func extractReference(_ normalizedType: SuiMoveNormalizedType) -> SuiMoveNormalizedType? {
        switch normalizedType {
        case .reference(let suiMoveNormalizedType):
            return .reference(suiMoveNormalizedType)
        default:
            return nil
        }
    }
    
    private func extractMutableReference(_ normalizedType: SuiMoveNormalizedType) -> SuiMoveNormalizedType? {
        switch normalizedType {
        case .mutableReference(let suiMoveNormalizedType):
            return .mutableReference(suiMoveNormalizedType)
        default:
            return nil
        }
    }
    
    private func getPureSerializationType(_ normalizedType: SuiMoveNormalizedType, _ argVal: SuiJsonValue) throws -> String? {
        enum AllowedTypes: String {
            case Address
            case Bool
            case U8
            case U16
            case U32
            case U64
            case U128
            case U256
            
            public static func isAllowed(_ input: SuiMoveNormalizedType) -> Bool {
                return AllowedTypes(rawValue: input.type) != nil
            }
        }
        
        if AllowedTypes.isAllowed(normalizedType) {
            switch normalizedType {
            case .bool:
                try self.expectType("boolean", argVal)
            case .u8, .u16, .u32, .u64, .u128, .u256:
                try self.expectType("number", argVal)
            case .address, .signer:
                try self.expectType("string", argVal)
                switch argVal {
                case .string(let str):
                    guard self.isValidSuiAddress(str) else { throw SuiError.notImplemented }
                default:
                    throw SuiError.notImplemented
                }
            default: break
            }
            return normalizedType.type.lowercased()
        }
        
        switch normalizedType {
        case .vector(let normalizedTypeVector):
            if argVal.kind == .string, normalizedTypeVector.type == "U8" {
                return "string"
            }
            let innerType = try self.getPureSerializationType(normalizedTypeVector, argVal)
            guard innerType != nil else { return nil }
            return "vector<\(innerType!)>"
        case .structure(let normalizedStruct):
            if self.isSameStruct(normalizedStruct, ResolvedAsciiStr()) {
                return "string"
            }
            if self.isSameStruct(normalizedStruct, ResolvedUtf8Str()) {
                return "utf8string"
            }
            if self.isSameStruct(normalizedStruct, ResolvedSuiId()) {
                return "address"
            }
            if self.isSameStruct(normalizedStruct, ResolvedStdOption()) {
                let optionToVec: SuiMoveNormalizedType = .vector(normalizedStruct.typeArguments[0])
                return try self.getPureSerializationType(optionToVec, argVal)
            }
        default: break
        }
        
        return nil
    }
    
    private func expectType(_ typeName: String, _ argVal: SuiJsonValue) throws {
        if SuiJsonValueType(rawValue: typeName) == nil {
            throw SuiError.notImplemented
        }
        if (SuiJsonValueType(rawValue: typeName))! != argVal.kind {
            throw SuiError.notImplemented
        }
    }
    
    private func isValidSuiAddress(_ value: String) -> Bool {
        return isHex(value) && self.getHexByteLength(value) == 32
    }
    
    private func isHex(_ value: String) -> Bool {
        let regex = try! NSRegularExpression(pattern: "^(0x|0X)?[a-fA-F0-9]+$")
        let range = NSRange(location: 0, length: value.utf16.count)
        let match = regex.firstMatch(in: value, options: [], range: range)

        return match != nil && value.count % 2 == 0
    }
    
    private func getHexByteLength(_ value: String) -> Int {
        if value.hasPrefix("0x") || value.hasPrefix("0X") {
            return (value.count - 2) / 2
        } else {
            return value.count / 2
        }
    }
    
    private func isSameStruct(_ lhs: SuiMoveNormalizedStructType, _ rhs: any ResolvedProtocol) -> Bool {
        return
            lhs.address == rhs.address &&
            lhs.module == rhs.module &&
            lhs.name == rhs.name
    }
    
    private func getSharedObjectInitialVersion(_ resp: SuiObjectResponse) -> Int? {
        if let owner = resp.owner, let initialSharedVersion = owner.shared?.shared.initialSharedVersion {
            return initialSharedVersion
        }
        return nil
    }
    
    private func getSharedObjectInput(_ arg: SuiCallArg) -> SharedObjectSuiCallArg? {
        switch arg {
        case .sharedObject(let sharedObjectSuiCallArg):
            return sharedObjectSuiCallArg
        default: return nil
        }
    }
    
    private func isMutableSharedObjectInput(_ arg: SuiCallArg) -> Bool {
        return self.getSharedObjectInput(arg)?.mutable ?? false
    }
    
    private func getObjectReference(_ resp: SuiObjectResponse) -> SuiObjectRef? {
        return SuiObjectRef(
            version: UInt8(resp.version),
            objectId: resp.objectId,
            digest: resp.digest
        )
    }
}

public struct ResolvedStdOption: ResolvedProtocol {
    public var address: String = ResolvedConstants.moveStdlibAddress
    public var module: String = ResolvedConstants.stdOptionModuleName
    public var name: String = ResolvedConstants.stdOptionStructName
}

public struct ResolvedUtf8Str: ResolvedProtocol {
    public var address: String = ResolvedConstants.moveStdlibAddress
    public var module: String = ResolvedConstants.stdUtf8ModuleName
    public var name: String = ResolvedConstants.stdUtf8StructName
}

public struct ResolvedAsciiStr: ResolvedProtocol {
    public var address: String = ResolvedConstants.moveStdlibAddress
    public var module: String = ResolvedConstants.stdAsciiModuleName
    public var name: String = ResolvedConstants.stdAsciiStructName
}

public struct ResolvedSuiId: ResolvedProtocol {
    public var address: String = ResolvedConstants.suiFrameworkAddress
    public var module: String = ResolvedConstants.objectModuleName
    public var name: String = ResolvedConstants.idStructName
}

public struct ResolvedConstants {
    public static let stdOptionStructName = "Option"
    public static let stdOptionModuleName = "option"
    
    public static let stdUtf8StructName = "String"
    public static let stdUtf8ModuleName = "string"
    
    public static let stdAsciiStructName = "String"
    public static let stdAsciiModuleName = "ascii"
    
    public static let suiSystemAddress = "0x3"
    public static let suiFrameworkAddress = "0x2"
    public static let moveStdlibAddress = "0x1"
    
    public static let objectModuleName = "object"
    public static let uidStructName = "UID"
    public static let idStructName = "ID"
    
    public static let suiTypeArg = "\(ResolvedConstants.suiFrameworkAddress)::sui::SUI"
    public static let validatorsEventQuery = "\(ResolvedConstants.suiSystemAddress)::validator_set::ValidatorEpochInfoEventV2"
}
