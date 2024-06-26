// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetCheckpointsQuery: GraphQLQuery {
  public static let operationName: String = "getCheckpoints"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query getCheckpoints($first: Int, $before: String, $last: Int, $after: String) { checkpoints(first: $first, after: $after, last: $last, before: $before) { __typename pageInfo { __typename startCursor endCursor hasNextPage hasPreviousPage } nodes { __typename ...RPC_Checkpoint_Fields } } }"#,
      fragments: [RPC_Checkpoint_Fields.self]
    ))

  public var first: GraphQLNullable<Int>
  public var before: GraphQLNullable<String>
  public var last: GraphQLNullable<Int>
  public var after: GraphQLNullable<String>

  public init(
    first: GraphQLNullable<Int>,
    before: GraphQLNullable<String>,
    last: GraphQLNullable<Int>,
    after: GraphQLNullable<String>
  ) {
    self.first = first
    self.before = before
    self.last = last
    self.after = after
  }

  public var __variables: Variables? { [
    "first": first,
    "before": before,
    "last": last,
    "after": after
  ] }

  public struct Data: SuiKit.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: ApolloAPI.ParentType { SuiKit.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("checkpoints", Checkpoints.self, arguments: [
        "first": .variable("first"),
        "after": .variable("after"),
        "last": .variable("last"),
        "before": .variable("before")
      ]),
    ] }

    public var checkpoints: Checkpoints { __data["checkpoints"] }

    /// Checkpoints
    ///
    /// Parent Type: `CheckpointConnection`
    public struct Checkpoints: SuiKit.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: ApolloAPI.ParentType { SuiKit.Objects.CheckpointConnection }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("pageInfo", PageInfo.self),
        .field("nodes", [Node].self),
      ] }

      /// Information to aid in pagination.
      public var pageInfo: PageInfo { __data["pageInfo"] }
      /// A list of nodes.
      public var nodes: [Node] { __data["nodes"] }

      /// Checkpoints.PageInfo
      ///
      /// Parent Type: `PageInfo`
      public struct PageInfo: SuiKit.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: ApolloAPI.ParentType { SuiKit.Objects.PageInfo }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("startCursor", String?.self),
          .field("endCursor", String?.self),
          .field("hasNextPage", Bool.self),
          .field("hasPreviousPage", Bool.self),
        ] }

        /// When paginating backwards, the cursor to continue.
        public var startCursor: String? { __data["startCursor"] }
        /// When paginating forwards, the cursor to continue.
        public var endCursor: String? { __data["endCursor"] }
        /// When paginating forwards, are there more items?
        public var hasNextPage: Bool { __data["hasNextPage"] }
        /// When paginating backwards, are there more items?
        public var hasPreviousPage: Bool { __data["hasPreviousPage"] }
      }

      /// Checkpoints.Node
      ///
      /// Parent Type: `Checkpoint`
      public struct Node: SuiKit.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: ApolloAPI.ParentType { SuiKit.Objects.Checkpoint }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .fragment(RPC_Checkpoint_Fields.self),
        ] }

        /// A 32-byte hash that uniquely identifies the checkpoint contents, encoded in Base58. This
        /// hash can be used to verify checkpoint contents by checking signatures against the committee,
        /// Hashing contents to match digest, and checking that the previous checkpoint digest matches.
        public var digest: String { __data["digest"] }
        /// The epoch this checkpoint is part of.
        public var epoch: RPC_Checkpoint_Fields.Epoch? { __data["epoch"] }
        /// The computation cost, storage cost, storage rebate, and non-refundable storage fee
        /// accumulated during this epoch, up to and including this checkpoint. These values increase
        /// monotonically across checkpoints in the same epoch, and reset on epoch boundaries.
        public var rollingGasSummary: RPC_Checkpoint_Fields.RollingGasSummary? { __data["rollingGasSummary"] }
        /// The total number of transaction blocks in the network by the end of this checkpoint.
        public var networkTotalTransactions: Int? { __data["networkTotalTransactions"] }
        /// The digest of the checkpoint at the previous sequence number.
        public var previousCheckpointDigest: String? { __data["previousCheckpointDigest"] }
        /// This checkpoint's position in the total order of finalized checkpoints, agreed upon by
        /// consensus.
        public var sequenceNumber: Int { __data["sequenceNumber"] }
        /// The timestamp at which the checkpoint is agreed to have happened according to consensus.
        /// Transactions that access time in this checkpoint will observe this timestamp.
        public var timestamp: SuiKit.DateTimeApollo { __data["timestamp"] }
        /// Transactions in this checkpoint.
        public var transactionBlockConnection: RPC_Checkpoint_Fields.TransactionBlocks? { __data["transactionBlocks"] }
        /// This is an aggregation of signatures from a quorum of validators for the checkpoint
        /// proposal.
        public var validatorSignatures: SuiKit.Base64Apollo { __data["validatorSignatures"] }

        public struct Fragments: FragmentContainer {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public var rPC_Checkpoint_Fields: RPC_Checkpoint_Fields { _toFragment() }
        }
      }
    }
  }
}
