🧾 Auction Smart Contract

This Solidity smart contract implements a decentralized auction system where users can place incremental bids. The contract enforces auction rules such as bid increments, deadline extensions, secure refunds, and commission handling, making it suitable for trustless auctions on Ethereum.
📌 Features

    Place bids with a minimum 5% increase over the highest.

    Extend auction time by 10 minutes if a bid is placed near the end.

    Track all bids per user.

    Allow users to withdraw excess or non-winning bids.

    Admin (owner) can finalize the auction.

    Emergency fund recovery by the owner.

    Secure commission deduction (2%) on withdrawals.

🧱 State Variables
Variable	Type	Description
owner	address	Address of the contract deployer (auction creator).
highestBidder	address	Current highest bidder.
highestBid	uint256	Current highest total bid amount.
auctionEndTime	uint256	Timestamp when the auction ends.
totalCommission	uint256	Accumulated commissions from all withdrawals (2% per withdrawal).
bids	mapping	Mapping from address to an array of Bid structs for tracking offers.
📦 Structs
Bid

struct Bid {
    uint256 amount;
    bool withdrawn;
}

Field	Type	Description
amount	uint256	Amount of Ether offered in the bid.
withdrawn	bool	Whether the bid was already claimed.
⚙️ Functions
🏗️ constructor(uint256 _durationSeconds)

Initializes the auction with a set duration.

    Parameters:

        _durationSeconds (uint256): Duration of the auction in seconds.

    Access: Public.

🟢 placeBid() external payable

Places a new bid. Requires a msg.value greater than zero, and the total bid must exceed the current highest bid by at least 5%. If the bid occurs in the last 10 minutes of the auction, the auction end time is extended by 10 more minutes.

    Parameters: None (uses msg.value).

    Modifiers: onlyWhileAuctionActive.

    Events: Emits NewBid(address bidder, uint256 amount).

🟢 getWinner() external view returns (address, uint256)

Returns the winner's address and the winning bid amount.

    Returns:

        address: The highest bidder.

        uint256: The amount of the highest bid.

    Conditions: Callable only after the auction has ended.

🟢 getBids(address _bidder) external view returns (Bid[] memory)

Returns all bids placed by a specific address.

    Parameters:

        _bidder (address): Address of the bidder to query.

    Returns:

        Bid[] memory: Array of bid records for that address.

🟢 withdrawExcess() external

Allows bidders to withdraw their non-winning bids, or excess amount if they are the winner (anything over the final winning bid). Applies a 2% commission to the withdrawal. Marks all withdrawn bids as true.

    Conditions:

        Only callable if there are unclaimed bids.

        If the sender is the winner, only the excess can be withdrawn.

    Events: Transfers Ether to the caller.

🛑 finalizeAuction() external

Marks the auction as finalized. Only the contract owner can call this after the auction ends. It locks the winner's bids to prevent withdrawal.

    Conditions:

        Auction must be ended.

        Caller must be owner.

    Events: Emits AuctionEnded(address winner, uint256 amount).

🛠️ emergencyWithdraw() external

Allows the contract owner to withdraw all contract funds in case of an emergency.

    Conditions: Caller must be the owner.

🔒 getTotalBid(address _bidder) internal view returns (uint256)

Calculates the total unwithdrawn amount bid by a specific address.

    Parameters:

        _bidder (address): Address whose total bid to calculate.

    Returns:

        uint256: Total active bid amount (excluding withdrawn bids).

    Access: Internal.

📢 Events
Event	Parameters	Description
NewBid	address bidder, uint256 amount	Emitted when a new bid is placed.
AuctionEnded	address winner, uint256 highestBid	Emitted when the auction ends.
✅ Best Practices Applied

    ✅ Short error messages to reduce gas costs.

    ✅ require checks at the top of functions.

    ✅ For-loop optimizations: no internal array length recalculations.

    ✅ Dirty variables declared outside loops.

    ✅ Read state once, write once.

    ✅ Emergency fund recovery function.

    ✅ Full English documentation.

🧪 Example Workflow

    Owner deploys the contract with a 1-day auction duration.

    Users place bids via placeBid(), with each new bid being 5% higher than the previous one.

    If the auction is nearing its end, the timer extends by 10 minutes.

    Once the auction ends, the owner finalizes it using finalizeAuction().

    Non-winners or the winning bidder (for excess) call withdrawExcess().

    The owner can recover leftover funds with emergencyWithdraw().