
//allows users to stake ERC20 tokens, withdraw staked tokens, and claim rewards

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";     //Interface for the ERC20 token standard.
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; //Provides a nonReentrant modifier to prevent reentrancy attacks.
import "@openzeppelin/contracts/utils/math/SafeMath.sol";   //Library for safe arithmetic operations to prevent overflows and underflows.

contract Staking is ReentrancyGuard   //The contract inherits from ReentrancyGuard to use the nonReentrant modifier.
{
  using SafeMath for uint256;
  IERC20 public s_stakingToken;   //s_stakingToken and s_rewardToken: ERC20 tokens used for staking and rewards.
  IERC20 public s_rewardToken;

  uint public constant REWARD_RATE=1e18; // rate at which rewards are distributed.
  uint private totalStakedTokens;  // total amount of tokens staked in the contract.
  uint public rewardPerTokenStored;   // cumulative reward per token.
  uint public lastUpdateTime;  // last time the rewards were updated.

  mapping(address=>uint) public stakedBalance; //Mapping of each user's staked balance.
  mapping(address=>uint) public rewards;   //Mapping of each user's accumulated rewards.
  mapping(address=>uint) public userRewardPerTokenPaid;  //Mapping of the reward per token already paid to each user.
 
 //Events are emitted to log staking, withdrawals, and reward claims.
  event Staked(address indexed user, uint256 indexed amount);
  event Withdrawn(address indexed user, uint256 indexed amount);
  event RewardsClaimed(address indexed user, uint256 indexed amount);
  
  //The constructor initializes the staking and reward tokens.
  constructor(address stakingToken,address rewardToken){
    s_stakingToken=IERC20(stakingToken);
    s_rewardToken=IERC20(rewardToken);
  }
//Calculates the current reward per token based on the time since the last update and the total staked tokens.
  function rewardPerToken() public view returns(uint){
    if(totalStakedTokens==0){
        return rewardPerTokenStored;
    }
    uint totalTime = block.timestamp.sub(lastUpdateTime);
    uint totalRewards = REWARD_RATE.mul(totalTime); 
    return rewardPerTokenStored.add(totalRewards.mul(1e18).div(totalStakedTokens));
  }
 
 //Calculates the total rewards earned by a user, based on their staked balance and the difference between the current reward per token and the last reward per token paid to the user.
  function earned(address account) public view returns(uint){
    return stakedBalance[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
  }
 
 //modifier updates the reward variables for the given account before executing the function logic.
  modifier updateReward(address account){
    rewardPerTokenStored=rewardPerToken();
    lastUpdateTime=block.timestamp;
    rewards[account]=earned(account);
    userRewardPerTokenPaid[account]=rewardPerTokenStored;
    _;
  }

  function stake(uint amount) external nonReentrant updateReward(msg.sender){  //The stake function allows users to stake tokens.
    require(amount>0,"Amount must be greater than zero"); //It requires the staking amount to be greater than zero.
    totalStakedTokens=totalStakedTokens.add(amount);
    stakedBalance[msg.sender]=stakedBalance[msg.sender].add(amount);
    emit Staked(msg.sender,amount);
    bool success = s_stakingToken.transferFrom(msg.sender,address(this),amount);
    require(success,"Transfer Failed");
  }
  //The withdrawStakedTokens function allows users to withdraw their staked tokens.
  function withdrawStakedTokens(uint amount) external nonReentrant updateReward(msg.sender)  {
    require(amount>0,"Amount must be greater than zero"); //It requires the withdrawal amount to be greater than zero and ensures the user has enough staked tokens.
    require(stakedBalance[msg.sender]>=amount,"Staked amount not enough");
    totalStakedTokens=totalStakedTokens.sub(amount);
    stakedBalance[msg.sender]=stakedBalance[msg.sender].sub(amount);
    emit Withdrawn(msg.sender, amount);(msg.sender,amount);
    bool success = s_stakingToken.transfer(msg.sender,amount);
    require(success,"Transfer Failed");
  }
 // This  function, getReward, is  allows users to claim their rewards
   function getReward() external nonReentrant updateReward(msg.sender){
     uint reward = rewards[msg.sender];
     require(reward>0,"No rewards to claim");
     rewards[msg.sender]=0;
     emit RewardsClaimed(msg.sender, reward);
     bool success = s_rewardToken.transfer(msg.sender,reward);
     require(success,"Transfer Failed");
  }
}
// On SepoliaETH testnetwork
//RewardToken     0x6fcb6a006da2a4ab9aaeec785b3d96d5956e342c
//StakeToken      0x54635d468e274bd03dd4e9bd1543aada84594cb7
//Staking         0xf929b33638afaa5d533e9869924af7d0c8bf74ce







