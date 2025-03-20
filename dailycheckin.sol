pragma solidity ^0.8.0;

contract DailyLoginReward {
    // Track last login timestamp for each user
    mapping(address => uint256) public lastLogin;
    
    // Store user reward balances
    mapping(address => uint256) public rewards;
    
    // Daily reward amount (in wei)
    uint256 public constant DAILY_REWARD = 1 ether;
    
    // Minimum time between rewards (24 hours in seconds)
    uint256 public constant COOLDOWN_PERIOD = 24 * 60 * 60;
    
    // Event to log successful reward claims
    event RewardClaimed(address indexed user, uint256 amount, uint256 timestamp);
    
    // Event for withdrawals
    event RewardWithdrawn(address indexed user, uint256 amount);
    
    // Function to claim daily reward
    function claimReward() public {
        address user = msg.sender;
        uint256 currentTime = block.timestamp;
        
        // Check if user is eligible for reward
        require(
            lastLogin[user] == 0 || 
            currentTime >= lastLogin[user] + COOLDOWN_PERIOD,
            "Must wait 24 hours between claims"
        );
        
        // Check if contract has enough balance
        require(address(this).balance >= DAILY_REWARD, "Insufficient contract balance");
        
        // Update last login time
        lastLogin[user] = currentTime;
        
        // Add reward to user's balance
        rewards[user] += DAILY_REWARD;
        
        // Emit event for successful claim
        emit RewardClaimed(user, DAILY_REWARD, currentTime);
    }
    
    // Function to withdraw accumulated rewards
    function withdrawRewards() public {
        address user = msg.sender;
        uint256 amount = rewards[user];
        
        require(amount > 0, "No rewards to withdraw");
        
        // Reset reward balance before transfer to prevent reentrancy
        rewards[user] = 0;
        
        // Transfer rewards
        (bool success, ) = user.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit RewardWithdrawn(user, amount);
    }
    
    // Function to check remaining cooldown time
    function getCooldownTime() public view returns (uint256) {
        address user = msg.sender;
        uint256 nextEligibleTime = lastLogin[user] + COOLDOWN_PERIOD;
        
        if (block.timestamp >= nextEligibleTime) {
            return 0;
        }
        
        return nextEligibleTime - block.timestamp;
    }
    
    // Function to check user's reward balance
    function getRewardBalance() public view returns (uint256) {
        return rewards[msg.sender];
    }
    
    // Allow contract to receive ether
    receive() external payable {}
}
